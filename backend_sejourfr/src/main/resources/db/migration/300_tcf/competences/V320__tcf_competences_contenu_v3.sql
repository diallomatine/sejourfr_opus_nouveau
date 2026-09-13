-- ==========================================================================
-- V320 — Contenu de la taxonomie V3 des competences d'expression
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--   cd backend_sejourfr && python3 tools/competences/emettre_contenu_v3.py
--
-- Fait suite a V319, qui a transforme la table des competences sans toucher
-- aux sujets. Trois apports :
--   1. 144 points d'apprentissage sur 48 competences actives ;
--   2. le cadrage corrige de 121 sujets (9 competences recentrees) ;
--   3. 19 lots neufs : anciens sujets desactives, 285 sujets et 855 references inseres.
--
-- 🛑 AUCUNE SUPPRESSION. user_skill_attempts.skill_prompt_id est en
-- ON DELETE CASCADE : supprimer un sujet effacerait les productions des
-- candidats. Le geste est is_active = false.
--
-- 🛑 Desactiver ne libere pas le rang : uq_skill_prompts_skill_order ne
-- filtre pas is_active. Les anciens sujets passent en 16..30 (le CHECK va
-- jusqu'a 50 depuis V064) pour que les neufs occupent 1..15.
--
-- L'etat intermediaire, ou deux sujets partagent un rang, est licite :
-- uq_skill_prompts_skill_order est DEFERRABLE INITIALLY DEFERRED (V025).
-- ==========================================================================

-- --------------------------------------------------------------------------
-- 1. « Vous allez apprendre a : » — 144 points, 48 competences
--
-- Colonne ajoutee par V063. Les points sont RELUS a la main : la generation
-- n'a servi que de premiere redaction (journal, D01).
-- --------------------------------------------------------------------------
UPDATE skills s SET
    learning_points = v.points::jsonb,
    updated_at      = '2026-09-13 09:00:00+02'
FROM (VALUES
  -- EE1-C2 — Répondre précisément à la demande du message
  ('EE1-C2', '["Repérer ce qui est demandé", "Répondre à cette demande seule", "Écarter ce qui n''est pas demandé"]'),
  -- EE1-C1 — Adapter la réponse au destinataire
  ('EE1-C1', '["Choisir le tutoiement ou le vouvoiement", "Tenir le même ton partout", "Rester poli sans être guindé"]'),
  -- EE1-C9 — Identifier clairement ce qui est décrit
  ('EE1-C9', '["Nommer ce dont on parle", "Donner un signe qui distingue", "Écarter les autres possibilités"]'),
  -- EE1-C10 — Sélectionner les caractéristiques pertinentes
  ('EE1-C10', '["Repérer ce qui intéresse le lecteur", "Retenir les traits utiles", "Laisser de côté le reste"]'),
  -- EE1-C7 — Décrire une personne ou un groupe
  ('EE1-C7', '["Donner l''aspect et l''âge", "Dire le caractère ou le rôle", "Décrire la composition d''un groupe"]'),
  -- EE1-C11 — Décrire un lieu ou un objet
  ('EE1-C11', '["Situer le lieu ou l''objet", "Donner la taille et la matière", "Dire l''usage ou l''ambiance"]'),
  -- EE1-C3 — Donner des détails concrets et précis
  ('EE1-C3', '["Remplacer les mots vagues", "Donner une couleur ou un nombre", "Préciser l''endroit ou le moment"]'),
  -- EE1-C8 — Relier les informations dans une description cohérente
  ('EE1-C8', '["Choisir un ordre de description", "Relier les phrases entre elles", "Refermer la description naturellement"]'),
  -- EE2-C1 — Situer le moment et le lieu
  ('EE2-C1', '["Donner un repère de temps", "Nommer le lieu du récit", "Poser ces repères d''emblée"]'),
  -- EE2-C2 — Présenter la situation et les personnes
  ('EE2-C2', '["Nommer les personnes présentes", "Dire ce que chacun faisait", "Ne pas redire le lieu"]'),
  -- EE2-C3 — Utiliser les temps du passé de manière compréhensible
  ('EE2-C3', '["Tenir le récit au passé", "Distinguer les actions du contexte", "Garder des temps cohérents"]'),
  -- EE2-C9 — Expliquer une action, un choix ou une réaction
  ('EE2-C9', '["Donner la raison d''un choix", "Nommer la cause d''un fait", "Rendre une réaction compréhensible"]'),
  -- EE2-C5 — Raconter les actions dans l'ordre
  ('EE2-C5', '["Poser la première étape", "Enchaîner les étapes suivantes", "Varier les connecteurs de temps"]'),
  -- EE2-C6 — Ajouter des détails utiles
  ('EE2-C6', '["Préciser une personne ou un lieu", "Ajouter une circonstance concrète", "Rester dans le sujet"]'),
  -- EE2-C7 — Exprimer une réaction ou un ressenti
  ('EE2-C7', '["Nommer un sentiment précis", "Le relier à la situation vécue", "Éviter les mots passe-partout"]'),
  -- EE2-C8 — Terminer par le résultat ou ce que cela a apporté
  ('EE2-C8', '["Dire comment cela s''est terminé", "Ou ce que cela a changé", "Refermer sans exagérer la fin"]'),
  -- EE3-C1 — Exprimer une position claire
  ('EE3-C1', '["Répondre à la question posée", "Rendre son avis identifiable", "Rester sur le sujet visé"]'),
  -- EE3-C2 — Donner un argument pertinent
  ('EE3-C2', '["Donner une raison à son avis", "La rattacher à l''avis annoncé", "Éviter la raison hors sujet"]'),
  -- EE3-C3 — Développer un argument
  ('EE3-C3', '["Expliquer pourquoi la raison vaut", "Dérouler le lien jusqu''au bout", "Nommer l''effet obtenu"]'),
  -- EE3-C4 — Illustrer avec un exemple concret
  ('EE3-C4', '["Choisir un cas précis", "Situer un moment et un geste", "Relier l''exemple à l''argument"]'),
  -- EE3-C5 — Faire progresser son propos sans se répéter
  ('EE3-C5', '["Apporter une idée nouvelle", "Changer de terrain", "Ne pas revenir sur la précédente"]'),
  -- EE3-C9 — Adapter son expression au destinataire et au contexte
  ('EE3-C9', '["Ajuster le ton à la personne", "Choisir le niveau de politesse", "Doser la franchise sans blesser"]'),
  -- EE3-C7 — Nuancer ou reconnaître une limite
  ('EE3-C7', '["Reconnaître un point adverse réel", "Marquer la concession clairement", "Garder sa position malgré elle"]'),
  -- EE3-C8 — Enchaîner ses idées de façon cohérente
  ('EE3-C8', '["Relier les idées entre elles", "Choisir le bon connecteur", "Se passer d''une conclusion formelle"]'),
  -- EO1-C1 — Se présenter avec les informations essentielles
  ('EO1-C1', '["Donner son nom et sa situation", "Répondre à ce qui est demandé", "Rester court et clair"]'),
  -- EO1-C2 — Répondre directement à une question personnelle
  ('EO1-C2', '["Répondre par une phrase complète", "Éviter le simple oui ou non", "Rester sur la question posée"]'),
  -- EO1-C3 — Développer une réponse avec une précision
  ('EO1-C3', '["Ajouter un quand ou un où", "Préciser avec qui ou pourquoi", "Donner une fréquence"]'),
  -- EO1-C4 — Parler de son quotidien
  ('EO1-C4', '["Décrire ses horaires habituels", "Suivre l''ordre de la journée", "Nommer des gestes concrets"]'),
  -- EO1-C5 — Décrire son entourage ou son environnement
  ('EO1-C5', '["Présenter sa famille ou ses proches", "Décrire son logement ou son quartier", "Ajouter deux détails concrets"]'),
  -- EO1-C6 — Raconter brièvement une expérience passée
  ('EO1-C6', '["Situer le moment du récit", "Résumer l''essentiel", "S''arrêter avant le récit développé"]'),
  -- EO1-C7 — Parler de ses projets futurs
  ('EO1-C7', '["Annoncer une intention", "Situer le projet dans le temps", "Ajouter une précision utile"]'),
  -- EO1-C8 — Réagir à une relance et maintenir l'échange
  ('EO1-C8', '["Comprendre ce qu''on vous redemande", "Compléter au lieu de répéter", "Relancer l''échange naturellement"]'),
  -- EO2-C1 — Commencer poliment et expliquer son besoin
  ('EO2-C1', '["Saluer son interlocuteur", "Présenter la situation en une phrase", "Annoncer ce que l''on cherche"]'),
  -- EO2-C2 — Formuler une question claire
  ('EO2-C2', '["Construire une question complète", "La relier à la situation", "Éviter la question trop vague"]'),
  -- EO2-C3 — Demander les informations et les conditions
  ('EO2-C3', '["Demander prix, horaire ou durée", "Demander documents et inscription", "Demander les règles et services"]'),
  -- EO2-C9 — Réagir à une réponse ou une contrainte imprévue
  ('EO2-C9', '["Poursuivre après un refus", "Relancer poliment", "Proposer une autre solution"]'),
  -- EO2-C5 — Poser une question de suivi
  ('EO2-C5', '["Reprendre la réponse obtenue", "En tirer une question nouvelle", "Demander un complément utile"]'),
  -- EO2-C6 — Demander une précision ou reformuler
  ('EO2-C6', '["Signaler ce qu''on n''a pas compris", "Demander de répéter autrement", "Reformuler pour faire confirmer"]'),
  -- EO2-C7 — Explorer plusieurs possibilités
  ('EO2-C7', '["Interroger chaque possibilité", "Faire préciser les différences", "Obtenir ce qui n''est pas dit"]'),
  -- EO2-C8 — Confirmer les informations et terminer l'échange
  ('EO2-C8', '["Récapituler l''essentiel obtenu", "Vérifier un dernier point", "Prendre congé naturellement"]'),
  -- EO3-C1 — Annoncer une position claire
  ('EO3-C1', '["Répondre clairement à la question", "Rendre son opinion identifiable", "Ne pas laisser deviner son avis"]'),
  -- EO3-C8 — Tenir un discours continu et organisé
  ('EO3-C8', '["Enchaîner sans laisser retomber", "Relier chaque idée à la précédente", "Organiser au lieu d''énumérer"]'),
  -- EO3-C2 — Donner un argument pertinent
  ('EO3-C2', '["Donner une raison à sa position", "La rattacher à ce qu''on défend", "Éviter la raison hors sujet"]'),
  -- EO3-C3 — Développer oralement un argument
  ('EO3-C3', '["Expliquer la cause de sa raison", "En donner la conséquence", "Ajouter une précision concrète"]'),
  -- EO3-C4 — Donner un exemple concret
  ('EO3-C4', '["Annoncer qu''on donne un exemple", "Situer une personne et un moment", "Dire l''effet observé"]'),
  -- EO3-C5 — Enchaîner une idée nouvelle
  ('EO3-C5', '["Apporter une idée qui avance", "Changer de terrain", "Ne pas compter ses arguments"]'),
  -- EO3-C9 — Reformuler pour relancer son propos
  ('EO3-C9', '["Redire la même idée autrement", "Préciser au lieu de répéter", "Repartir sans bloquer sur un mot"]'),
  -- EO3-C7 — Nuancer ou reconnaître une limite
  ('EO3-C7', '["Introduire une réserve", "Reconnaître une exception", "Tenir sa position malgré elle"]')
) AS v(code, points)
WHERE s.code = v.code;

-- --------------------------------------------------------------------------
-- 2. Cadrage corrige — 121 sujets de 9 competences recentrees
--
-- Les SITUATIONS sont conservees : seuls la consigne, le critere unique, le
-- guidage et, quand la V3 l'imposait, les references changent. Voir le
-- journal D02/D03.
-- --------------------------------------------------------------------------
UPDATE skill_prompts p SET
    title                        = v.title,
    instruction                  = v.instruction,
    unique_criterion             = v.unique_criterion,
    checklist                    = v.checklist::jsonb,
    constraint_tags              = v.constraint_tags::jsonb,
    answer_starter               = v.answer_starter,
    tip                          = v.tip,
    recommended_min_words        = v.recommended_min_words,
    recommended_max_words        = v.recommended_max_words,
    recommended_duration_seconds = v.recommended_duration_seconds,
    difficulty_level             = v.difficulty_level,
    updated_at                   = '2026-09-13 09:00:00+02'
FROM (VALUES
  -- EE2-C2-S1
  ('EE2-C2-S1', 'Une fête dans le quartier',
   'Présentez en deux phrases le début de cette soirée : avec qui vous étiez et ce que vous faisiez.',
   'Le début du récit dit les personnes présentes et l''activité en cours.',
   '["Nommez les personnes présentes", "Dites ce que chacun faisait", "Écrivez deux phrases"]',
   '[{"label": "Qui est là", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'J''étais avec mes voisins et…', 'Deux informations suffisent : les personnes, et ce que vous faisiez.',
   25, 55, NULL, 'EASY'),
  -- EE2-C2-S2
  ('EE2-C2-S2', 'Un cours du soir',
   'Racontez le début d''une de ces soirées en deux phrases : avec qui vous étiez et ce que vous faisiez avant le début du cours.',
   'La situation de départ précise les personnes présentes et l''activité en cours.',
   '["Dites avec qui vous êtes", "Racontez ce que vous faisiez", "Écrivez deux phrases"]',
   '[{"label": "Autres élèves", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'J''étais avec cinq autres élèves…', 'Restez sur ce seul soir : évitez de décrire les cours en général.',
   25, 55, NULL, 'EASY'),
  -- EE2-C2-S3
  ('EE2-C2-S3', 'Dans la salle d''attente',
   'Présentez en deux phrases la situation avant d''entrer dans le cabinet : avec qui vous étiez et ce que vous faisiez.',
   'Le lecteur sait qui vous accompagne et ce que chacun fait avant l''événement.',
   '["Dites qui vous accompagne", "Précisez votre occupation", "Arrêtez-vous avant la consultation"]',
   '[{"label": "Votre fille", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'J''attendais avec ma fille, qui…', 'Ne racontez pas encore la consultation : restez sur les minutes d''attente.',
   25, 55, NULL, 'MEDIUM'),
  -- EE2-C2-S4
  ('EE2-C2-S4', 'Un départ en covoiturage',
   'Écrivez trois phrases pour présenter le début du trajet : avec qui vous étiez et ce que vous faisiez.',
   'Les trois phrases posent les personnes présentes et l''activité avant le départ.',
   '["Présentez les autres passagers", "Dites ce que vous faisiez", "Écrivez trois phrases"]',
   '[{"label": "Passagers présents", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Le conducteur et deux passagers m''attendaient…', 'Les personnes d''abord : le voyage lui-même n''est pas demandé ici.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C2-S5
  ('EE2-C2-S5', 'Juste avant l''incident',
   'Écrivez trois phrases qui présentent la situation initiale : les personnes présentes et votre activité, sans raconter encore l''incident.',
   'Les trois phrases décrivent les personnes et l''activité d''avant l''incident, sans le raconter.',
   '["Nommez votre collègue", "Dites ce que vous faisiez", "Ne racontez pas l''incident"]',
   '[{"label": "Collègues présents", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Ma collègue Sonia travaillait à côté de moi…', 'Gardez la surprise : l''incident se raconte plus tard, pas dans ces phrases.',
   40, 80, NULL, 'HARD'),
  -- EE2-C2-S6
  ('EE2-C2-S6', 'Le matin du déménagement',
   'Présentez en deux phrases le début de cette matinée : avec qui vous étiez et ce que vous faisiez.',
   'La situation de départ nomme les personnes présentes et votre activité.',
   '["Nommez les amis présents", "Décrivez ce que vous faisiez", "Écrivez deux phrases"]',
   '[{"label": "Personnes présentes", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Mes deux amis et moi, nous…', 'Restez sur les premières minutes : le trajet viendra plus tard.',
   25, 55, NULL, 'EASY'),
  -- EE2-C2-S7
  ('EE2-C2-S7', 'La clé du voisin',
   'Présentez en deux phrases ce qui se passait juste avant ce coup de sonnette : les personnes présentes et votre activité.',
   'Les deux phrases disent avec qui vous étiez et ce que vous faisiez avant le coup de sonnette.',
   '["Dites qui était avec vous", "Racontez votre activité", "Écrivez deux phrases"]',
   '[{"label": "Personnes avec vous", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'J''étais avec ma femme et notre fils…', 'Arrêtez-vous avant le coup de sonnette : seul le décor compte.',
   25, 55, NULL, 'EASY'),
  -- EE2-C2-S8
  ('EE2-C2-S8', 'Dans le hall avec le gardien',
   'Présentez en deux phrases la situation avant votre discussion : qui était là et ce que chacun faisait.',
   'La situation initiale précise les personnes présentes et leur activité.',
   '["Dites qui était présent", "Précisez l''activité de chacun", "Écrivez deux phrases"]',
   '[{"label": "Gardien présent", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Le gardien triait le courrier et…', 'Dites ce que chacun faisait : la scène devient tout de suite vivante.',
   25, 55, NULL, 'EASY'),
  -- EE2-C2-S9
  ('EE2-C2-S9', 'Dans le local à vélos',
   'Présentez en deux phrases la situation : les personnes présentes et ce que vous faisiez.',
   'Les personnes présentes et l''activité en cours apparaissent avant tout autre détail.',
   '["Nommez qui était présent", "Dites ce que vous faisiez", "Écrivez deux phrases"]',
   '[{"label": "Autres habitants", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'J''accrochais mon cadenas pendant que…', 'Un geste concret, comme fermer un cadenas, montre votre activité.',
   25, 55, NULL, 'MEDIUM'),
  -- EE2-C2-S10
  ('EE2-C2-S10', 'Une heure à la laverie',
   'Présentez en deux phrases le début de cette attente : avec qui vous étiez et ce que vous faisiez.',
   'Les deux phrases installent les personnes présentes et votre occupation.',
   '["Dites qui attendait aussi", "Racontez votre occupation", "Écrivez deux phrases"]',
   '[{"label": "Clients présents", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Deux autres clients attendaient aussi…', 'Ce que vous faisiez pendant l''attente compte autant que les personnes présentes.',
   25, 55, NULL, 'MEDIUM'),
  -- EE2-C2-S11
  ('EE2-C2-S11', 'La file de la caisse',
   'Écrivez trois phrases pour présenter cette attente : avec qui vous étiez et ce que chacun faisait.',
   'Les trois phrases posent les personnes présentes et leur activité avant la suite du récit.',
   '["Présentez les personnes autour", "Dites ce que chacun faisait", "Écrivez trois phrases"]',
   '[{"label": "Clients autour", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Mon fils tenait la liste des courses…', 'Le chariot, les sacs, les voisins de queue : montrez les gestes.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C2-S12
  ('EE2-C2-S12', 'Au stand d''un ami',
   'Écrivez trois phrases pour présenter le début de cette matinée : les personnes présentes et votre activité.',
   'Les trois phrases décrivent les personnes présentes et ce que chacun faisait.',
   '["Nommez votre ami", "Décrivez votre travail", "Écrivez trois phrases"]',
   '[{"label": "Ami commerçant", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Mon ami installait la balance pendant que…', 'Nommez vos gestes : installer, peser, servir. Le lecteur vous voit.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C2-S13
  ('EE2-C2-S13', 'La queue du dimanche matin',
   'Écrivez trois phrases qui présentent la situation, sans raconter la suite : les personnes présentes et leur activité.',
   'Les trois phrases décrivent les personnes et leur activité sans avancer dans le récit.',
   '["Dites qui vous accompagne", "Racontez ce que chacun faisait", "N''avancez pas dans l''histoire"]',
   '[{"label": "Votre fille", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'J''attendais avec ma fille, qui…', 'Gardez la suite pour plus tard : montrez seulement qui était là et ce que chacun faisait.',
   40, 80, NULL, 'HARD'),
  -- EE2-C2-S14
  ('EE2-C2-S14', 'Chez l''épicier du quartier',
   'Écrivez trois phrases qui posent la situation de départ : les personnes présentes et votre activité.',
   'La situation de départ nomme les personnes présentes et ce que chacun faisait.',
   '["Présentez le commerçant", "Dites votre activité", "Écrivez trois phrases"]',
   '[{"label": "Commerçant présent", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Le commerçant coupait du fromage pendant que…', 'Un geste, une parole, une occupation : trois détails suffisent.',
   40, 80, NULL, 'HARD'),
  -- EE2-C2-S15
  ('EE2-C2-S15', 'En attendant le livreur',
   'Écrivez trois phrases sur cette attente : avec qui vous étiez et ce que vous faisiez, sans raconter la livraison.',
   'Les trois phrases décrivent les personnes présentes et leur activité, sans raconter la livraison.',
   '["Dites qui attendait avec vous", "Décrivez votre occupation", "Ne racontez pas la livraison"]',
   '[{"label": "Personnes présentes", "icon": "PERSON"}, {"label": "Activité en cours", "icon": "STRUCTURE"}]',
   'Mon frère était venu m''aider et…', 'L''attente est la scène : le livreur n''entre pas encore.',
   40, 80, NULL, 'HARD'),
  -- EE2-C3-S1
  ('EE2-C3-S1', 'Les courses de samedi',
   'Racontez en une phrase une action que vous avez terminée pendant ces courses.',
   'L''action terminée est racontée au passé, sans glisser vers le présent.',
   '["Choisissez une action terminée", "Racontez-la au passé", "Tenez-vous à une phrase"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Une seule action", "icon": "NUMBER"}]',
   'Samedi matin, au supermarché, je…', '« J''ai acheté » plutôt que « j''achète » : l''action est terminée.',
   15, 35, NULL, 'EASY'),
  -- EE2-C3-S2
  ('EE2-C3-S2', 'La journée d''école d''hier',
   'Racontez en deux phrases deux choses qui se sont passées hier à l''école.',
   'Les deux actions passées sont racontées au passé, pas au présent.',
   '["Choisissez deux faits d''hier", "Racontez-les au passé", "Écrivez deux phrases"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Deux actions", "icon": "NUMBER"}, {"label": "Hier", "icon": "TIME"}]',
   'Hier, à l''école, mon fils…', 'Le présent raconterait une habitude : ici, tout s''est passé hier.',
   25, 55, NULL, 'EASY'),
  -- EE2-C3-S3
  ('EE2-C3-S3', 'Pendant que j''attendais le bus',
   'Racontez en deux phrases une action terminée qui s''est produite pendant que vous attendiez.',
   'Les temps du passé distinguent l''attente qui durait de l''action qui l''a interrompue.',
   '["Décrivez l''attente qui durait", "Introduisez l''action avec « quand »", "Marquez l''action comme terminée"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Contexte et action", "icon": "STRUCTURE"}, {"label": "« Quand »", "icon": "STRUCTURE"}]',
   'J''attendais le bus depuis dix minutes…', 'Ce qui durait sert de décor ; ce qui est arrivé fait avancer le récit.',
   25, 55, NULL, 'MEDIUM'),
  -- EE2-C3-S4
  ('EE2-C3-S4', 'Une coupure d''eau le soir',
   'Racontez en trois phrases ce qui se passait chez vous et ce que vous avez fait ensuite.',
   'Le contexte qui durait et les actions terminées se distinguent clairement.',
   '["Décrivez ce qui durait", "Racontez la coupure", "Ajoutez vos actions terminées"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Contexte et actions", "icon": "STRUCTURE"}, {"label": "Le soir", "icon": "TIME"}]',
   'Je préparais le dîner quand…', 'Ce qui durait fait le décor, ce qui arrive fait avancer le récit.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C3-S5
  ('EE2-C3-S5', 'Le jour de l''entretien',
   'Racontez cet entretien en trois phrases : le décor, ce que vous avez fait, et la fin du rendez-vous.',
   'Le récit distingue le décor qui durait des actions terminées.',
   '["Plantez le décor", "Racontez vos actions terminées", "Terminez par la fin du rendez-vous"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Contexte et actions", "icon": "STRUCTURE"}, {"label": "Trois étapes", "icon": "STRUCTURE"}]',
   'La salle était grande et…', 'Un récit où rien ne se termine n''avance plus : ajoutez des actions achevées.',
   40, 80, NULL, 'HARD'),
  -- EE2-C3-S6
  ('EE2-C3-S6', 'Le carton était abîmé',
   'Racontez en une phrase une action terminée que vous avez faite en recevant ce colis.',
   'L''action que vous avez faite est racontée au passé, pas au présent.',
   '["Choisissez une action terminée", "Racontez-la au passé", "Tenez-vous à une phrase"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Une seule action", "icon": "NUMBER"}]',
   'En ouvrant le carton, j''ai…', '« J''ai photographié » montre que l''action est bien finie.',
   15, 35, NULL, 'EASY'),
  -- EE2-C3-S7
  ('EE2-C3-S7', 'L''appel au service après-vente',
   'Racontez en une phrase ce que vous avez fait pendant cet appel.',
   'L''action de l''appel est racontée au passé, pas au présent.',
   '["Choisissez une action de l''appel", "Racontez-la au passé", "Écrivez une seule phrase"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Une seule action", "icon": "NUMBER"}]',
   'Au téléphone, j''ai expliqué que…', 'Le présent raconterait une habitude ; ici, l''appel est terminé.',
   15, 35, NULL, 'EASY'),
  -- EE2-C3-S8
  ('EE2-C3-S8', 'L''écran cassé du téléphone',
   'Racontez en deux phrases deux choses que vous avez faites ce jour-là.',
   'Les deux actions passées sont racontées au passé.',
   '["Choisissez deux actions terminées", "Racontez-les au passé", "Écrivez deux phrases"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Deux actions", "icon": "NUMBER"}]',
   'Samedi, j''ai apporté mon téléphone…', 'Un récit au présent laisse croire que rien n''est terminé.',
   25, 55, NULL, 'EASY'),
  -- EE2-C3-S9
  ('EE2-C3-S9', 'La voiture au garage',
   'Racontez en deux phrases ce qui se passait dans le garage et l''action terminée qui a suivi.',
   'Le décor du garage qui durait se distingue de l''action terminée qui suit.',
   '["Décrivez ce qui se passait", "Ajoutez l''action terminée", "Écrivez deux phrases"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Contexte et action", "icon": "STRUCTURE"}]',
   'Le mécanicien réparait une camionnette quand…', 'Le décor dure, l''action tombe : deux rôles différents.',
   25, 55, NULL, 'MEDIUM'),
  -- EE2-C3-S10
  ('EE2-C3-S10', 'La première leçon de conduite',
   'Racontez en deux phrases le décor de cette leçon et ce que vous avez fait.',
   'Le décor de la leçon se distingue des actions que vous avez faites.',
   '["Plantez le décor", "Racontez vos actions terminées", "Écrivez deux phrases"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Contexte et actions", "icon": "STRUCTURE"}, {"label": "Une leçon", "icon": "NUMBER"}]',
   'La rue était calme et je…', 'Le stress et la météo font le décor ; vos gestes font les actions.',
   25, 55, NULL, 'MEDIUM'),
  -- EE2-C3-S11
  ('EE2-C3-S11', 'Un billet échangé au guichet',
   'Racontez en trois phrases ce qui se passait dans la gare et ce que vous avez fait au guichet.',
   'Le contexte de la gare se distingue des actions menées au guichet.',
   '["Décrivez la scène de la gare", "Racontez l''échange", "Ajoutez le résultat obtenu"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Décor et actions", "icon": "STRUCTURE"}]',
   'Le hall était plein et j''attendais…', 'Le hall dure en arrière-plan ; vos démarches, elles, se terminent.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C3-S12
  ('EE2-C3-S12', 'Le bus de remplacement',
   'Racontez en trois phrases ce qui se passait ce matin-là et ce que vous avez fait.',
   'Le récit distingue ce qui durait ce matin-là des actions terminées.',
   '["Décrivez la scène à l''arrêt", "Racontez vos actions terminées", "Terminez par votre arrivée"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Contexte et actions", "icon": "STRUCTURE"}, {"label": "Le matin", "icon": "TIME"}]',
   'Il faisait encore nuit et j''attendais…', 'Alternez : ce qui dure en arrière-plan, ce qui arrive au premier plan.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C3-S13
  ('EE2-C3-S13', 'La création de mon abonnement',
   'Racontez cette démarche en trois phrases : le décor, ce que vous avez fait, et la fin du rendez-vous.',
   'Le décor reste en arrière-plan pendant que les démarches avancent et se terminent.',
   '["Décrivez la scène de l''agence", "Racontez chaque démarche", "Terminez par la sortie"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Décor et actions", "icon": "STRUCTURE"}, {"label": "Étapes successives", "icon": "STRUCTURE"}]',
   'L''agence était pleine et j''attendais…', 'Sans action achevée, votre démarche semble ne jamais aboutir.',
   40, 80, NULL, 'HARD'),
  -- EE2-C3-S14
  ('EE2-C3-S14', 'La valise perdue',
   'Racontez cette arrivée en trois phrases : le décor, vos actions, et la fin de l''attente.',
   'Le décor de l''aéroport se distingue de chaque action terminée.',
   '["Décrivez la scène au tapis", "Racontez vos démarches", "Terminez par la fin de l''attente"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Décor et actions", "icon": "STRUCTURE"}, {"label": "Après l''arrivée", "icon": "TIME"}]',
   'Le tapis tournait depuis longtemps quand…', 'Chaque démarche accomplie mérite d''être marquée comme terminée.',
   40, 80, NULL, 'HARD'),
  -- EE2-C3-S15
  ('EE2-C3-S15', 'La sortie manquée sur l''autoroute',
   'Racontez ce moment en trois phrases : ce qui se passait dans la voiture, l''erreur, et ce que vous avez fait ensuite.',
   'Le récit distingue ce qui durait dans la voiture des actions qui sont arrivées.',
   '["Décrivez la scène dans la voiture", "Racontez l''erreur", "Ajoutez ce que vous avez fait"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Décor et actions", "icon": "STRUCTURE"}, {"label": "Sur la route", "icon": "PLACE"}]',
   'Nous roulions depuis deux heures quand…', 'Les temps suivent le rythme : décor long, actions courtes.',
   40, 80, NULL, 'HARD'),
  -- EE2-C8-S1
  ('EE2-C8-S1', 'Le colis enfin retrouvé',
   'Écrivez la fin de ce récit en deux phrases : dites comment le problème s''est terminé.',
   'La fin dit clairement comment le problème s''est résolu.',
   '["Dites comment le problème s''est réglé", "Refermez vraiment le récit", "Écrivez deux phrases"]',
   '[{"label": "Résultat clair", "icon": "STRUCTURE"}, {"label": "Deux phrases", "icon": "NUMBER"}]',
   'Après plusieurs appels, le transporteur…', 'Terminez vraiment l''histoire : le lecteur doit savoir comment cela s''est fini.',
   25, 55, NULL, 'EASY'),
  -- EE2-C8-S2
  ('EE2-C8-S2', 'La fin des cours du soir',
   'Racontez la fin de cette année en deux phrases : le résultat obtenu ou ce que cela a changé pour vous.',
   'La fin donne le résultat obtenu ou ce que cette année a changé.',
   '["Choisissez le résultat ou le changement", "Rendez-le concret", "Écrivez deux phrases"]',
   '[{"label": "Résultat ou changement", "icon": "STRUCTURE"}, {"label": "Effet concret", "icon": "EXAMPLE"}]',
   'À la fin de l''année…', '« Maintenant, je peux… » montre bien ce que cette année a changé.',
   25, 55, NULL, 'EASY'),
  -- EE2-C8-S3
  ('EE2-C8-S3', 'La fuite d''eau réparée',
   'Racontez la fin de cette histoire en trois phrases : la réparation, puis le résultat ou ce que cela a changé pour vous.',
   'Le récit se termine par un résultat net ou par ce que la situation a changé.',
   '["Racontez la réparation", "Donnez l''état final", "Refermez le récit"]',
   '[{"label": "Fin du récit", "icon": "STRUCTURE"}, {"label": "Résultat ou effet", "icon": "EXAMPLE"}]',
   'Le plombier est venu réparer…', '« Depuis, … » est une façon simple d''annoncer la conséquence.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C8-S4
  ('EE2-C8-S4', 'Un gros retard au travail',
   'Racontez la fin de cette journée en trois phrases : comment l''incident s''est terminé, ou ce qu''il a changé ensuite.',
   'La conclusion dit comment l''incident s''est terminé ou ce qu''il a changé.',
   '["Racontez la réaction du responsable", "Dites comment cela s''est terminé", "Refermez le récit"]',
   '[{"label": "Issue de l''incident", "icon": "STRUCTURE"}, {"label": "Résultat ou effet", "icon": "EXAMPLE"}]',
   'Mon responsable m''a écouté, puis…', 'Une habitude nouvelle prouve mieux qu''un « je ferai attention » un peu vague.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C8-S5
  ('EE2-C8-S5', 'Un dossier qui aboutit',
   'Écrivez la fin de ce récit en trois phrases : le résultat obtenu ou ce qu''il change, sans grossir le dénouement.',
   'La fin referme le récit par un résultat ou un changement, sans le rendre spectaculaire.',
   '["Annoncez le résultat obtenu", "Restez fidèle aux faits", "Refermez le récit"]',
   '[{"label": "Résultat daté", "icon": "TIME"}, {"label": "Fin sans exagération", "icon": "STRUCTURE"}]',
   'Au mois d''avril, j''ai enfin…', 'Une fin ordinaire, dite clairement, vaut mieux qu''un dénouement inventé.',
   40, 80, NULL, 'HARD'),
  -- EE2-C8-S6
  ('EE2-C8-S6', 'Les résultats de la prise de sang',
   'Écrivez la fin de ce récit en deux phrases : dites comment cela s''est terminé.',
   'La fin dit clairement quel a été le résultat de l''analyse.',
   '["Donnez le résultat obtenu", "Refermez vraiment le récit", "Écrivez deux phrases"]',
   '[{"label": "Résultat clair", "icon": "STRUCTURE"}, {"label": "Deux phrases", "icon": "NUMBER"}]',
   'Deux jours plus tard, le laboratoire…', 'Le lecteur doit savoir ce que disaient les résultats.',
   25, 55, NULL, 'EASY'),
  -- EE2-C8-S7
  ('EE2-C8-S7', 'Une carie enfin soignée',
   'Écrivez la fin de ce récit en deux phrases : le soin reçu et son résultat, ou ce que cela a changé.',
   'La fin donne le résultat du rendez-vous ou ce qu''il a changé.',
   '["Dites le soin reçu", "Donnez le résultat ou l''effet", "Écrivez deux phrases"]',
   '[{"label": "Résultat concret", "icon": "STRUCTURE"}, {"label": "Résultat ou effet", "icon": "EXAMPLE"}]',
   'Le dentiste a soigné ma dent…', '« Depuis, je peux… » montre bien l''effet du soin.',
   25, 55, NULL, 'EASY'),
  -- EE2-C8-S8
  ('EE2-C8-S8', 'Une place en halte-garderie',
   'Écrivez la fin de ce récit en deux phrases : la réponse reçue ou ce que cela change pour vous.',
   'La réponse obtenue est donnée, ou ce qu''elle change pour vous.',
   '["Donnez la réponse reçue", "Rendez la fin concrète", "Écrivez deux phrases"]',
   '[{"label": "Réponse obtenue", "icon": "STRUCTURE"}, {"label": "Résultat ou effet", "icon": "EXAMPLE"}]',
   'Au mois de septembre, la halte-garderie…', 'Dites ce que vous pouvez faire maintenant, très concrètement.',
   25, 55, NULL, 'EASY'),
  -- EE2-C8-S9
  ('EE2-C8-S9', 'Un soutien en lecture pour mon fils',
   'Racontez la fin de cette démarche en trois phrases : la décision de l''école, puis le résultat ou ce que cela a changé pour votre fils.',
   'Le récit se termine par une décision claire suivie d''un résultat ou d''un effet.',
   '["Donnez la décision de l''école", "Dites le résultat ou l''effet", "Refermez le récit"]',
   '[{"label": "Décision finale", "icon": "STRUCTURE"}, {"label": "Résultat ou effet", "icon": "EXAMPLE"}]',
   'La directrice m''a reçue en mai…', 'Une note, un mot du maître, un livre lu : voilà un effet visible.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C8-S10
  ('EE2-C8-S10', 'Après la réunion au collège',
   'Racontez la fin de cette soirée en trois phrases : ce qui a été décidé, puis le résultat ou ce que cela a changé.',
   'La conclusion présente une décision prise et le résultat ou le changement qui en découle.',
   '["Rapportez ce qui a été décidé", "Dites le résultat ou l''effet", "Refermez le récit"]',
   '[{"label": "Décision prise", "icon": "STRUCTURE"}, {"label": "Résultat ou effet", "icon": "EXAMPLE"}]',
   'À la fin de la réunion…', 'Dites ce qui est différent aujourd''hui, à la maison ou en classe.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C8-S11
  ('EE2-C8-S11', 'Un problème réglé à la cantine',
   'Racontez la fin de cette histoire en trois phrases : la solution trouvée, puis le résultat ou ce que cela a changé.',
   'La fin donne la solution obtenue et le résultat ou l''effet concret pour vous.',
   '["Racontez la solution trouvée", "Donnez le résultat ou l''effet", "Refermez le récit"]',
   '[{"label": "Solution obtenue", "icon": "STRUCTURE"}, {"label": "Résultat ou effet", "icon": "EXAMPLE"}]',
   'Au bout de trois semaines, la mairie…', 'Terminez par ce qui est plus simple aujourd''hui, dans votre semaine.',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C8-S12
  ('EE2-C8-S12', 'Les mercredis au centre de loisirs',
   'Racontez la fin de cette première période en trois phrases : le résultat ou ce que cela a changé pour vous deux.',
   'Le récit se termine par un résultat clair ou par ce que la période a changé.',
   '["Donnez le résultat de l''inscription", "Rendez la fin concrète", "Refermez le récit"]',
   '[{"label": "Résultat clair", "icon": "STRUCTURE"}, {"label": "Résultat ou effet", "icon": "EXAMPLE"}]',
   'Après un mois de mercredis, ma fille…', 'Une fin concrète vaut mieux qu''un simple « tout va bien ».',
   40, 80, NULL, 'MEDIUM'),
  -- EE2-C8-S13
  ('EE2-C8-S13', 'Un acte de naissance corrigé',
   'Écrivez la fin de ce récit en trois phrases : le résultat obtenu ou ce qu''il change, sans grossir le dénouement.',
   'La fin referme le récit par un résultat ou un changement, sans le rendre spectaculaire.',
   '["Donnez la correction obtenue", "Restez fidèle aux faits", "Refermez le récit"]',
   '[{"label": "Résultat daté", "icon": "TIME"}, {"label": "Fin sans exagération", "icon": "STRUCTURE"}]',
   'Après deux visites au guichet, l''employée…', 'Ne gonflez pas la fin : dites simplement ce qui s''est passé au bout du compte.',
   45, 90, NULL, 'HARD'),
  -- EE2-C8-S14
  ('EE2-C8-S14', 'Un titre de séjour volé',
   'Écrivez la fin de ce récit en trois phrases : le résultat obtenu ou ce qu''il change, sans grossir le dénouement.',
   'La fin referme le récit par un résultat ou un changement, sans le rendre spectaculaire.',
   '["Dites le résultat de la demande", "Restez fidèle aux faits", "Refermez le récit"]',
   '[{"label": "Résultat daté", "icon": "TIME"}, {"label": "Fin sans exagération", "icon": "STRUCTURE"}]',
   'Six semaines après le dépôt de plainte…', 'Même une issue partielle referme le récit, à condition de la dire nettement.',
   45, 90, NULL, 'HARD'),
  -- EE2-C8-S15
  ('EE2-C8-S15', 'Le dossier de la CAF débloqué',
   'Écrivez la fin de ce récit en trois phrases : le résultat obtenu ou ce qu''il change, sans grossir le dénouement.',
   'La fin referme le récit par un résultat ou un changement, sans le rendre spectaculaire.',
   '["Donnez la décision de la CAF", "Restez fidèle aux faits", "Refermez le récit"]',
   '[{"label": "Résultat daté", "icon": "TIME"}, {"label": "Fin sans exagération", "icon": "STRUCTURE"}]',
   'Le versement a repris au mois…', 'Un dénouement discret suffit : ce qui compte, c''est qu''on sache où cela s''arrête.',
   45, 90, NULL, 'HARD'),
  -- EO1-C6-S1
  ('EO1-C6-S1', 'Une sortie récente',
   'Répondez à la question : « Parlez-moi d''une sortie que vous avez faite récemment. » Dites quand c''était et racontez au moins deux actions dans l''ordre.',
   'Situer le moment de la sortie et raconter au moins deux actions dans l''ordre.',
   '["Dites quand c''était", "Racontez deux actions", "Respectez l''ordre des faits"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Moment situé", "icon": "TIME"}]',
   'Samedi dernier, je suis allé…', 'commencez par la date : samedi dernier, la semaine dernière, hier soir.',
   NULL, NULL, 35, 'EASY'),
  -- EO1-C6-S2
  ('EO1-C6-S2', 'Un repas de fête',
   'Répondez à la question : « Racontez-moi un repas de fête auquel vous avez participé. » Dites quand c''était, avec qui, et racontez deux ou trois moments.',
   'Situer le moment et raconter au moins deux moments du repas dans l''ordre.',
   '["Dites quand c''était", "Dites avec qui", "Racontez deux moments du repas"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Deux moments", "icon": "NUMBER"}]',
   'Le mois dernier, nous avons fêté…', 'd''abord, ensuite, après : ces mots suffisent pour raconter dans l''ordre.',
   NULL, NULL, 35, 'EASY'),
  -- EO1-C6-S4
  ('EO1-C6-S4', 'Un déplacement compliqué',
   'Répondez à la question : « Racontez-moi un voyage ou un trajet difficile. » Dites quand c''était, ce qui s''est passé et comment cela s''est terminé.',
   'Situer le moment, raconter le problème et dire comment la situation s''est terminée.',
   '["Dites quand c''était", "Racontez le problème", "Dites comment cela s''est terminé"]',
   '[{"label": "Problème et fin", "icon": "STRUCTURE"}, {"label": "Temps du passé", "icon": "TENSE"}]',
   'L''hiver dernier, je suis parti…', 'un récit a une fin : dites comment la situation s''est résolue.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO1-C6-S6
  ('EO1-C6-S6', 'Le mercredi au centre de loisirs',
   'Répondez à la question : « Racontez-moi ce mercredi-là, du matin au soir. » Donnez la date, puis racontez au moins deux actions, l''une après l''autre.',
   'Situer le moment et raconter au moins deux actions dans l''ordre.',
   '["Dites quand c''était", "Racontez deux actions", "Gardez l''ordre des faits"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Moment situé", "icon": "TIME"}]',
   'Mercredi dernier, j''ai emmené mon fils…', 'commencez par mercredi dernier, puis dites ce que vous avez fait ensuite.',
   NULL, NULL, 30, 'EASY'),
  -- EO1-C6-S7
  ('EO1-C6-S7', 'Un passage à l''état civil',
   'Répondez à la question : « Comment avez-vous obtenu ce document ? » Dites quel jour vous y êtes allé, puis racontez au moins deux actions dans l''ordre.',
   'Situer le moment de la démarche et raconter au moins deux actions dans l''ordre.',
   '["Dites quand vous y êtes allé", "Racontez deux actions"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Deux actions", "icon": "NUMBER"}]',
   'Le mois dernier, je suis allée…', 'une démarche a un début et une fin : dites les deux.',
   NULL, NULL, 35, 'EASY'),
  -- EO1-C6-S8
  ('EO1-C6-S8', 'Le jour du rendez-vous en préfecture',
   'Répondez à la question : « Comment ce rendez-vous s''est-il déroulé ? » Placez d''abord le moment, et racontez ensuite deux actions au minimum, sans en inverser l''ordre.',
   'Situer le moment du rendez-vous et raconter au moins deux actions dans l''ordre.',
   '["Dites quand c''était", "Racontez deux actions", "Respectez l''ordre"]',
   '[{"label": "Moment situé", "icon": "TIME"}, {"label": "Temps du passé", "icon": "TENSE"}]',
   'En février, j''avais un rendez-vous à…', 'l''heure d''arrivée ouvre bien un récit : j''y étais à huit heures.',
   NULL, NULL, 35, 'EASY'),
  -- EO1-C6-S3
  ('EO1-C6-S3', 'Un rendez-vous médical',
   'Répondez à la question : « Racontez-moi votre dernier rendez-vous chez le médecin. » Dites quand c''était et racontez l''essentiel en deux ou trois phrases, sans dérouler tout le rendez-vous.',
   'Le récit reste court : le moment est situé et l''essentiel du rendez-vous est raconté dans l''ordre.',
   '["Dites quand c''était", "Racontez l''essentiel", "Arrêtez-vous avant le détail"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Récit court", "icon": "STRUCTURE"}]',
   'Il y a deux semaines, j''ai…', 'l''essentiel d''un rendez-vous tient en deux phrases : pourquoi, et ce qui a été dit.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO1-C6-S5
  ('EO1-C6-S5', 'Votre premier jour',
   'Répondez à la question : « Racontez-moi votre premier jour de travail ou de formation. » Dites quand c''était et racontez-le brièvement, même si la question invite à tout raconter.',
   'La réponse situe le moment et reste un récit court, sans basculer dans le récit développé.',
   '["Dites quand c''était", "Racontez-le brièvement", "Ne déroulez pas toute la journée"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Récit court", "icon": "STRUCTURE"}, {"label": "Question ouverte", "icon": "TONE"}]',
   'L''année dernière, j''ai commencé dans…', 'une question large n''oblige pas à une réponse longue : choisissez ce qui compte.',
   NULL, NULL, 40, 'HARD'),
  -- EO1-C6-S9
  ('EO1-C6-S9', 'Votre dossier à la CAF',
   'Répondez à la question : « Reprenez ce dossier depuis le début. » Dites quand vous avez commencé et résumez la démarche en deux ou trois phrases.',
   'Le récit reste court : le moment est situé et la démarche est résumée dans l''ordre.',
   '["Dites quand vous avez commencé", "Résumez la démarche", "Gardez l''ordre des faits"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Récit court", "icon": "STRUCTURE"}]',
   'L''an dernier, j''ai créé mon compte…', 'un dossier long se résume : le début, le moment difficile, la fin.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO1-C6-S10
  ('EO1-C6-S10', 'Le point avec France Travail',
   'Répondez à la question : « Ce rendez-vous, il s''est passé comment ? » Situez-le dans le temps et résumez-le en deux ou trois phrases.',
   'Le récit reste court : le moment est situé et l''essentiel du rendez-vous est résumé.',
   '["Dites quand c''était", "Résumez le rendez-vous", "Gardez l''ordre des faits"]',
   '[{"label": "Récit court", "icon": "STRUCTURE"}, {"label": "Moment situé", "icon": "TIME"}]',
   'Il y a trois semaines, j''ai…', 'ce qui a été décidé compte plus que le détail de la conversation.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO1-C6-S11
  ('EO1-C6-S11', 'Obtenir votre carte Vitale',
   'Répondez à la question : « Comment l''avez-vous obtenue ? » Dites quand vous avez commencé et résumez la démarche en deux ou trois phrases.',
   'Le récit reste court : le moment est situé et la démarche est résumée dans l''ordre.',
   '["Dites quand vous avez commencé", "Résumez la démarche", "Suivez l''ordre réel"]',
   '[{"label": "Temps du passé", "icon": "TENSE"}, {"label": "Récit court", "icon": "STRUCTURE"}]',
   'Quand je suis arrivée en France…', 'un délai dit beaucoup en peu de mots : deux semaines après, un mois plus tard.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO1-C6-S12
  ('EO1-C6-S12', 'Le courrier des impôts',
   'Répondez à la question : « Qu''avez-vous fait après ce courrier ? » Situez le moment et résumez ce que vous avez fait, en gardant l''ordre.',
   'Le récit reste court : le moment est situé et les démarches sont résumées dans l''ordre.',
   '["Dites quand c''était", "Résumez ce que vous avez fait", "Respectez l''ordre des faits"]',
   '[{"label": "Récit court", "icon": "STRUCTURE"}, {"label": "Moment situé", "icon": "TIME"}]',
   'Au printemps, j''ai reçu un courrier…', 'commencez par ce qui a déclenché la démarche : un courrier, une date.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO1-C6-S13
  ('EO1-C6-S13', 'Un colis qui n''arrivait pas',
   'Répondez à la question : « Reprenez cette histoire du début à la fin. » Dites quand c''était et racontez-la brièvement, même si la question invite à tout dérouler.',
   'La réponse situe le moment et reste un récit court, sans basculer dans le récit développé.',
   '["Dites quand c''était", "Racontez-la brièvement", "Ne déroulez pas toute l''histoire"]',
   '[{"label": "Récit court", "icon": "STRUCTURE"}, {"label": "Question ouverte", "icon": "TONE"}]',
   'En décembre, j''attendais un colis important…', '« du début à la fin » ne veut pas dire tout dire : gardez ce qui compte.',
   NULL, NULL, 40, 'HARD'),
  -- EO1-C6-S14
  ('EO1-C6-S14', 'Un rendez-vous à la banque',
   'Répondez à la question : « Racontez-moi ce rendez-vous. » Situez le moment et racontez-le brièvement, sans dérouler toute la rencontre.',
   'La réponse situe le moment et reste un récit court, sans basculer dans le récit développé.',
   '["Dites quand c''était", "Racontez-le brièvement", "Ne déroulez pas toute la rencontre"]',
   '[{"label": "Récit court", "icon": "STRUCTURE"}, {"label": "Question ouverte", "icon": "TONE"}]',
   'Au mois de mai, j''ai rencontré…', 'choisissez le moment qui compte plutôt que de tout raconter.',
   NULL, NULL, 40, 'HARD'),
  -- EO1-C6-S15
  ('EO1-C6-S15', 'Un dégât dans l''appartement',
   'Répondez à la question : « Que s''est-il passé, et ensuite ? » Dites quand c''était et résumez brièvement ce qui s''est passé, même si l''histoire est longue.',
   'La réponse situe le moment et reste un récit court, sans basculer dans le récit développé.',
   '["Dites quand c''était", "Résumez ce qui s''est passé", "Ne déroulez pas toutes les démarches"]',
   '[{"label": "Récit court", "icon": "STRUCTURE"}, {"label": "Question ouverte", "icon": "TONE"}]',
   'L''hiver dernier, une fuite a abîmé…', 'l''assurance, l''artisan, le voisin : nommez qui compte, pas tout le monde.',
   NULL, NULL, 40, 'HARD'),
  -- EO2-C3-S1
  ('EO2-C3-S1', 'S''inscrire aux cours de l''association',
   'Demandez-lui deux choses : comment on s''inscrit et quels documents il faut apporter.',
   'La façon de s''inscrire et les documents à fournir sont demandés explicitement.',
   '["Saluez la bénévole", "Demandez comment s''inscrire", "Demandez les documents à apporter"]',
   '[{"label": "Deux questions", "icon": "NUMBER"}, {"label": "Conditions demandées", "icon": "STRUCTURE"}]',
   'Bonjour madame, je souhaite suivre vos cours…', 'Connaître les horaires ne suffit pas : demandez ce qu''il faut pour s''inscrire.',
   NULL, NULL, 30, 'EASY'),
  -- EO2-C3-S5
  ('EO2-C3-S5', 'Inscrire sa fille au centre de loisirs',
   'Demandez-lui quatre choses : les documents du dossier d''inscription, ce qui est compris dans la journée, ce que l''enfant doit apporter et les règles en cas d''absence.',
   'Les quatre conditions — dossier, prestations comprises, affaires à apporter, règle d''absence — sont réclamées chacune explicitement.',
   '["Saluez le directeur", "Demandez les documents du dossier", "Demandez ce qui est compris", "Demandez la règle en cas d''absence"]',
   '[{"label": "Quatre questions", "icon": "NUMBER"}, {"label": "Conditions demandées", "icon": "STRUCTURE"}]',
   'Bonjour monsieur, ma fille voudrait venir…', 'Les conditions s''oublient plus vite que les horaires : gardez-les toutes en tête.',
   NULL, NULL, 45, 'HARD'),
  -- EO2-C3-S6
  ('EO2-C3-S6', 'Les règles du poste',
   'Demandez-lui deux choses : la tenue ou l''équipement à prévoir et ce qu''il faut faire en cas de retard.',
   'Les deux conditions, l''équipement à prévoir et la règle en cas de retard, sont demandées explicitement.',
   '["Saluez votre tuteur", "Demandez la tenue à prévoir", "Demandez la règle de retard"]',
   '[{"label": "Deux questions", "icon": "NUMBER"}, {"label": "Conditions demandées", "icon": "STRUCTURE"}]',
   'Bonjour monsieur, avant de commencer, pourriez-vous…', 'Deux conditions à connaître avant le premier jour : la tenue et la règle de retard.',
   NULL, NULL, 30, 'EASY'),
  -- EO2-C3-S9
  ('EO2-C3-S9', 'Les conditions pour résilier',
   'Demandez-lui trois choses : la démarche à suivre pour résilier, les documents à envoyer et les frais éventuels.',
   'Les trois conditions, démarche, documents et frais, sont demandées chacune explicitement.',
   '["Saluez la conseillère", "Demandez la démarche à suivre", "Demandez les documents à envoyer", "Demandez s''il y a des frais"]',
   '[{"label": "Trois questions", "icon": "NUMBER"}, {"label": "Conditions demandées", "icon": "STRUCTURE"}]',
   'Bonjour madame, je voudrais faire le point…', 'Savoir qu''on peut résilier ne suffit pas : demandez comment, avec quoi, et à quel prix.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO2-C3-S13
  ('EO2-C3-S13', 'Les règles du jardin partagé',
   'Demandez-lui quatre choses : comment on s''inscrit, les documents à fournir, ce qui est mis à disposition sur place et les règles à respecter.',
   'Les quatre conditions — inscription, documents, matériel fourni, règles — sont réclamées chacune explicitement.',
   '["Saluez le responsable", "Demandez comment s''inscrire", "Demandez ce qui est fourni", "Demandez les règles à respecter"]',
   '[{"label": "Quatre questions", "icon": "NUMBER"}, {"label": "Conditions demandées", "icon": "STRUCTURE"}]',
   'Bonjour monsieur, j''aimerais cultiver une parcelle…', 'Quatre conditions à ramener : inscription, documents, matériel, règles.',
   NULL, NULL, 45, 'HARD'),
  -- EO2-C7-S1
  ('EO2-C7-S1', 'Deux formules à la salle de sport',
   'Interrogez-le sur ce qui distingue les deux formules, et faites-lui préciser au moins une différence qu''il n''a pas donnée.',
   'Les deux formules sont interrogées et au moins une différence non annoncée est obtenue.',
   '["Interrogez les deux formules", "Faites préciser une différence", "Restez dans l''échange"]',
   '[{"label": "Deux formules", "icon": "NUMBER"}, {"label": "Différences explorées", "icon": "STRUCTURE"}]',
   'Si je compare les deux formules…', 'Le prix est déjà donné : cherchez ce qui n''a pas été dit.',
   NULL, NULL, 35, 'EASY'),
  -- EO2-C7-S2
  ('EO2-C7-S2', 'Deux forfaits mobiles',
   'Posez des questions sur ce qui distingue ces deux forfaits, au-delà de ce que le conseiller vient d''annoncer.',
   'Les deux forfaits sont interrogés et au moins une différence non annoncée est obtenue.',
   '["Interrogez les deux forfaits", "Faites préciser une différence", "Restez dans l''échange"]',
   '[{"label": "Deux forfaits", "icon": "NUMBER"}, {"label": "Différences explorées", "icon": "STRUCTURE"}]',
   'Entre les deux forfaits, est-ce que…', 'Prix et gigaoctets sont déjà dits : cherchez les conditions autour.',
   NULL, NULL, 35, 'EASY'),
  -- EO2-C7-S3
  ('EO2-C7-S3', 'Train ou bus pour Lyon',
   'Interrogez la conseillère sur plusieurs différences entre les deux trajets, au-delà du temps et du prix déjà donnés.',
   'Les deux trajets sont interrogés sur au moins deux différences non annoncées.',
   '["Interrogez les deux trajets", "Cherchez deux différences nouvelles", "Restez dans l''échange"]',
   '[{"label": "Deux trajets", "icon": "NUMBER"}, {"label": "Deux différences", "icon": "NUMBER"}]',
   'Entre le train et le bus…', 'Le lieu d''arrivée et les bagages changent souvent plus que le prix.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO2-C7-S4
  ('EO2-C7-S4', 'Cours du soir ou du samedi',
   'Posez des questions sur ces deux formules pour faire apparaître plusieurs différences que le centre n''a pas annoncées.',
   'Les deux formules sont interrogées sur au moins deux différences non annoncées.',
   '["Interrogez les deux formules", "Cherchez deux différences nouvelles", "Restez dans l''échange"]',
   '[{"label": "Deux formules", "icon": "NUMBER"}, {"label": "Deux différences", "icon": "NUMBER"}]',
   'Avant de choisir, j''aimerais savoir si…', 'Le diplôme, le groupe, les absences : tout cela peut différer.',
   NULL, NULL, 45, 'MEDIUM'),
  -- EO2-C7-S5
  ('EO2-C7-S5', 'Deux contrats d''assurance habitation',
   'Posez des questions jusqu''à faire apparaître ce qui distingue vraiment ces deux contrats, au-delà du prix et de la franchise.',
   'Les deux contrats sont interrogés jusqu''à obtenir des différences que l''annonce ne donnait pas.',
   '["Interrogez les deux contrats", "Cherchez ce qui n''est pas dit", "Poursuivez jusqu''à une réponse utile"]',
   '[{"label": "Deux contrats", "icon": "NUMBER"}, {"label": "Différences cachées", "icon": "STRUCTURE"}]',
   'Entre ces deux contrats, est-ce que…', 'Ce qui est couvert compte plus que ce qui est affiché.',
   NULL, NULL, 55, 'HARD'),
  -- EO2-C7-S6
  ('EO2-C7-S6', 'Standard ou express pour le canapé',
   'Interrogez-le sur ce qui distingue ces deux livraisons, au-delà du délai et du prix déjà annoncés.',
   'Les deux livraisons sont interrogées et au moins une différence non annoncée est obtenue.',
   '["Interrogez les deux livraisons", "Faites préciser une différence", "Restez dans l''échange"]',
   '[{"label": "Deux livraisons", "icon": "NUMBER"}, {"label": "Différences explorées", "icon": "STRUCTURE"}]',
   'Entre les deux livraisons, est-ce que…', 'La montée à l''étage et l''emballage ne sont presque jamais annoncés.',
   NULL, NULL, 35, 'EASY'),
  -- EO2-C7-S7
  ('EO2-C7-S7', 'Remboursement ou nouvel article',
   'Posez des questions sur ce qui distingue ces deux solutions, au-delà de ce que le service client vient d''annoncer.',
   'Les deux solutions sont interrogées et au moins une différence non annoncée est obtenue.',
   '["Interrogez les deux solutions", "Faites préciser une différence", "Restez dans l''échange"]',
   '[{"label": "Deux solutions", "icon": "NUMBER"}, {"label": "Différences explorées", "icon": "STRUCTURE"}]',
   'Entre le remboursement et l''échange, est-ce…', 'Le retour de l''article cassé change souvent les délais annoncés.',
   NULL, NULL, 35, 'EASY'),
  -- EO2-C7-S8
  ('EO2-C7-S8', 'Le four à l''atelier ou à domicile',
   'Interrogez le conseiller sur ce qui distingue ces deux solutions, au-delà du prix du déplacement.',
   'Les deux solutions de réparation sont interrogées et au moins une différence non annoncée est obtenue.',
   '["Interrogez les deux solutions", "Demandez le délai de chacune", "Restez dans l''échange"]',
   '[{"label": "Atelier ou domicile", "icon": "PLACE"}, {"label": "Différences explorées", "icon": "STRUCTURE"}]',
   'À domicile ou à l''atelier, quelle…', 'Le délai et la garantie de la réparation ne sont pas toujours les mêmes.',
   NULL, NULL, 30, 'EASY'),
  -- EO2-C7-S9
  ('EO2-C7-S9', 'Deux écrans pour le téléphone',
   'Posez des questions sur ces deux écrans pour faire apparaître plusieurs différences que le réparateur n''a pas annoncées.',
   'Les deux écrans sont interrogés sur au moins deux différences non annoncées.',
   '["Interrogez les deux écrans", "Cherchez deux différences nouvelles", "Restez dans l''échange"]',
   '[{"label": "Deux écrans", "icon": "NUMBER"}, {"label": "Deux différences", "icon": "NUMBER"}]',
   'Avant de choisir, est-ce que l''écran…', 'La qualité d''image et l''étendue de la garantie s''obtiennent en demandant.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO2-C7-S10
  ('EO2-C7-S10', 'Deux jeux de pneus',
   'Interrogez-le sur ces deux jeux de pneus pour faire apparaître plusieurs différences, au-delà du prix et de la tenue sous la pluie.',
   'Les deux jeux de pneus sont interrogés sur au moins deux différences non annoncées.',
   '["Interrogez les deux jeux", "Cherchez deux différences nouvelles", "Restez dans l''échange"]',
   '[{"label": "Deux jeux", "icon": "NUMBER"}, {"label": "Deux différences", "icon": "NUMBER"}]',
   'Entre les deux jeux de pneus…', 'Le kilométrage et le montage sont rarement annoncés d''eux-mêmes.',
   NULL, NULL, 40, 'MEDIUM'),
  -- EO2-C7-S11
  ('EO2-C7-S11', 'Boîte manuelle ou automatique',
   'Posez des questions sur ces deux formules pour faire apparaître plusieurs différences que l''auto-école n''a pas annoncées.',
   'Les deux formules sont interrogées sur au moins deux différences non annoncées.',
   '["Interrogez les deux formules", "Cherchez deux différences nouvelles", "Restez dans l''échange"]',
   '[{"label": "Manuelle ou automatique", "icon": "NUMBER"}, {"label": "Deux différences", "icon": "NUMBER"}]',
   'Avant de m''inscrire, j''aimerais savoir si…', 'Le passage d''un permis à l''autre et le prix de l''heure méritent d''être demandés.',
   NULL, NULL, 45, 'MEDIUM'),
  -- EO2-C7-S12
  ('EO2-C7-S12', 'Deux billets pour le même train',
   'Interrogez l''agent sur ces deux billets pour faire apparaître plusieurs différences, au-delà du prix et de l''échange.',
   'Les deux billets sont interrogés sur au moins deux différences non annoncées.',
   '["Interrogez les deux billets", "Cherchez deux différences nouvelles", "Restez dans l''échange"]',
   '[{"label": "Deux billets", "icon": "NUMBER"}, {"label": "Deux différences", "icon": "NUMBER"}]',
   'Entre ces deux billets, est-ce que…', 'Les frais d''échange et la place réservée ne sont presque jamais annoncés.',
   NULL, NULL, 45, 'MEDIUM'),
  -- EO2-C7-S13
  ('EO2-C7-S13', 'Carnet de tickets ou abonnement',
   'Posez des questions jusqu''à faire apparaître ce qui distingue vraiment ces deux titres, au-delà du prix affiché.',
   'Les deux titres sont interrogés jusqu''à obtenir des différences que l''annonce ne donnait pas.',
   '["Interrogez les deux titres", "Cherchez ce qui n''est pas dit", "Poursuivez jusqu''à une réponse utile"]',
   '[{"label": "Deux titres", "icon": "NUMBER"}, {"label": "Différences cachées", "icon": "STRUCTURE"}]',
   'Entre le carnet et l''abonnement, est-ce…', 'Le réseau couvert et la possibilité d''arrêter ne sont jamais sur l''affiche.',
   NULL, NULL, 55, 'HARD'),
  -- EO2-C7-S14
  ('EO2-C7-S14', 'Quel abonnement de tramway',
   'Interrogez la conseillère sur ces trois possibilités jusqu''à faire apparaître ce qui les distingue vraiment.',
   'Les trois possibilités sont interrogées jusqu''à obtenir des différences que l''annonce ne donnait pas.',
   '["Interrogez les trois possibilités", "Cherchez ce qui n''est pas dit", "Poursuivez jusqu''à une réponse utile"]',
   '[{"label": "Trois possibilités", "icon": "NUMBER"}, {"label": "Différences cachées", "icon": "STRUCTURE"}]',
   'Avant de m''engager, j''aimerais comparer ces…', 'Le calcul du tarif réduit et les justificatifs demandés s''obtiennent en demandant.',
   NULL, NULL, 55, 'HARD'),
  -- EO2-C7-S15
  ('EO2-C7-S15', 'Valise trop lourde à l''aéroport',
   'Posez des questions jusqu''à faire apparaître ce qui distingue vraiment ces deux solutions, au-delà du prix et du délai.',
   'Les deux solutions sont interrogées jusqu''à obtenir des différences que l''annonce ne donnait pas.',
   '["Interrogez les deux possibilités", "Cherchez ce qui n''est pas dit", "Poursuivez jusqu''à une réponse utile"]',
   '[{"label": "Supplément ou colis", "icon": "NUMBER"}, {"label": "Différences cachées", "icon": "STRUCTURE"}]',
   'Entre le supplément et le colis…', 'Le suivi, l''assurance et l''adresse de livraison ne sont pas annoncés.',
   NULL, NULL, 60, 'HARD'),
  -- EO3-C1-S1
  ('EO3-C1-S1', 'Ville ou campagne',
   'Dites si vous préférez vivre en ville ou à la campagne. Votre choix doit être clairement identifiable.',
   'On sait laquelle des deux vous choisissez, sans avoir à le deviner.',
   '["Choisissez : ville ou campagne", "Nommez ce choix clairement", "Tenez ce choix jusqu''au bout"]',
   '[{"label": "Position claire", "icon": "STRUCTURE"}, {"label": "Un seul camp", "icon": "NUMBER"}]',
   'Si je devais choisir, je dirais…', 'nommez votre choix : décrire les deux options ne répond pas à la question',
   NULL, NULL, 30, 'EASY'),
  -- EO3-C1-S2
  ('EO3-C1-S2', 'Cuisiner ou acheter tout prêt',
   'Dites ce que vous préférez : cuisiner vous-même ou acheter des plats préparés. Votre préférence doit être clairement identifiable.',
   'On identifie votre préférence sans avoir à la deviner.',
   '["Nommez ce que vous préférez", "Dites-le sans ambiguïté", "Ne décrivez pas les deux options"]',
   '[{"label": "Préférence explicite", "icon": "STRUCTURE"}, {"label": "Ton personnel", "icon": "TONE"}]',
   'Entre les deux, ma préférence va…', 'une préférence se dit, elle ne se devine pas : nommez-la clairement',
   NULL, NULL, 28, 'EASY'),
  -- EO3-C1-S3
  ('EO3-C1-S3', 'Voiture ou vélo en ville',
   'Dites si, pour vos trajets quotidiens en ville, vous choisiriez plutôt la voiture ou le vélo. Votre position doit rester identifiable même si vous reconnaissez un point à l''autre option.',
   'Votre position reste identifiable, même si vous reconnaissez ensuite un point à l''autre option.',
   '["Annoncez voiture ou vélo", "Gardez la position identifiable", "Concédez au plus un point"]',
   '[{"label": "Position claire", "icon": "STRUCTURE"}, {"label": "Concession brève", "icon": "TONE"}]',
   'Pour mes trajets quotidiens, je choisis…', 'une concession peut s''entendre, à condition qu''on sache toujours ce que vous choisissez',
   NULL, NULL, 30, 'MEDIUM'),
  -- EO3-C1-S4
  ('EO3-C1-S4', 'Téléphone au collège',
   'Dites si vous êtes pour ou contre cette interdiction. On doit comprendre votre position sans avoir à la deviner.',
   'Vous vous positionnez clairement pour ou contre, sans ambiguïté.',
   '["Positionnez-vous : pour ou contre", "Dites-le sans ambiguïté", "Restez sur cette position"]',
   '[{"label": "Pour ou contre", "icon": "STRUCTURE"}, {"label": "Avis assumé", "icon": "TONE"}]',
   'Sur cette question, ma position est…', 'ne vous contentez pas de décrire la situation : donnez votre avis',
   NULL, NULL, 30, 'MEDIUM'),
  -- EO3-C1-S6
  ('EO3-C1-S6', 'Accompagner un nouveau le premier jour',
   'Dites si un nouveau doit être accompagné pendant toute sa première journée. Votre position doit être clairement identifiable.',
   'Annoncer une position claire, sans se contenter de décrire la situation.',
   '["Tranchez : accompagné ou non", "Dites-le clairement", "Gardez la même position"]',
   '[{"label": "Choix annoncé", "icon": "STRUCTURE"}, {"label": "Un seul avis", "icon": "NUMBER"}]',
   'Pour moi, la réponse est…', 'annoncez votre choix sans ambiguïté, les raisons viennent ensuite',
   NULL, NULL, 30, 'EASY'),
  -- EO3-C1-S7
  ('EO3-C1-S7', 'Demander ses congés à l''oral',
   'Dites s''il vaut mieux demander ses congés par mail ou en parlant au responsable. Votre choix doit être clairement identifiable.',
   'Nommer l''option choisie sans la laisser deviner.',
   '["Choisissez : mail ou oral", "Nommez-la clairement", "Tenez ce choix"]',
   '[{"label": "Option nommée", "icon": "STRUCTURE"}, {"label": "Réponse directe", "icon": "TONE"}]',
   'Entre les deux, je choisirais…', 'ne racontez pas la procédure : dites clairement ce que vous choisissez',
   NULL, NULL, 30, 'EASY'),
  -- EO3-C1-S8
  ('EO3-C1-S8', 'Une heure sans bruit au bureau',
   'Dites si vous êtes pour ou contre cette heure sans bruit. On doit le savoir sans avoir à le deviner.',
   'Se placer clairement pour ou contre, sans ambiguïté.',
   '["Dites pour ou contre", "Dites-le clairement", "Ne changez pas ensuite"]',
   '[{"label": "Avis clair", "icon": "STRUCTURE"}, {"label": "Position tenue", "icon": "TONE"}]',
   'Sur cette idée, je suis…', 'dites pour ou contre : commenter la proposition ne suffit pas',
   NULL, NULL, 28, 'EASY'),
  -- EO3-C1-S9
  ('EO3-C1-S9', 'Commencer le chantier à six heures',
   'Dites si vous êtes favorable à ce démarrage à six heures. Votre position doit rester identifiable même si vous reconnaissez une difficulté.',
   'Annoncer clairement favorable ou défavorable et s''y tenir, malgré une difficulté reconnue.',
   '["Annoncez favorable ou non", "Dites-le clairement", "Gardez cet avis"]',
   '[{"label": "Avis clair", "icon": "STRUCTURE"}, {"label": "Horaire tranché", "icon": "TIME"}]',
   'Pour ces horaires d''été, je…', 'un oui ou un non clair, puis une phrase d''explication',
   NULL, NULL, 35, 'MEDIUM'),
  -- EO3-C1-S10
  ('EO3-C1-S10', 'Partager les pourboires en salle',
   'Dites si vous êtes pour ou contre ce partage. Votre position doit être claire, même si vous rapportez l''avis des autres.',
   'Rendre sa position identifiable, sans se cacher derrière l''avis des autres.',
   '["Tranchez : pour ou contre", "Dites-le sans ambiguïté", "Restez sur cette ligne"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Avis unique", "icon": "NUMBER"}]',
   'Sur les pourboires, ma position…', 'rapporter ce que pensent les autres ne remplace pas votre avis',
   NULL, NULL, 35, 'MEDIUM'),
  -- EO3-C1-S11
  ('EO3-C1-S11', 'Changer de poste dans l''entrepôt',
   'Dites si vous préférez tourner sur les postes ou garder le même. Votre préférence doit rester identifiable même si vous pesez le pour et le contre.',
   'Donner une préférence claire, sans se limiter au pour et au contre.',
   '["Choisissez tourner ou rester", "Dites-le sans ambiguïté", "Ne revenez pas dessus"]',
   '[{"label": "Préférence annoncée", "icon": "STRUCTURE"}, {"label": "Sans détour", "icon": "TONE"}]',
   'Si on me demande, je préfère…', 'votre préférence doit s''entendre, pas seulement vos arguments',
   NULL, NULL, 35, 'MEDIUM'),
  -- EO3-C1-S12
  ('EO3-C1-S12', 'Se former sur le temps de travail',
   'Dites laquelle des deux formules vous choisiriez. Le choix doit être clairement identifiable, et ne pas changer en cours de route.',
   'Nommer clairement la formule choisie et ne pas en changer ensuite.',
   '["Choisissez une formule", "Nommez-la clairement", "Gardez ce choix"]',
   '[{"label": "Formule nommée", "icon": "STRUCTURE"}, {"label": "Une seule formule", "icon": "NUMBER"}]',
   'Entre ces deux formules, je prends…', 'la prime ne doit pas vous faire changer d''avis en cours de route',
   NULL, NULL, 35, 'MEDIUM'),
  -- EO3-C5-S1
  ('EO3-C5-S1', 'Deuxième raison, le travail d''équipe',
   'Apportez une idée nouvelle en faveur du travail en équipe. Elle doit porter sur autre chose que la rapidité.',
   'L''idée apportée est nettement différente de la précédente, elle ne la reformule pas.',
   '["Apportez une idée nouvelle", "Changez de terrain", "Écartez la question du temps"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Terrain différent", "icon": "STRUCTURE"}]',
   'Il y a autre chose encore…', 'redire le même argument autrement ne fait pas avancer le propos',
   NULL, NULL, 40, 'EASY'),
  -- EO3-C5-S2
  ('EO3-C5-S2', 'Deuxième raison pour le vélo',
   'Apportez une idée nouvelle en faveur du vélo en ville, sur un autre terrain que l''argent.',
   'Une idée nouvelle est apportée et elle ne parle plus du coût.',
   '["Signalez que vous ajoutez une idée", "Évitez toute question de coût", "Développez cette idée"]',
   '[{"label": "Hors budget", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Sur un tout autre plan…', 'le budget est déjà traité : cherchez un avantage d''une autre nature',
   NULL, NULL, 40, 'EASY'),
  -- EO3-C5-S3
  ('EO3-C5-S3', 'Autre intérêt des sorties scolaires',
   'Apportez une idée nouvelle en faveur des sorties scolaires, différente de la motivation.',
   'L''idée apportée ouvre un autre aspect que celui déjà évoqué.',
   '["Ouvrez un aspect nouveau", "Laissez de côté la motivation", "Expliquez brièvement cet apport"]',
   '[{"label": "Aspect nouveau", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Il y a aussi autre chose…', 'insister sur la motivation reviendrait à répéter ce qui a déjà été dit',
   NULL, NULL, 42, 'MEDIUM'),
  -- EO3-C5-S4
  ('EO3-C5-S4', 'Au-delà du dépistage',
   'Apportez une idée nouvelle en faveur de ces rendez-vous, sur un autre aspect que le dépistage précoce.',
   'L''idée apportée porte sur un aspect nouveau, sans revenir au dépistage.',
   '["Trouvez un intérêt hors dépistage", "Apportez-le comme idée nouvelle", "Montrez qu''il tient seul"]',
   '[{"label": "Hors dépistage", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Un autre intérêt, très différent…', 'revenir au dépistage précoce annulerait l''effet de cette nouvelle idée',
   NULL, NULL, 42, 'MEDIUM'),
  -- EO3-C5-S5
  ('EO3-C5-S5', 'Au-delà du lien familial',
   'Apportez une idée nouvelle en faveur de ces outils, clairement distincte du lien familial.',
   'L''idée apportée aborde un domaine différent du maintien du lien familial.',
   '["Sortez du lien familial", "Nommez un autre domaine", "Illustrez-le en une phrase"]',
   '[{"label": "Autre domaine", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Sur un terrain complètement différent…', 'changez franchement de domaine : le lien familial a déjà été dit',
   NULL, NULL, 45, 'HARD'),
  -- EO3-C5-S6
  ('EO3-C5-S6', 'Garder un gardien dans l''immeuble',
   'Apportez une idée nouvelle en faveur du gardien, sur autre chose que la propreté.',
   'L''idée apportée porte sur autre chose que la propreté des lieux.',
   '["Apportez une idée nouvelle", "Quittez la question de la propreté", "Développez cette idée"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Autre terrain", "icon": "STRUCTURE"}]',
   'Autre chose, tout aussi importante…', 'reparler de propreté ne ferait que redire ce qui a déjà été dit',
   NULL, NULL, 40, 'EASY'),
  -- EO3-C5-S7
  ('EO3-C5-S7', 'Créer un local à vélos',
   'Apportez une idée nouvelle en faveur de ce local, sur un autre terrain que le vol.',
   'L''idée apportée ne revient pas sur la question du vol.',
   '["Signalez une idée nouvelle", "Laissez le vol de côté", "Expliquez cet apport"]',
   '[{"label": "Hors du vol", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Sur un autre point encore…', 'le vol est déjà dit : cherchez un bénéfice d''une autre nature',
   NULL, NULL, 40, 'EASY'),
  -- EO3-C5-S8
  ('EO3-C5-S8', 'La laverie ouverte un jour de plus',
   'Apportez une idée nouvelle en faveur de cette ouverture, différente des horaires de travail.',
   'L''idée apportée sort de la question des horaires de travail.',
   '["Ouvrez un autre terrain", "Évitez la question des horaires", "Appuyez cette idée nouvelle"]',
   '[{"label": "Autre terrain", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Il y a un autre intérêt…', 'revenir aux horaires ferait de votre idée une simple répétition',
   NULL, NULL, 38, 'EASY'),
  -- EO3-C5-S9
  ('EO3-C5-S9', 'Garder des caisses avec caissiers',
   'Apportez une idée nouvelle contre le tout-automatique, sur un autre aspect que la difficulté d''utilisation.',
   'L''idée apportée aborde un aspect nouveau, hors de la difficulté d''utilisation.',
   '["Nommez un aspect nouveau", "Écartez la difficulté d''usage", "Développez cette idée"]',
   '[{"label": "Aspect nouveau", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Ce n''est pas le seul point…', 'revenir à la difficulté d''usage annulerait l''effet de cette idée nouvelle',
   NULL, NULL, 42, 'MEDIUM'),
  -- EO3-C5-S10
  ('EO3-C5-S10', 'Maintenir le marché de la place',
   'Apportez une idée nouvelle pour garder le marché, en dehors de la qualité des produits.',
   'L''idée apportée quitte la question de la qualité des produits.',
   '["Sortez de la qualité", "Apportez une idée nouvelle", "Illustrez-la brièvement"]',
   '[{"label": "Hors qualité", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Une autre idée, très différente…', 'parler encore de fraîcheur reviendrait à répéter ce que vous avez dit',
   NULL, NULL, 42, 'MEDIUM'),
  -- EO3-C5-S11
  ('EO3-C5-S11', 'Acheter son pain juste en bas',
   'Apportez une idée nouvelle en faveur de la boulangerie, hors de la question du goût.',
   'L''idée apportée porte sur autre chose que le goût du pain.',
   '["Quittez la question du goût", "Apportez une idée nouvelle", "Donnez-lui un contenu concret"]',
   '[{"label": "Hors goût", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Il y a un autre aspect…', 'le goût est traité : votre idée doit changer de terrain',
   NULL, NULL, 44, 'MEDIUM'),
  -- EO3-C5-S12
  ('EO3-C5-S12', 'Passer par le boucher du quartier',
   'Apportez une idée nouvelle en faveur de la boucherie, sans revenir au gaspillage.',
   'L''idée apportée n''évoque plus la quantité ni le gaspillage.',
   '["Laissez de côté le gaspillage", "Apportez une idée nouvelle", "Rendez-la concrète"]',
   '[{"label": "Hors gaspillage", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Autre chose, sur un plan différent…', 'reparler de quantité vous ramènerait à ce que vous avez déjà dit',
   NULL, NULL, 44, 'MEDIUM'),
  -- EO3-C5-S13
  ('EO3-C5-S13', 'Les courses livrées à la maison',
   'Apportez une idée nouvelle en faveur de la livraison, sans revenir au poids des courses.',
   'L''idée apportée ouvre un domaine nouveau, hors du transport des sacs.',
   '["Écartez le poids des sacs", "Ouvrez un domaine nouveau", "Développez-le en deux phrases"]',
   '[{"label": "Domaine nouveau", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Sur un autre plan, maintenant…', 'le portage est traité : ouvrez un domaine qui n''en dépend pas',
   NULL, NULL, 46, 'HARD'),
  -- EO3-C5-S14
  ('EO3-C5-S14', 'Un colis livré abîmé',
   'Apportez une idée nouvelle, sur un terrain complètement différent de la responsabilité.',
   'L''idée apportée change de terrain et ne reparle pas de responsabilité.',
   '["Quittez le terrain de la responsabilité", "Nommez un autre terrain", "Argumentez-la clairement"]',
   '[{"label": "Autre terrain", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Il y a un autre angle…', 'reparler de faute ou de responsabilité ne produit aucune idée nouvelle',
   NULL, NULL, 48, 'HARD'),
  -- EO3-C5-S15
  ('EO3-C5-S15', 'Des pièces disponibles dix ans',
   'Apportez une idée nouvelle en faveur de cette obligation, hors de l''argument écologique.',
   'L''idée apportée sort de l''argument écologique déjà donné.',
   '["Sortez de l''argument écologique", "Apportez une idée nouvelle", "Appuyez-la sur un fait"]',
   '[{"label": "Hors écologie", "icon": "STRUCTURE"}, {"label": "Idée nouvelle", "icon": "STRUCTURE"}]',
   'Autre chose, complètement indépendant de ce que j''ai dit…', 'reparler de déchets vous ferait redire ce que vous avez déjà donné',
   NULL, NULL, 48, 'HARD'),
  -- EO3-C8-S1
  ('EO3-C8-S1', 'Sport seul ou en club',
   'Répondez d''un seul tenant, sans que la parole retombe : reliez chaque idée à la précédente.',
   'Le propos est suivi : les idées sont reliées entre elles et la parole ne retombe pas.',
   '["Enchaînez sans vous arrêter", "Reliez chaque idée à la précédente", "Tenez la durée demandée"]',
   '[{"label": "Propos suivi", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'Pour moi, la réponse est…', 'des mots comme « parce que », « du coup », « ce qui fait que » tiennent le fil',
   NULL, NULL, 50, 'EASY'),
  -- EO3-C8-S2
  ('EO3-C8-S2', 'Réparer plutôt que racheter',
   'Répondez d''un seul tenant, en reliant vos idées les unes aux autres.',
   'Le propos est suivi : les idées sont reliées entre elles et la parole ne retombe pas.',
   '["Enchaînez sans vous arrêter", "Reliez chaque idée à la précédente", "Tenez la durée demandée"]',
   '[{"label": "Propos suivi", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'Sur ce point, je penche…', 'un propos qui tient n''est pas un propos long : c''est un propos lié',
   NULL, NULL, 52, 'EASY'),
  -- EO3-C8-S3
  ('EO3-C8-S3', 'Vivre ici suffit-il',
   'Répondez en une prise de parole continue et nourrie, en appuyant chaque idée sur la précédente.',
   'Le propos est suivi et nourri : chaque idée s''appuie sur la précédente, sans rupture.',
   '["Enchaînez sans rupture", "Appuyez chaque idée sur la précédente", "Nourrissez le propos"]',
   '[{"label": "Propos nourri", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'Ma réponse à cette question…', 'reprendre ce que vous venez de dire permet de repartir sans vous arrêter',
   NULL, NULL, 55, 'MEDIUM'),
  -- EO3-C8-S4
  ('EO3-C8-S4', 'Le repas du midi',
   'Répondez d''un seul tenant, en nourrissant votre propos et en reliant chaque idée à la suivante.',
   'Le propos est suivi et nourri : chaque idée s''appuie sur la précédente, sans rupture.',
   '["Enchaînez sans rupture", "Ajoutez un exemple chiffré", "Nourrissez le propos"]',
   '[{"label": "Conseil assumé", "icon": "TONE"}, {"label": "Propos nourri", "icon": "STRUCTURE"}]',
   'Ce que je conseillerais, personnellement…', 'un exemple chiffré nourrit le propos en quelques mots',
   NULL, NULL, 55, 'MEDIUM'),
  -- EO3-C8-S5
  ('EO3-C8-S5', 'Une ville et ses visiteurs',
   'Répondez de manière continue et organisée : un sujet à deux faces invite à empiler les idées, organisez-les au lieu de les énumérer.',
   'Le propos reste organisé au lieu de s''empiler : les idées sont liées et hiérarchisées.',
   '["Organisez au lieu d''énumérer", "Reliez les idées entre elles", "Tenez le fil jusqu''au bout"]',
   '[{"label": "Propos organisé", "icon": "STRUCTURE"}, {"label": "Sans accumulation", "icon": "STRUCTURE"}]',
   'Sur cette question, je dirais…', 'hiérarchisez : une idée principale tenue vaut mieux que six idées posées',
   NULL, NULL, 58, 'HARD'),
  -- EO3-C8-S6
  ('EO3-C8-S6', 'Visite guidée ou visite libre',
   'Reprenez votre réponse d''un seul tenant, en reliant chaque idée à la précédente.',
   'Le propos est suivi : les idées sont reliées entre elles et la parole ne retombe pas.',
   '["Enchaînez sans vous arrêter", "Reliez chaque idée à la précédente", "Tenez la durée demandée"]',
   '[{"label": "Propos suivi", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'Entre les deux, je choisirais…', 'une phrase lâchée puis abandonnée ne fait pas un propos',
   NULL, NULL, 50, 'EASY'),
  -- EO3-C8-S7
  ('EO3-C8-S7', 'Un festival gratuit en été',
   'Répondez en une seule prise de parole continue, en reliant clairement vos idées.',
   'Le propos est suivi : les idées sont reliées entre elles et la parole ne retombe pas.',
   '["Enchaînez sans vous arrêter", "Reliez chaque idée à la précédente", "Tenez la durée demandée"]',
   '[{"label": "Propos suivi", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'Sur ce financement, mon avis…', 'annoncez vos liens : on vous suit sans effort',
   NULL, NULL, 50, 'EASY'),
  -- EO3-C8-S8
  ('EO3-C8-S8', 'Laisser un pourboire ou non',
   'Répondez de façon continue, en reliant vos idées les unes aux autres.',
   'Le propos est suivi : les idées sont reliées entre elles et la parole ne retombe pas.',
   '["Enchaînez sans vous arrêter", "Reliez chaque idée à la précédente", "Tenez la durée demandée"]',
   '[{"label": "Propos suivi", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'Ma réponse tient en une phrase…', 'reprendre votre dernier mot est la façon la plus simple de repartir',
   NULL, NULL, 52, 'EASY'),
  -- EO3-C8-S9
  ('EO3-C8-S9', 'Le dernier café du village',
   'Répondez en une prise de parole continue et nourrie, sans revenir en arrière.',
   'Le propos est suivi et nourri : chaque idée s''appuie sur la précédente, sans rupture.',
   '["Enchaînez sans rupture", "Appuyez chaque idée sur la précédente", "Nourrissez le propos"]',
   '[{"label": "Propos nourri", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'Si la mairie me demandait…', 'avancer, c''est reprendre ce qu''on vient de dire pour aller plus loin',
   NULL, NULL, 55, 'MEDIUM'),
  -- EO3-C8-S10
  ('EO3-C8-S10', 'Traiteur ou cuisine maison',
   'Répondez d''un seul tenant, en nourrissant votre propos et en le reliant d''une idée à l''autre.',
   'Le propos est suivi et nourri : chaque idée s''appuie sur la précédente, sans rupture.',
   '["Enchaînez sans rupture", "Ajoutez un exemple chiffré", "Nourrissez le propos"]',
   '[{"label": "Conseil assumé", "icon": "TONE"}, {"label": "Propos nourri", "icon": "STRUCTURE"}]',
   'Pour cinquante personnes, je conseillerais…', 'un chiffre bien placé nourrit le propos en une phrase',
   NULL, NULL, 55, 'MEDIUM'),
  -- EO3-C8-S11
  ('EO3-C8-S11', 'Tarif remboursable ou non',
   'Répondez en continu, en appuyant chaque idée sur la précédente.',
   'Le propos est suivi et nourri : chaque idée s''appuie sur la précédente, sans rupture.',
   '["Enchaînez sans rupture", "Appuyez chaque idée sur la précédente", "Nourrissez le propos"]',
   '[{"label": "Propos nourri", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'À choisir, je prendrais plutôt…', 'un exemple qui traîne casse le fil : reliez-le à ce qui précède',
   NULL, NULL, 55, 'MEDIUM'),
  -- EO3-C8-S12
  ('EO3-C8-S12', 'Une semaine en camping',
   'Répondez en une prise de parole organisée et nourrie, en reliant chaque idée à la suivante.',
   'Le propos est suivi et nourri : chaque idée s''appuie sur la précédente, sans rupture.',
   '["Enchaînez sans rupture", "Appuyez chaque idée sur la précédente", "Nourrissez le propos"]',
   '[{"label": "Propos nourri", "icon": "STRUCTURE"}, {"label": "Liens explicites", "icon": "STRUCTURE"}]',
   'Avec des enfants, je pencherais…', 'reliez chaque idée : sans lien, la réponse ressemble à une liste',
   NULL, NULL, 56, 'MEDIUM'),
  -- EO3-C8-S13
  ('EO3-C8-S13', 'Passer par l''office de tourisme',
   'Répondez de manière continue et organisée : organisez vos idées au lieu de les énumérer.',
   'Le propos reste organisé au lieu de s''empiler : les idées sont liées et hiérarchisées.',
   '["Organisez au lieu d''énumérer", "Reliez les idées entre elles", "Tenez le fil jusqu''au bout"]',
   '[{"label": "Propos organisé", "icon": "STRUCTURE"}, {"label": "Sans accumulation", "icon": "STRUCTURE"}]',
   'Dans une ville inconnue, personnellement…', 'une idée tenue et développée porte plus loin que quatre idées posées',
   NULL, NULL, 58, 'HARD'),
  -- EO3-C8-S14
  ('EO3-C8-S14', 'Payer l''assurance annulation',
   'Répondez en tenant votre propos d''un bout à l''autre, sans empiler les cas possibles.',
   'Le propos reste organisé au lieu de s''empiler : les idées sont liées et hiérarchisées.',
   '["Organisez au lieu d''énumérer", "Reliez les idées entre elles", "Tenez le fil jusqu''au bout"]',
   '[{"label": "Propos organisé", "icon": "STRUCTURE"}, {"label": "Sans accumulation", "icon": "STRUCTURE"}]',
   'Pour quarante euros, je dirais…', 'évitez d''empiler les cas : une idée développée tient mieux qu''une liste',
   NULL, NULL, 58, 'HARD'),
  -- EO3-C8-S15
  ('EO3-C8-S15', 'Dire qu''on ne sait pas',
   'Répondez d''un seul tenant, sans revenir en arrière et sans tourner en rond.',
   'Le propos reste organisé au lieu de s''empiler : les idées sont liées et hiérarchisées.',
   '["Organisez au lieu d''énumérer", "Reliez les idées entre elles", "Tenez le fil jusqu''au bout"]',
   '[{"label": "Propos organisé", "icon": "STRUCTURE"}, {"label": "Sans accumulation", "icon": "STRUCTURE"}]',
   'En entretien, je choisirais toujours…', 'tourner en rond n''est pas tenir un propos : chaque phrase doit ajouter',
   NULL, NULL, 60, 'HARD')
) AS v(code, title, instruction, unique_criterion, checklist, constraint_tags,
       answer_starter, tip, recommended_min_words, recommended_max_words,
       recommended_duration_seconds, difficulty_level)
WHERE p.code = v.code;

-- Les 228 references dont la V3 a change le texte ou la note : une
-- reference modele qui montre ce que le critere vient d'interdire ferait
-- mentir l'ecran.
UPDATE skill_references r SET
    text             = v.text,
    pedagogical_note = v.note,
    updated_at       = '2026-09-13 09:00:00+02'
FROM (VALUES
  -- EE2-C2-S1 / INSUFFICIENT
  ('EE2-C2-S1', 'INSUFFICIENT',
   'La fête du quartier était vraiment très réussie cette année encore. Tout le monde a beaucoup aimé la musique, les plats et l''ambiance de la soirée.',
   'C''est un avis général : ni personnes, ni activité de départ.'),
  -- EE2-C2-S1 / EXPECTED
  ('EE2-C2-S1', 'EXPECTED',
   'J''étais avec mes voisins et leurs enfants. Nous préparions les tables et les chaises pour le repas du soir.',
   'Les personnes et l''activité suffisent à ouvrir le récit.'),
  -- EE2-C2-S1 / EXCELLENT
  ('EE2-C2-S1', 'EXCELLENT',
   'J''étais avec ma voisine Fatou et son fils. Nous installions les tables et nous coupions des fruits pendant que la musique commençait.',
   'Les prénoms et les gestes précis rendent la scène facile à imaginer.'),
  -- EE2-C2-S2 / INSUFFICIENT
  ('EE2-C2-S2', 'INSUFFICIENT',
   'Le cours de français est très intéressant et la professeure explique toujours très bien. J''apprends beaucoup de choses nouvelles chaque semaine avec mes camarades de classe.',
   'Vous décrivez le cours en général, pas les personnes ni l''activité du moment.'),
  -- EE2-C2-S2 / EXPECTED
  ('EE2-C2-S2', 'EXPECTED',
   'J''étais avec cinq autres élèves de mon groupe. Nous relisions nos exercices de grammaire en attendant l''arrivée de la professeure de français.',
   'Le lecteur voit tout de suite avec qui vous êtes et ce que vous faites.'),
  -- EE2-C2-S2 / EXCELLENT
  ('EE2-C2-S2', 'EXCELLENT',
   'J''étais assis avec cinq autres élèves, nos cahiers ouverts devant nous. Nous comparions nos exercices à voix basse pendant que la professeure installait le tableau.',
   'Chacun a une occupation : la scène vit sans qu''on ait besoin du décor.'),
  -- EE2-C2-S3 / INSUFFICIENT
  ('EE2-C2-S3', 'INSUFFICIENT',
   'Nous avons attendu très longtemps dans le couloir avant de voir le médecin. Ensuite, la visite s''est très bien passée et nous sommes rentrés à la maison.',
   'Le récit avance déjà alors que les personnes et l''activité ne sont pas posées.'),
  -- EE2-C2-S3 / EXPECTED
  ('EE2-C2-S3', 'EXPECTED',
   'J''attendais avec ma fille et son carnet de santé. Elle dessinait tranquillement et je remplissais un formulaire pour la mutuelle.',
   'Deux personnes, deux occupations : c''est exactement la cible.'),
  -- EE2-C2-S3 / EXCELLENT
  ('EE2-C2-S3', 'EXCELLENT',
   'J''attendais avec ma fille Awa assise sur mes genoux. Elle regardait un livre d''images et je remplissais tranquillement le formulaire de la mutuelle.',
   'Chaque personne a une activité propre : la scène devient vivante.'),
  -- EE2-C2-S4 / INSUFFICIENT
  ('EE2-C2-S4', 'INSUFFICIENT',
   'Le voyage a duré presque quatre heures sur l''autoroute, avec un seul arrêt. Le conducteur roulait assez vite et il écoutait la radio pendant tout le trajet. Je suis arrivé très fatigué chez ma sœur, en fin d''après-midi, avec mal au dos.',
   'Ces phrases racontent déjà le trajet sans présenter les personnes.'),
  -- EE2-C2-S4 / EXPECTED
  ('EE2-C2-S4', 'EXPECTED',
   'Le conducteur et deux autres passagers m''attendaient déjà, leurs valises à la main. Nous rangions nos sacs et nos manteaux dans le grand coffre. Personne ne se connaissait encore.',
   'Les personnes et l''activité sont en place avant que le voyage ne commence.'),
  -- EE2-C2-S4 / EXCELLENT
  ('EE2-C2-S4', 'EXCELLENT',
   'J''attendais avec mon sac à dos quand le conducteur, Marc, est arrivé. Il voyageait avec deux autres passagers, une étudiante et un retraité. Pendant que nous rangions les bagages, nous parlions de la route à faire.',
   'L''activité partagée relie naturellement les personnes entre elles.'),
  -- EE2-C2-S5 / INSUFFICIENT
  ('EE2-C2-S5', 'INSUFFICIENT',
   'Un client s''est énervé à la caisse numéro deux et j''ai appelé mon responsable tout de suite. Après quelques minutes de discussion, tout est redevenu calme dans le magasin. C''était vraiment une journée très difficile pour toute l''équipe et pour moi.',
   'L''incident est déjà raconté ; les personnes et l''activité restent absentes.'),
  -- EE2-C2-S5 / EXPECTED
  ('EE2-C2-S5', 'EXPECTED',
   'J''étais en service avec ma collègue Sonia, qui encaissait juste à côté de moi. Il y avait beaucoup de clients et nous étions toutes les deux très occupées. Nous n''avions pas eu une minute depuis le début du service.',
   'Les personnes et l''activité sont complètes et l''incident n''est pas dévoilé.'),
  -- EE2-C2-S5 / EXCELLENT
  ('EE2-C2-S5', 'EXCELLENT',
   'Ma collègue Sonia encaissait juste à côté de moi et rangeait les rayons entre deux clients. Nous travaillions vite, sans nous parler, depuis le début du service. Tout se passait normalement.',
   'La dernière phrase crée une attente sans rien révéler : c''est habile.'),
  -- EE2-C2-S6 / INSUFFICIENT
  ('EE2-C2-S6', 'INSUFFICIENT',
   'Le déménagement a été très fatigant et nous avons fini tard le soir. Heureusement, mes amis étaient là et rien n''a été cassé.',
   'C''est le bilan de la journée : les personnes et l''activité de départ manquent.'),
  -- EE2-C2-S6 / EXPECTED
  ('EE2-C2-S6', 'EXPECTED',
   'J''étais avec deux amis, Karim et Ana, à côté de la camionnette louée. Nous descendions les premiers cartons par l''escalier.',
   'Les personnes et l''activité : la situation initiale est complète.'),
  -- EE2-C2-S6 / EXCELLENT
  ('EE2-C2-S6', 'EXCELLENT',
   'J''étais avec Karim et Ana, arrivés à huit heures pour m''aider. Nous descendions les cartons par l''escalier pendant que ma sœur surveillait les meubles.',
   'Chacun a une occupation précise : la scène de départ devient vivante.'),
  -- EE2-C2-S7 / INSUFFICIENT
  ('EE2-C2-S7', 'INSUFFICIENT',
   'Mon voisin s''était enfermé dehors et il a sonné chez moi pour téléphoner. Je l''ai fait entrer et il a appelé le gardien pour ouvrir sa porte.',
   'L''histoire commence déjà : on ne sait pas avec qui vous étiez ni ce que vous faisiez.'),
  -- EE2-C2-S7 / EXPECTED
  ('EE2-C2-S7', 'EXPECTED',
   'J''étais avec ma femme et notre fils, vers la fin du repas. Nous finissions de manger et la radio était allumée.',
   'Les personnes et l''activité sont posées avant l''événement.'),
  -- EE2-C2-S7 / EXCELLENT
  ('EE2-C2-S7', 'EXCELLENT',
   'J''étais avec ma femme et notre fils Élias, tous les trois autour de la table. Nous finissions de dîner, la radio allumée, et nous n''attendions aucune visite.',
   'La dernière précision installe le calme d''avant sans rien raconter.'),
  -- EE2-C2-S8 / INSUFFICIENT
  ('EE2-C2-S8', 'INSUFFICIENT',
   'L''interphone ne marchait plus depuis une semaine et personne ne pouvait sonner chez moi. J''en ai parlé au gardien, qui a promis d''appeler une entreprise.',
   'Vous expliquez le problème sans jamais dire qui était là ni ce que chacun faisait.'),
  -- EE2-C2-S8 / EXPECTED
  ('EE2-C2-S8', 'EXPECTED',
   'J''étais avec le gardien, monsieur Vasseur, et une voisine du deuxième étage. Il triait le courrier et nous attendions tous les deux devant les boîtes aux lettres.',
   'Le lecteur voit les personnes et ce que chacun fait.'),
  -- EE2-C2-S8 / EXCELLENT
  ('EE2-C2-S8', 'EXCELLENT',
   'Je descendais mes poubelles quand j''ai croisé le gardien, monsieur Vasseur. Il triait le courrier pendant qu''une voisine du deuxième attendait son colis.',
   'Trois occupations différentes rendent la situation de départ très concrète.'),
  -- EE2-C2-S9 / INSUFFICIENT
  ('EE2-C2-S9', 'INSUFFICIENT',
   'Le local à vélos de la résidence est souvent mal rangé et la porte ferme mal. Beaucoup d''habitants s''en plaignent depuis longtemps auprès du syndic.',
   'C''est une description générale, pas les personnes ni l''activité d''un soir précis.'),
  -- EE2-C2-S9 / EXPECTED
  ('EE2-C2-S9', 'EXPECTED',
   'J''étais avec un voisin du rez-de-chaussée. J''accrochais mon cadenas pendant qu''il gonflait les pneus du vélo de sa fille.',
   'Le voisin et vos gestes composent une situation complète.'),
  -- EE2-C2-S9 / EXCELLENT
  ('EE2-C2-S9', 'EXCELLENT',
   'J''accrochais mon vélo pendant que mon voisin du rez-de-chaussée gonflait les pneus de celui de sa fille. Nous parlions de la porte qui ferme mal, sans nous presser.',
   'La conversation en plus des gestes ancre la scène dans un vrai moment.'),
  -- EE2-C2-S10 / INSUFFICIENT
  ('EE2-C2-S10', 'INSUFFICIENT',
   'Ma machine à laver est tombée en panne, alors je vais à la laverie chaque dimanche. C''est pratique, mais cela coûte assez cher à la fin du mois.',
   'Vous parlez d''une habitude au lieu d''installer les personnes et l''activité d''un moment précis.'),
  -- EE2-C2-S10 / EXPECTED
  ('EE2-C2-S10', 'EXPECTED',
   'J''attendais la fin de ma machine avec deux autres clients. Je lisais les annonces affichées près de la porte.',
   'Les personnes et votre occupation sont données d''emblée.'),
  -- EE2-C2-S10 / EXCELLENT
  ('EE2-C2-S10', 'EXCELLENT',
   'J''attendais assise, mon sac de linge à mes pieds, en relisant mes fiches de français. Un étudiant pliait ses draps près de la fenêtre et une dame surveillait son séchoir.',
   'Chaque personne a son activité propre : l''attente devient une vraie scène.'),
  -- EE2-C2-S11 / INSUFFICIENT
  ('EE2-C2-S11', 'INSUFFICIENT',
   'Le supermarché est toujours plein le samedi et il n''y a jamais assez de caisses ouvertes. Les clients s''énervent souvent et l''attente dure vingt minutes. C''est un vrai problème dans ce magasin.',
   'Vous décrivez le magasin en général, pas les personnes ni ce qu''elles faisaient.'),
  -- EE2-C2-S11 / EXPECTED
  ('EE2-C2-S11', 'EXPECTED',
   'J''attendais avec mon fils, qui tenait la liste des courses. Mon chariot était plein et je sortais mon porte-monnaie. Derrière nous, une dame âgée posait ses articles sur le tapis.',
   'Les personnes et les gestes de chacun sont bien en place.'),
  -- EE2-C2-S11 / EXCELLENT
  ('EE2-C2-S11', 'EXCELLENT',
   'J''attendais coincée entre deux chariots pleins, mon fils Adam à côté de moi. Il rangeait nos courses dans les sacs et comptait les articles à voix haute. Derrière nous, une dame âgée cherchait sa carte de fidélité dans son porte-monnaie.',
   'Les occupations de chacun donnent une scène complète.'),
  -- EE2-C2-S12 / INSUFFICIENT
  ('EE2-C2-S12', 'INSUFFICIENT',
   'Mon ami vend des légumes au marché depuis cinq ans et il connaît tous ses clients. Son stand marche très bien, surtout le dimanche. Il m''a demandé de l''aider parce que son frère était absent.',
   'Vous présentez votre ami en général, pas ce que chacun faisait ce matin-là.'),
  -- EE2-C2-S12 / EXPECTED
  ('EE2-C2-S12', 'EXPECTED',
   'J''aidais mon ami Mehdi, qui vend des légumes. Sa femme servait les clients à côté de moi. Je remplissais les cageots de tomates et je pesais les sacs.',
   'Les personnes et vos gestes forment une situation initiale nette.'),
  -- EE2-C2-S12 / EXCELLENT
  ('EE2-C2-S12', 'EXCELLENT',
   'Mon ami Mehdi installait la balance pendant que sa femme accrochait les étiquettes de prix. Je sortais les cageots de tomates du camion, les mains déjà froides. Aucun client n''était encore arrivé.',
   'Chaque personne a une tâche précise, et rien de la suite n''est raconté.'),
  -- EE2-C2-S13 / INSUFFICIENT
  ('EE2-C2-S13', 'INSUFFICIENT',
   'La vendeuse nous a dit qu''il n''y aurait plus de baguettes avant dix minutes. Nous avons attendu et ma fille a choisi un pain au chocolat. Nous sommes rentrés à la maison pour le petit-déjeuner.',
   'Le récit avance déjà : les personnes et leur activité ne sont jamais posées.'),
  -- EE2-C2-S13 / EXPECTED
  ('EE2-C2-S13', 'EXPECTED',
   'J''attendais avec ma fille Lina. Cinq personnes patientaient devant nous et la vendeuse remplissait les paniers de baguettes. Nous regardions les gâteaux dans la vitrine en attendant notre tour.',
   'Les personnes et leurs gestes sont complets, et rien de la suite n''est dévoilé.'),
  -- EE2-C2-S13 / EXCELLENT
  ('EE2-C2-S13', 'EXCELLENT',
   'J''attendais avec ma fille Lina, qui serrait la monnaie dans sa main. Devant nous, un habitué discutait avec la vendeuse sans se presser. Personne ne semblait pressé d''avancer.',
   'Les occupations de chacun créent une attente sans rien raconter de la suite.'),
  -- EE2-C2-S14 / INSUFFICIENT
  ('EE2-C2-S14', 'INSUFFICIENT',
   'J''achète souvent chez l''épicier de ma rue parce qu''il ferme tard le soir. Les prix sont plus élevés qu''au supermarché, mais c''est très pratique. Le commerçant est toujours aimable avec ses clients.',
   'Vous parlez de vos habitudes, pas des personnes ni de l''activité d''un moment précis.'),
  -- EE2-C2-S14 / EXPECTED
  ('EE2-C2-S14', 'EXPECTED',
   'L''épicier, monsieur Tahar, était derrière son comptoir. Deux clientes attendaient avec leurs paniers. Je choisissais des œufs et du lait pour le dîner.',
   'Les personnes et votre geste installent bien la situation.'),
  -- EE2-C2-S14 / EXCELLENT
  ('EE2-C2-S14', 'EXCELLENT',
   'Monsieur Tahar coupait du fromage derrière son comptoir, la radio allumée doucement. Deux clientes discutaient en attendant leur tour. Je remplissais mon panier d''œufs et de lait, sans me presser.',
   'Les gestes de chacun donnent une scène très nette.'),
  -- EE2-C2-S15 / INSUFFICIENT
  ('EE2-C2-S15', 'INSUFFICIENT',
   'Le livreur est arrivé avec deux heures de retard et il était seul pour monter la machine. Nous avons dû l''aider dans l''escalier jusqu''au troisième étage. Finalement, tout s''est bien terminé et l''appareil fonctionne.',
   'La livraison est déjà racontée ; les personnes et leur activité, elles, ne le sont pas.'),
  -- EE2-C2-S15 / EXPECTED
  ('EE2-C2-S15', 'EXPECTED',
   'J''attendais la livraison avec mon frère, venu m''aider. Il regardait par la fenêtre pendant que je vidais la buanderie. Nous ne savions pas à quelle heure le camion passerait.',
   'Les personnes et vos gestes tiennent toute l''attente.'),
  -- EE2-C2-S15 / EXCELLENT
  ('EE2-C2-S15', 'EXCELLENT',
   'Mon frère Yacine surveillait la rue depuis la fenêtre, le téléphone posé à côté de lui. Je démontais l''ancien appareil et je poussais les cartons contre le mur. Nous nous relayions sans nous parler.',
   'Deux occupations en parallèle remplissent l''attente sans jamais l''achever.'),
  -- EE2-C3-S3 / EXCELLENT
  ('EE2-C3-S3', 'EXCELLENT',
   'Il pleuvait et j''attendais le bus depuis dix minutes lorsqu''une dame perdue m''a demandé son chemin. Je lui ai expliqué la direction de la mairie et elle m''a remercié deux fois.',
   'Le décor se distingue nettement des actions, sans jamais se confondre avec elles.'),
  -- EE2-C3-S4 / EXPECTED
  ('EE2-C3-S4', 'EXPECTED',
   'Je préparais le dîner dans la cuisine quand l''eau s''est arrêtée d''un coup. Je suis descendu voir la gardienne au rez-de-chaussée pour lui expliquer le problème. Elle a appelé un plombier tout de suite et elle m''a promis une réparation rapide.',
   'Le décor et les actions se distinguent clairement l''un de l''autre.'),
  -- EE2-C3-S5 / EXPECTED
  ('EE2-C3-S5', 'EXPECTED',
   'J''étais un peu stressé parce que la salle était grande et très silencieuse. La recruteuse m''a posé plusieurs questions sur mon expérience et sur mes horaires. J''ai répondu calmement à toutes ses questions et je suis sorti du bureau après trente minutes d''entretien.',
   'Le décor reste en arrière-plan pendant que les trois actions avancent.'),
  -- EE2-C3-S9 / EXCELLENT
  ('EE2-C3-S9', 'EXCELLENT',
   'Il faisait froid dans l''atelier et le mécanicien terminait une camionnette quand mon tour est arrivé. Il a écouté le moteur deux minutes, puis il m''a montré la courroie abîmée.',
   'La scène reste en arrière-plan pendant que les actions se succèdent.'),
  -- EE2-C3-S10 / EXPECTED
  ('EE2-C3-S10', 'EXPECTED',
   'La rue était calme et j''étais très nerveux derrière le volant. J''ai démarré doucement et j''ai fait deux fois le tour du quartier avec la monitrice.',
   'Le décor reste en arrière-plan pendant que vos gestes avancent.'),
  -- EE2-C3-S12 / EXPECTED
  ('EE2-C3-S12', 'EXPECTED',
   'Il faisait encore nuit et une dizaine de personnes attendaient à l''arrêt provisoire. Le bus de remplacement est arrivé avec dix minutes de retard. Je suis monté, j''ai validé mon titre et je suis arrivé juste à l''heure au travail.',
   'Le décor du matin reste en arrière-plan et chaque action se termine nettement.'),
  -- EE2-C3-S14 / EXCELLENT
  ('EE2-C3-S14', 'EXCELLENT',
   'Il était minuit passé, le tapis tournait à vide et les derniers voyageurs partaient un par un. J''ai fait deux fois le tour de la salle, puis j''ai rejoint le comptoir de la compagnie. L''employé a rempli une déclaration avec moi et ma valise est arrivée chez moi deux jours plus tard.',
   'Le décor de la nuit encadre des démarches toutes clairement achevées.'),
  -- EE2-C3-S15 / EXCELLENT
  ('EE2-C3-S15', 'EXCELLENT',
   'Il pleuvait, la nuit tombait et les autres passagers dormaient depuis Poitiers. Le conducteur a dépassé notre sortie sans la voir, puis il a soupiré très fort. J''ai ouvert la carte sur mon téléphone et nous avons retrouvé la bonne route vingt kilomètres plus loin.',
   'L''ambiance du trajet encadre des actions toutes parfaitement terminées.'),
  -- EE2-C8-S3 / EXPECTED
  ('EE2-C8-S3', 'EXPECTED',
   'Le plombier est venu réparer le tuyau du voisin du dessus dès le lendemain. Les travaux de peinture ont été faits deux semaines plus tard. Depuis, la salle de bains est bien sèche et le plafond n''a plus aucune trace d''humidité.',
   'La réparation et son résultat referment nettement le récit.'),
  -- EE2-C8-S4 / EXCELLENT
  ('EE2-C8-S4', 'EXCELLENT',
   'Mon responsable a d''abord soupiré, puis il a vu l''annonce de la grève sur son téléphone et il a accepté mon explication. J''ai rattrapé mon heure le soir même, sans discuter. Depuis, je regarde l''application des transports avant de me coucher et je pars vingt minutes plus tôt.',
   'La conséquence se voit concrètement dans vos habitudes.'),
  -- EE2-C8-S5 / EXPECTED
  ('EE2-C8-S5', 'EXPECTED',
   'Au mois d''avril, j''ai reçu ma carte de séjour de deux ans. Je peux maintenant signer un contrat de travail sans expliquer ma situation à chaque employeur. Cette longue attente m''a appris à préparer chaque document à l''avance et à en garder une copie.',
   'Le résultat et son effet referment le récit sans rien exagérer.'),
  -- EE2-C8-S7 / EXCELLENT
  ('EE2-C8-S7', 'EXCELLENT',
   'Le dentiste a soigné la carie en une séance de quarante minutes et m''a posé un plombage blanc. Depuis, je mange des deux côtés sans y penser, et j''ai enfin pris un rendez-vous de contrôle pour dans six mois.',
   'Le résultat est suivi d''un effet concret dans votre quotidien.'),
  -- EE2-C8-S8 / EXCELLENT
  ('EE2-C8-S8', 'EXCELLENT',
   'Au mois de septembre, la halte-garderie m''a accordé deux matinées par semaine, le mardi et le jeudi. Depuis, je suis mon cours de français sans ma fille sur les genoux, et elle s''est fait deux petites camarades.',
   'La conséquence est concrète et la fin ne laisse rien en suspens.'),
  -- EE2-C8-S9 / EXPECTED
  ('EE2-C8-S9', 'EXPECTED',
   'La directrice m''a reçue en mai et a inscrit mon fils à un soutien en lecture, deux fois par semaine. À la fin de l''année, il lisait des textes courts sans se décourager. Depuis, il prend un livre tout seul le soir, ce qui n''arrivait jamais avant.',
   'La décision et son effet sur votre fils referment nettement le récit.'),
  -- EE2-C8-S10 / EXPECTED
  ('EE2-C8-S10', 'EXPECTED',
   'À la fin de la réunion, le professeur principal a proposé que ma fille s''inscrive à l''aide aux devoirs du lundi. Elle a commencé la semaine suivante et ses notes de mathématiques sont remontées avant les vacances. Depuis, elle ose lever la main en classe, ce que les professeurs ont remarqué.',
   'La décision et le changement observé referment la soirée sans rien laisser ouvert.'),
  -- EE2-C8-S11 / EXCELLENT
  ('EE2-C8-S11', 'EXCELLENT',
   'Au bout de trois semaines, une employée du service scolaire a accepté mon attestation de la CAF et a corrigé mon dossier devant moi. Mon fils a repris la cantine le lundi suivant, au tarif le plus bas, sans rien remarquer du tout. Depuis, je finis mes matinées sans regarder l''heure et je garde une copie de chaque document dans une pochette bleue.',
   'La conséquence se voit dans votre emploi du temps, pas seulement dans les mots.'),
  -- EE2-C8-S13 / EXPECTED
  ('EE2-C8-S13', 'EXPECTED',
   'En novembre, la mairie m''a envoyé un acte de naissance corrigé, avec le prénom complet de mon fils. J''ai enfin pu demander sa carte d''identité et l''inscrire au club de football, ce qui était bloqué depuis un an. Cette histoire m''a appris à vérifier chaque papier officiel le jour même où je le reçois.',
   'Le résultat daté et son effet réel referment le récit sans rien exagérer.'),
  -- EE2-C8-S14 / EXPECTED
  ('EE2-C8-S14', 'EXPECTED',
   'Six semaines après le dépôt de plainte, la préfecture m''a remis un nouveau titre de séjour. J''ai pu reprendre mon travail d''intérim, qui m''était refusé sans document valide. Cette période m''a appris à garder une photocopie de mes papiers chez ma sœur.',
   'Le résultat et son effet sur votre travail referment le récit sans rien forcer.'),
  -- EE2-C8-S15 / EXPECTED
  ('EE2-C8-S15', 'EXPECTED',
   'Le versement a repris au mois de mars, avec le rappel des deux mois manquants. J''ai pu payer mon loyer sans emprunter à ma sœur et rattraper ma facture d''électricité. Depuis, je vérifie mon espace personnel une fois par mois, pour ne plus rien laisser passer.',
   'Le résultat et son effet sur votre budget referment nettement le récit.'),
  -- EO1-C6-S3 / EXPECTED
  ('EO1-C6-S3', 'EXPECTED',
   'Il y a deux semaines, j''ai pris rendez-vous chez le médecin. J''ai attendu un peu dans la salle d''attente, puis le médecin m''a examinée et il m''a donné un traitement.',
   'Le moment est situé et l''essentiel est raconté sans s''étendre.'),
  -- EO1-C6-S3 / EXCELLENT
  ('EO1-C6-S3', 'EXCELLENT',
   'Il y a deux semaines, j''ai pris rendez-vous en ligne pour le jeudi matin. Je suis arrivée dix minutes avant et j''ai attendu dans la salle d''attente. Ensuite, le médecin m''a examinée et m''a posé des questions. À la fin, il m''a donné une ordonnance et je suis passée à la pharmacie.',
   'Le récit reste court et donne pourtant tout ce qu''il faut.'),
  -- EO1-C6-S5 / INSUFFICIENT
  ('EO1-C6-S5', 'INSUFFICIENT',
   'Mon premier jour, j''étais très stressée, mais après ça a été.',
   'Rien n''est situé ni raconté : la question reste sans réponse.'),
  -- EO1-C6-S5 / EXPECTED
  ('EO1-C6-S5', 'EXPECTED',
   'L''année dernière, j''ai commencé dans une boulangerie. Le premier jour, je suis arrivée à six heures, la responsable m''a montré le travail et j''ai servi les clients. J''étais fatiguée, mais contente.',
   'Le récit est situé, ordonné, et s''arrête au bon moment.'),
  -- EO1-C6-S5 / EXCELLENT
  ('EO1-C6-S5', 'EXCELLENT',
   'L''année dernière, en septembre, j''ai commencé dans une boulangerie. Le premier jour, je suis arrivée à six heures du matin. D''abord, la responsable m''a montré la machine à café et les prix. Ensuite, j''ai servi mes premiers clients et j''ai fait une erreur avec la monnaie. Une collègue m''a aidée tout de suite. Le soir, j''étais fatiguée, mais vraiment contente d''avoir tenu.',
   'Un seul détail bien choisi rend le récit vivant sans l''allonger.'),
  -- EO1-C6-S9 / EXPECTED
  ('EO1-C6-S9', 'EXPECTED',
   'L''an dernier, j''ai créé mon compte sur le site de la CAF. J''ai rempli le formulaire, puis j''ai envoyé mes documents. Trois semaines après, j''ai reçu la réponse.',
   'Le moment est donné et la démarche est résumée sans trou.'),
  -- EO1-C6-S9 / EXCELLENT
  ('EO1-C6-S9', 'EXCELLENT',
   'L''an dernier, en octobre, j''ai créé mon compte sur le site de la CAF. D''abord, j''ai rempli le formulaire avec mes revenus. Ensuite, j''ai photographié mon bail et ma pièce d''identité pour les envoyer. Il manquait une attestation, donc je suis allée à l''accueil la semaine suivante. Enfin, j''ai reçu la réponse trois semaines après.',
   'La difficulté retenue suffit à rendre le résumé concret.'),
  -- EO1-C6-S10 / EXPECTED
  ('EO1-C6-S10', 'EXPECTED',
   'Il y a trois semaines, j''ai eu un rendez-vous avec ma conseillère. J''ai apporté mon CV, elle m''a posé des questions sur mes recherches, et elle m''a proposé une formation.',
   'Le moment est situé et le rendez-vous tient en quelques phrases.'),
  -- EO1-C6-S10 / EXCELLENT
  ('EO1-C6-S10', 'EXCELLENT',
   'Il y a trois semaines, j''ai eu un rendez-vous avec ma conseillère, à neuf heures. D''abord, j''ai apporté mon CV et la liste de mes candidatures. Ensuite, elle m''a posé des questions sur les métiers qui m''intéressent. Enfin, elle m''a proposé une formation de trois mois, et j''ai dit oui tout de suite.',
   'Le résumé se termine sur la décision : c''est ce qu''on retient.'),
  -- EO1-C6-S11 / EXPECTED
  ('EO1-C6-S11', 'EXPECTED',
   'Quand je suis arrivée en France, en 2023, j''ai rempli un dossier à la CPAM. J''ai envoyé mon contrat de travail et mon acte de naissance, puis j''ai reçu la carte deux mois après.',
   'Le moment est donné et la démarche est résumée clairement.'),
  -- EO1-C6-S11 / EXCELLENT
  ('EO1-C6-S11', 'EXCELLENT',
   'Quand je suis arrivée en France, en 2023, je suis allée à l''accueil de la CPAM pour prendre le formulaire. D''abord, je l''ai rempli avec l''aide d''une amie. Ensuite, j''ai envoyé mon contrat de travail et mon acte de naissance traduit. Un mois après, j''ai reçu un numéro provisoire, et la carte est arrivée deux mois plus tard.',
   'Deux dates suffisent à faire avancer le récit sans l''allonger.'),
  -- EO1-C6-S12 / EXPECTED
  ('EO1-C6-S12', 'EXPECTED',
   'Au printemps, j''ai reçu un courrier des impôts. Je n''ai pas compris, donc je suis allé au centre des finances publiques. Une dame m''a expliqué, et j''ai corrigé ma déclaration sur internet.',
   'Un moment situé, puis un résumé clair et dans l''ordre.'),
  -- EO1-C6-S13 / INSUFFICIENT
  ('EO1-C6-S13', 'INSUFFICIENT',
   'Une fois, mon colis n''est jamais arrivé, c''était vraiment énervant.',
   'Ni moment, ni déroulement : le récit n''existe pas.'),
  -- EO1-C6-S13 / EXPECTED
  ('EO1-C6-S13', 'EXPECTED',
   'En décembre, j''attendais un colis important. Le facteur est passé quand je n''étais pas là, donc je suis allé au bureau de poste avec l''avis. Ils me l''ont donné le lendemain.',
   'Le moment et l''essentiel sont là, et la réponse s''arrête à temps.'),
  -- EO1-C6-S13 / EXCELLENT
  ('EO1-C6-S13', 'EXCELLENT',
   'En décembre, j''attendais un colis important pour l''anniversaire de ma fille. Le facteur est passé un matin où je travaillais, et il a laissé un avis. Le samedi, je suis allé au bureau de poste, mais le colis n''était pas encore arrivé. J''ai suivi l''envoi sur internet et j''y suis retourné le mardi. Finalement, je l''ai récupéré à temps.',
   'Le récit reste court et se termine pourtant nettement.'),
  -- EO1-C6-S14 / INSUFFICIENT
  ('EO1-C6-S14', 'INSUFFICIENT',
   'Je suis allé voir mon conseiller pour un crédit, j''étais un peu stressé.',
   'Le rendez-vous n''est ni situé ni raconté : la question reste sans réponse.'),
  -- EO1-C6-S14 / EXPECTED
  ('EO1-C6-S14', 'EXPECTED',
   'Au mois de mai, j''ai rencontré mon conseiller pour ouvrir un compte pour mon fils. J''ai apporté nos papiers, il m''a expliqué les frais, et j''ai signé les documents. Je suis sorti rassuré.',
   'Le moment est situé, l''essentiel est dit, et la réponse s''arrête à temps.'),
  -- EO1-C6-S14 / EXCELLENT
  ('EO1-C6-S14', 'EXCELLENT',
   'Au mois de mai, j''ai rencontré mon conseiller pour ouvrir un compte pour mon fils. D''abord, j''ai apporté nos pièces d''identité et un justificatif de domicile. Ensuite, il m''a expliqué les frais et j''ai posé des questions sur la carte. À la fin, j''ai signé les documents et il m''a donné un rendez-vous en septembre. Je suis sorti rassuré, parce que j''avais peur de ne pas tout comprendre.',
   'Un détail bien choisi remplace avantageusement dix phrases.'),
  -- EO1-C6-S15 / INSUFFICIENT
  ('EO1-C6-S15', 'INSUFFICIENT',
   'J''ai eu un dégât des eaux et l''assurance s''est occupée de tout.',
   'Le problème est nommé, mais rien n''est raconté ni situé.'),
  -- EO1-C6-S15 / EXPECTED
  ('EO1-C6-S15', 'EXPECTED',
   'L''hiver dernier, une fuite a abîmé le mur de ma cuisine. J''ai appelé mon assurance le jour même et j''ai envoyé des photos. Un expert est venu, et l''assurance a payé les réparations.',
   'Le moment et l''essentiel s''enchaînent sans que la réponse s''allonge.'),
  -- EO1-C6-S15 / EXCELLENT
  ('EO1-C6-S15', 'EXCELLENT',
   'L''hiver dernier, une fuite du voisin du dessus a abîmé le mur de ma cuisine. Le jour même, j''ai appelé mon assurance et une conseillère m''a demandé des photos. Ensuite, j''ai rempli un papier avec mon voisin. Un expert est passé deux semaines plus tard, il a tout regardé, et l''assurance a payé les réparations en mars.',
   'Deux repères suffisent, et la fin reste claire.'),
  -- EO2-C3-S1 / INSUFFICIENT
  ('EO2-C3-S1', 'INSUFFICIENT',
   'Bonjour madame. Je voudrais m''inscrire aux cours de français, s''il vous plaît.',
   'L''intention est annoncée, mais ni la démarche ni les documents ne sont demandés.'),
  -- EO2-C3-S1 / EXPECTED
  ('EO2-C3-S1', 'EXPECTED',
   'Bonjour madame. Je souhaite suivre vos cours de français. Comment est-ce que je m''inscris, et quels documents dois-je apporter ?',
   'Les deux conditions sont demandées clairement, dans une seule prise de parole.'),
  -- EO2-C3-S1 / EXCELLENT
  ('EO2-C3-S1', 'EXCELLENT',
   'Bonjour madame. Je souhaite suivre vos cours de français. Faut-il s''inscrire sur place ou en ligne, quels documents dois-je apporter, et y a-t-il un test de niveau avant l''entrée en cours ?',
   'Une troisième condition s''ajoute naturellement, sans alourdir la demande.'),
  -- EO2-C3-S5 / INSUFFICIENT
  ('EO2-C3-S5', 'INSUFFICIENT',
   'Bonjour monsieur. Qu''est-ce qu''il faut apporter pour inscrire ma fille cet été ?',
   'Une seule condition est réclamée : trois des quatre restent inconnues.'),
  -- EO2-C3-S5 / EXPECTED
  ('EO2-C3-S5', 'EXPECTED',
   'Bonjour monsieur. Ma fille voudrait venir cet été. Quels documents faut-il pour le dossier, qu''est-ce qui est compris dans la journée, que doit-elle apporter, et que se passe-t-il si elle est absente un jour ?',
   'Les quatre conditions sont posées clairement, sans que l''échange devienne confus.'),
  -- EO2-C3-S5 / EXCELLENT
  ('EO2-C3-S5', 'EXCELLENT',
   'Bonjour monsieur. Ma fille a huit ans et je voudrais l''inscrire pour le mois de juillet. Quelles pièces dois-je fournir pour le dossier, le repas et les sorties sont-ils compris dans la journée, faut-il prévoir un sac avec un change et une casquette, et faut-il prévenir la veille en cas d''absence ?',
   'Chaque condition est posée de façon concrète : plus rien ne restera à rappeler.'),
  -- EO2-C3-S6 / INSUFFICIENT
  ('EO2-C3-S6', 'INSUFFICIENT',
   'Bonjour monsieur. Est-ce que je dois porter quelque chose de particulier ?',
   'Une seule condition est demandée : la règle en cas de retard reste inconnue.'),
  -- EO2-C3-S6 / EXPECTED
  ('EO2-C3-S6', 'EXPECTED',
   'Bonjour monsieur. Avant de commencer : est-ce qu''il faut une tenue ou des chaussures particulières, et qui dois-je prévenir si je suis en retard ?',
   'Les deux conditions sont réclamées dans une seule prise de parole.'),
  -- EO2-C3-S6 / EXCELLENT
  ('EO2-C3-S6', 'EXCELLENT',
   'Bonjour monsieur. Pour bien démarrer : faut-il des chaussures de sécurité et une tenue fournie par le magasin, et en cas de retard ou d''absence, est-ce que je vous appelle directement ou je passe par l''accueil ?',
   'Chaque condition est posée avec son cas concret : rien ne restera à demander demain.'),
  -- EO2-C3-S9 / INSUFFICIENT
  ('EO2-C3-S9', 'INSUFFICIENT',
   'Bonjour madame. Je voudrais résilier mon abonnement internet, est-ce que c''est possible ?',
   'Aucune des trois conditions n''est réclamée : ni démarche, ni documents, ni frais.'),
  -- EO2-C3-S9 / EXPECTED
  ('EO2-C3-S9', 'EXPECTED',
   'Bonjour madame. Comment dois-je faire pour résilier, quels documents faut-il vous envoyer, et est-ce qu''il y a des frais à payer ?',
   'Les trois conditions sont demandées à la suite, dans un ordre facile à suivre.'),
  -- EO2-C3-S9 / EXCELLENT
  ('EO2-C3-S9', 'EXCELLENT',
   'Bonjour madame. Je fais le point sur mon abonnement : la résiliation se fait-elle par courrier ou depuis mon espace client, quelles pièces dois-je joindre à la demande, et reste-t-il des frais de résiliation ou un matériel à renvoyer ?',
   'Chaque question est resserrée : la conseillère ne peut répondre que par des conditions précises.'),
  -- EO2-C3-S13 / INSUFFICIENT
  ('EO2-C3-S13', 'INSUFFICIENT',
   'Bonjour monsieur. Comment fait-on pour avoir un jardin ici ?',
   'L''inscription est abordée, mais documents, matériel et règles restent inconnus.'),
  -- EO2-C3-S13 / EXPECTED
  ('EO2-C3-S13', 'EXPECTED',
   'Bonjour monsieur. Comment est-ce qu''on s''inscrit, quels documents faut-il fournir, qu''est-ce qui est mis à disposition sur place, et quelles règles faut-il respecter ?',
   'Les quatre conditions sont demandées sans que la prise de parole devienne confuse.'),
  -- EO2-C3-S13 / EXCELLENT
  ('EO2-C3-S13', 'EXCELLENT',
   'Bonjour monsieur. J''habite l''immeuble d''en face et j''aimerais cultiver quelques légumes. L''inscription se fait-elle auprès de vous ou à la mairie, quels justificatifs dois-je apporter, est-ce que l''eau et les outils sont fournis, et y a-t-il des règles sur les produits ou sur l''entretien de la parcelle ?',
   'Chaque condition est posée avec son cas concret : rien n''est laissé à deviner.'),
  -- EO2-C7-S1 / INSUFFICIENT
  ('EO2-C7-S1', 'INSUFFICIENT',
   'Je vais prendre l''abonnement à l''année, s''il vous plaît.',
   'L''échange s''arrête avant d''avoir exploré quoi que ce soit.'),
  -- EO2-C7-S1 / EXPECTED
  ('EO2-C7-S1', 'EXPECTED',
   'Si je compare les deux formules, l''une est plus chère mais sans engagement. Est-ce que l''abonnement à l''année peut être arrêté en cours de route, et les deux donnent-ils accès aux mêmes créneaux ?',
   'Les deux formules sont interrogées et deux différences nouvelles sont demandées.'),
  -- EO2-C7-S1 / EXCELLENT
  ('EO2-C7-S1', 'EXCELLENT',
   'Si je compare les deux formules, l''écart est de dix euros par mois. Est-ce que l''abonnement annuel peut être suspendu en cas de déménagement, est-ce qu''il inclut les cours collectifs, et y a-t-il des frais d''inscription dans un cas ou dans l''autre ?',
   'Trois questions différentes font sortir ce que l''annonce ne disait pas.'),
  -- EO2-C7-S2 / INSUFFICIENT
  ('EO2-C7-S2', 'INSUFFICIENT',
   'D''accord, je vais prendre le deuxième forfait, celui à dix-neuf euros.',
   'Le forfait est pris sans qu''aucune différence ait été explorée.'),
  -- EO2-C7-S2 / EXPECTED
  ('EO2-C7-S2', 'EXPECTED',
   'Entre les deux forfaits, est-ce qu''il y a un engagement dans un cas et pas dans l''autre ? Et les appels vers l''étranger comprennent-ils tous les pays ?',
   'Deux différences non annoncées sont réclamées : l''échange avance vraiment.'),
  -- EO2-C7-S2 / EXCELLENT
  ('EO2-C7-S2', 'EXCELLENT',
   'Entre les deux forfaits, est-ce que l''engagement est le même ? Les appels illimités comprennent-ils le Maroc, et que se passe-t-il si je dépasse les vingt gigaoctets du premier : le débit baisse, ou c''est facturé ?',
   'Chaque question porte sur un point que l''annonce laissait dans l''ombre.'),
  -- EO2-C7-S3 / INSUFFICIENT
  ('EO2-C7-S3', 'INSUFFICIENT',
   'Le train est plus rapide, donc je prends le train.',
   'Une seule donnée déjà connue est reprise : rien n''est exploré.'),
  -- EO2-C7-S3 / EXPECTED
  ('EO2-C7-S3', 'EXPECTED',
   'Entre le train et le bus, est-ce que le bus arrive au centre-ville ou en périphérie ? Et les bagages sont-ils inclus dans les deux cas ?',
   'Deux différences que l''annonce ne donnait pas sont obtenues.'),
  -- EO2-C7-S3 / EXCELLENT
  ('EO2-C7-S3', 'EXCELLENT',
   'Entre le train et le bus, où arrive exactement le bus, et combien de temps faut-il ensuite pour rejoindre le centre ? Les bagages sont-ils limités, et peut-on changer d''horaire dans l''un ou l''autre cas ?',
   'Trois différences sortent de l''échange, dont une que personne n''avait annoncée.'),
  -- EO2-C7-S4 / INSUFFICIENT
  ('EO2-C7-S4', 'INSUFFICIENT',
   'Je préfère la formule du samedi, c''est mieux pour moi.',
   'Une préférence est annoncée sans qu''aucune différence ait été explorée.'),
  -- EO2-C7-S4 / EXPECTED
  ('EO2-C7-S4', 'EXPECTED',
   'Avant de choisir, j''aimerais savoir si le contenu et le diplôme sont identiques dans les deux cas, et si les absences sont comptées de la même façon.',
   'Deux différences non annoncées sont réclamées : l''échange avance vraiment.'),
  -- EO2-C7-S4 / EXCELLENT
  ('EO2-C7-S4', 'EXCELLENT',
   'Avant de choisir, j''aimerais savoir si le contenu et le diplôme sont identiques, si les groupes ont la même taille, et ce qui se passe en cas d''absence dans chaque formule : peut-on rattraper une séance ?',
   'Trois différences sortent de l''échange, dont une conséquence concrète.'),
  -- EO2-C7-S5 / INSUFFICIENT
  ('EO2-C7-S5', 'INSUFFICIENT',
   'La formule de base est moins chère, alors je vais prendre celle-là.',
   'Le prix déjà annoncé suffit à décider : rien n''est exploré.'),
  -- EO2-C7-S5 / EXPECTED
  ('EO2-C7-S5', 'EXPECTED',
   'Entre ces deux contrats, est-ce que le vol et le dégât des eaux sont couverts dans les deux cas ? Et la franchise s''applique-t-elle à chaque sinistre ou une fois par an ?',
   'Deux différences que l''annonce ne donnait pas sont obtenues.'),
  -- EO2-C7-S5 / EXCELLENT
  ('EO2-C7-S5', 'EXCELLENT',
   'Entre ces deux contrats, le vol et le dégât des eaux sont-ils couverts dans les deux cas ? La franchise s''applique-t-elle à chaque sinistre ? Et le remplacement à neuf vaut-il pour tous les appareils, ou seulement ceux de moins de deux ans ?',
   'Chaque question resserre un point que le tarif affiché ne dit pas.'),
  -- EO2-C7-S6 / INSUFFICIENT
  ('EO2-C7-S6', 'INSUFFICIENT',
   'Je vais prendre la livraison express, s''il vous plaît.',
   'Le choix tombe sans qu''aucune différence ait été explorée.'),
  -- EO2-C7-S6 / EXPECTED
  ('EO2-C7-S6', 'EXPECTED',
   'Entre les deux livraisons, est-ce que les deux montent le canapé jusqu''à l''appartement ? Et peut-on choisir un créneau horaire dans les deux cas ?',
   'Deux différences non annoncées sont réclamées : l''échange avance vraiment.'),
  -- EO2-C7-S6 / EXCELLENT
  ('EO2-C7-S6', 'EXCELLENT',
   'Entre les deux livraisons, est-ce que les deux montent le canapé à l''étage, peut-on choisir un créneau, et l''emballage est-il repris dans un cas comme dans l''autre ?',
   'Trois questions font sortir ce que l''annonce passait sous silence.'),
  -- EO2-C7-S7 / INSUFFICIENT
  ('EO2-C7-S7', 'INSUFFICIENT',
   'Bon, alors remboursez-moi, ce sera plus simple pour tout le monde.',
   'Une solution est prise d''emblée, sans qu''aucune différence soit explorée.'),
  -- EO2-C7-S7 / EXPECTED
  ('EO2-C7-S7', 'EXPECTED',
   'Entre le remboursement et l''échange, est-ce que je dois renvoyer la lampe cassée dans les deux cas ? Et qui paie le retour ?',
   'Deux différences que l''annonce ne donnait pas sont obtenues.'),
  -- EO2-C7-S7 / EXCELLENT
  ('EO2-C7-S7', 'EXCELLENT',
   'Entre le remboursement et l''échange, faut-il renvoyer la lampe cassée dans les deux cas, qui paie le retour, et le délai de huit jours court-il à partir de mon appel ou à partir de la réception du colis ?',
   'Chaque question porte sur un point que l''annonce laissait imprécis.'),
  -- EO2-C7-S8 / INSUFFICIENT
  ('EO2-C7-S8', 'INSUFFICIENT',
   'D''accord, faites venir le technicien à la maison, s''il vous plaît.',
   'La solution est prise sans que l''autre ait été examinée.'),
  -- EO2-C7-S8 / EXPECTED
  ('EO2-C7-S8', 'EXPECTED',
   'À domicile ou à l''atelier, quel est le délai de réparation dans chaque cas ? Et la garantie sur la réparation est-elle la même ?',
   'Deux différences non annoncées sont réclamées : l''échange avance vraiment.'),
  -- EO2-C7-S8 / EXCELLENT
  ('EO2-C7-S8', 'EXCELLENT',
   'À domicile ou à l''atelier, quel est le délai dans chaque cas, la garantie sur la réparation est-elle identique, et le devis est-il gratuit si je renonce après diagnostic ?',
   'Trois questions font sortir ce qui n''était pas annoncé.'),
  -- EO2-C7-S9 / INSUFFICIENT
  ('EO2-C7-S9', 'INSUFFICIENT',
   'Je prends l''écran compatible, il est deux fois moins cher.',
   'Le prix déjà annoncé suffit à décider : rien n''est exploré.'),
  -- EO2-C7-S9 / EXPECTED
  ('EO2-C7-S9', 'EXPECTED',
   'Avant de choisir, est-ce que l''écran compatible a la même qualité d''image ? Et la garantie couvre-t-elle une nouvelle casse ou seulement une panne ?',
   'Deux différences que l''annonce ne donnait pas sont obtenues.'),
  -- EO2-C7-S9 / EXCELLENT
  ('EO2-C7-S9', 'EXCELLENT',
   'Avant de choisir, est-ce que l''écran compatible a la même qualité d''image et le même tactile ? La garantie couvre-t-elle une casse ou seulement une panne, et la pose est-elle comprise dans les deux prix ?',
   'Trois différences sortent de l''échange, dont le détail du prix.'),
  -- EO2-C7-S10 / INSUFFICIENT
  ('EO2-C7-S10', 'INSUFFICIENT',
   'Les moins chers me suffiront, mettez-moi ceux à deux cent vingt euros.',
   'Le prix décide seul : aucune différence n''est explorée.'),
  -- EO2-C7-S10 / EXPECTED
  ('EO2-C7-S10', 'EXPECTED',
   'Entre les deux jeux de pneus, combien de kilomètres tient chaque modèle ? Et le montage et l''équilibrage sont-ils compris dans les deux prix ?',
   'Deux différences non annoncées sont réclamées : l''échange avance vraiment.'),
  -- EO2-C7-S10 / EXCELLENT
  ('EO2-C7-S10', 'EXCELLENT',
   'Entre les deux jeux de pneus, combien de kilomètres tient chaque modèle, le montage est-il compris dans les deux prix, et y a-t-il une différence de bruit ou de consommation sur autoroute ?',
   'Trois questions font sortir ce que l''affichage ne dit jamais.'),
  -- EO2-C7-S11 / INSUFFICIENT
  ('EO2-C7-S11', 'INSUFFICIENT',
   'Je vais prendre la boîte automatique, ce sera plus facile pour moi.',
   'Aucune différence n''est explorée : la limite du permis n''est même pas évoquée.'),
  -- EO2-C7-S11 / EXPECTED
  ('EO2-C7-S11', 'EXPECTED',
   'Avant de m''inscrire, j''aimerais savoir si le prix de l''heure est le même dans les deux formules, et si l''on peut passer plus tard de l''automatique à la manuelle.',
   'Deux différences que l''annonce ne donnait pas sont obtenues.'),
  -- EO2-C7-S11 / EXCELLENT
  ('EO2-C7-S11', 'EXCELLENT',
   'Avant de m''inscrire, j''aimerais savoir si l''heure de conduite coûte pareil dans les deux formules, si l''on peut passer ensuite de l''automatique à la manuelle, et si le délai d''obtention de l''examen est le même.',
   'Trois différences sortent de l''échange, y compris le délai d''examen.'),
  -- EO2-C7-S12 / INSUFFICIENT
  ('EO2-C7-S12', 'INSUFFICIENT',
   'Je prends le billet à quarante-cinq euros, c''est moins cher.',
   'Le prix décide seul : aucune différence n''est explorée.'),
  -- EO2-C7-S12 / EXPECTED
  ('EO2-C7-S12', 'EXPECTED',
   'Entre ces deux billets, si j''échange celui à soixante-huit euros, est-ce que je paie la différence de prix ? Et la place est-elle réservée dans les deux cas ?',
   'Deux différences non annoncées sont réclamées : l''échange avance vraiment.'),
  -- EO2-C7-S12 / EXCELLENT
  ('EO2-C7-S12', 'EXCELLENT',
   'Entre ces deux billets, l''échange est-il gratuit ou faut-il payer la différence de tarif, la place est-elle réservée dans les deux cas, et le billet le moins cher donne-t-il droit à un bagage en plus ?',
   'Trois questions font sortir des conditions que le guichet n''annonce pas.'),
  -- EO2-C7-S13 / INSUFFICIENT
  ('EO2-C7-S13', 'INSUFFICIENT',
   'Je vais prendre le carnet de dix tickets, s''il vous plaît.',
   'Aucun des deux titres n''est interrogé : rien ne sort de l''échange.'),
  -- EO2-C7-S13 / EXPECTED
  ('EO2-C7-S13', 'EXPECTED',
   'Entre le carnet et l''abonnement, est-ce que l''abonnement donne aussi accès au tramway ? Et un ticket du carnet permet-il de changer de ligne pendant une heure ?',
   'Deux différences que l''annonce ne donnait pas sont obtenues.'),
  -- EO2-C7-S13 / EXCELLENT
  ('EO2-C7-S13', 'EXCELLENT',
   'Entre le carnet et l''abonnement, est-ce que l''abonnement couvre aussi le tramway, peut-on l''arrêter en cours d''année en cas de déménagement, et un ticket du carnet autorise-t-il la correspondance pendant une heure ?',
   'Trois questions font sortir le réseau, la souplesse et la règle de correspondance.'),
  -- EO2-C7-S14 / INSUFFICIENT
  ('EO2-C7-S14', 'INSUFFICIENT',
   'L''abonnement jeune est le moins cher, je vais prendre celui-là.',
   'Les deux autres possibilités ne sont ni interrogées ni comparées.'),
  -- EO2-C7-S14 / EXPECTED
  ('EO2-C7-S14', 'EXPECTED',
   'Avant de m''engager, j''aimerais comparer ces abonnements : comment le tarif selon les revenus est-il calculé, et l''abonnement annuel peut-il être résilié en cours d''année ?',
   'Deux différences non annoncées sont obtenues, sur deux possibilités distinctes.'),
  -- EO2-C7-S14 / EXCELLENT
  ('EO2-C7-S14', 'EXCELLENT',
   'Avant de m''engager, j''aimerais comparer ces trois abonnements : comment le tarif selon les revenus est-il calculé et quels justificatifs faut-il apporter, l''abonnement annuel peut-il être arrêté en cours d''année, et l''abonnement jeune s''arrête-t-il à la date d''anniversaire ou en fin d''année scolaire ?',
   'Chaque possibilité est interrogée sur un point que l''affichage ne dit pas.'),
  -- EO2-C7-S15 / INSUFFICIENT
  ('EO2-C7-S15', 'INSUFFICIENT',
   'Bon, je paie les soixante euros, je n''ai pas le choix.',
   'La seconde solution est écartée sans être examinée.'),
  -- EO2-C7-S15 / EXPECTED
  ('EO2-C7-S15', 'EXPECTED',
   'Entre le supplément et le colis, est-ce que le colis est suivi et assuré s''il se perd ? Et à quelle adresse est-il livré ?',
   'Deux différences que l''annonce ne donnait pas sont obtenues.'),
  -- EO2-C7-S15 / EXCELLENT
  ('EO2-C7-S15', 'EXCELLENT',
   'Entre le supplément et le colis, le colis est-il suivi et assuré en cas de perte, à quelle adresse est-il livré, et le supplément de soixante euros vaut-il pour le retour aussi ou seulement pour ce vol ?',
   'Trois questions font sortir le risque réel et la portée du supplément.'),
  -- EO3-C1-S1 / EXPECTED
  ('EO3-C1-S1', 'EXPECTED',
   'Moi, je préfère vivre en ville. C''est mon choix parce que tout est proche : le travail, les magasins, les transports. La campagne est agréable, mais je ne m''y vois pas au quotidien.',
   'La position est nommée sans ambiguïté et elle reste la même jusqu''au bout.'),
  -- EO3-C1-S2 / EXPECTED
  ('EO3-C1-S2', 'EXPECTED',
   'Je préfère cuisiner moi-même. Ça me prend du temps, c''est vrai, mais je sais ce que je mange et ça me revient moins cher à la fin du mois.',
   'La préférence est nommée sans détour, le reste vient l''appuyer.'),
  -- EO3-C1-S4 / EXPECTED
  ('EO3-C1-S4', 'EXPECTED',
   'Je suis pour cette interdiction. Pendant les cours et les récréations, les élèves ont besoin de se concentrer et de se parler entre eux, pas de regarder un écran.',
   'Le « je suis pour » ne laisse aucun doute : la position est nette.'),
  -- EO3-C1-S6 / EXPECTED
  ('EO3-C1-S6', 'EXPECTED',
   'Pour moi, la réponse est oui : il faut rester avec le nouveau toute la première journée. Le premier jour, on ne sait pas à qui demander, et une question sans réponse fait perdre une heure.',
   'La position est posée sans ambiguïté et elle est tenue ensuite.'),
  -- EO3-C1-S7 / EXPECTED
  ('EO3-C1-S7', 'EXPECTED',
   'Entre les deux, je choisirais d''aller lui parler. En deux minutes, il me dit oui ou non, et je peux réserver mes billets le soir même.',
   'L''option choisie est nommée sans détour.'),
  -- EO3-C1-S8 / EXPECTED
  ('EO3-C1-S8', 'EXPECTED',
   'Sur cette idée, je suis pour. Le matin, j''ai besoin de calme pour traiter mes dossiers, et là, je serais tranquille au moins une heure.',
   'La position est nommée sans détour : on la saisit sans effort.'),
  -- EO3-C1-S9 / EXPECTED
  ('EO3-C1-S9', 'EXPECTED',
   'Pour ces horaires d''été, je suis favorable. À six heures, on travaille au frais, et à quatorze heures on a fini, avant que le toit devienne dangereux.',
   'L''avis est annoncé sans ambiguïté et il ne change pas.'),
  -- EO3-C1-S10 / EXPECTED
  ('EO3-C1-S10', 'EXPECTED',
   'Sur les pourboires, ma position est simple : je suis pour le partage. Le client est content de son assiette autant que du service, donc l''argent doit aller aux deux.',
   'La position est nommée sans détour et reste la même jusqu''au bout.'),
  -- EO3-C1-S11 / EXPECTED
  ('EO3-C1-S11', 'EXPECTED',
   'Si on me demande, je préfère tourner. Huit heures à scanner les mêmes colis, mon épaule ne suit pas, alors que deux heures ici, deux heures là-bas, ça passe.',
   'La préférence est posée sans ambiguïté, le reste vient l''appuyer.'),
  -- EO3-C1-S12 / EXPECTED
  ('EO3-C1-S12', 'EXPECTED',
   'Entre ces deux formules, je prends la semaine. Une formation, c''est du travail, donc ça se fait pendant les heures de travail, prime ou pas prime.',
   'La formule choisie est nommée sans détour et tenue jusqu''au bout.'),
  -- EO3-C5-S1 / EXCELLENT
  ('EO3-C5-S1', 'EXCELLENT',
   'Autre chose, et ça n''a rien à voir avec le temps : la qualité. À plusieurs, chacun relit le travail de l''autre, et une erreur qui aurait coûté cher est repérée dès le début, pas à la livraison.',
   'La distinction avec l''idée précédente est annoncée puis tenue.'),
  -- EO3-C5-S2 / INSUFFICIENT
  ('EO3-C5-S2', 'INSUFFICIENT',
   'En plus, le vélo ne coûte presque rien : pas d''essence, pas d''assurance, pas de parking à payer. Financièrement, c''est vraiment la meilleure solution en ville.',
   'La nouvelle idée reprend le budget, terrain déjà couvert.'),
  -- EO3-C5-S2 / EXPECTED
  ('EO3-C5-S2', 'EXPECTED',
   'Autre chose : à vélo, on connaît son temps de trajet. Il n''y a pas d''embouteillage, donc on arrive à l''heure même quand la circulation est difficile.',
   'La fiabilité horaire est une idée neuve, clairement séparée.'),
  -- EO3-C5-S2 / EXCELLENT
  ('EO3-C5-S2', 'EXCELLENT',
   'Sur un tout autre plan, maintenant : la régularité. Un trajet à vélo dure vingt minutes le lundi comme le vendredi soir, alors qu''en voiture le même trajet peut doubler. On ne parle plus de budget là, on parle de fiabilité.',
   'Le changement de terrain est signalé : la réponse est très lisible.'),
  -- EO3-C5-S3 / EXPECTED
  ('EO3-C5-S3', 'EXPECTED',
   'Il y a aussi le groupe : pendant une sortie, des élèves qui ne se parlent jamais en classe passent la journée ensemble. Au retour, l''ambiance n''est plus la même.',
   'La vie du groupe est une idée bien distincte de la précédente.'),
  -- EO3-C5-S3 / EXCELLENT
  ('EO3-C5-S3', 'EXCELLENT',
   'Un autre aspect, qui n''a rien à voir avec l''envie d''apprendre : les relations. Dans le car et pendant le pique-nique, des élèves qui s''ignoraient se découvrent. Et cette journée-là continue de se sentir en classe pendant des semaines.',
   'L''idée est neuve, située, et son effet durable est précisé.'),
  -- EO3-C5-S4 / INSUFFICIENT
  ('EO3-C5-S4', 'INSUFFICIENT',
   'Et aussi, ça permet de détecter les problèmes rapidement, avant que ce soit grave. Plus on trouve tôt, mieux on soigne, c''est vraiment le plus important.',
   'Le dépistage revient : c''est l''idée précédente, rien de neuf.'),
  -- EO3-C5-S4 / EXCELLENT
  ('EO3-C5-S4', 'EXCELLENT',
   'Un autre intérêt, et il ne concerne pas la maladie : le conseil. En vingt minutes, le médecin regarde vos horaires, votre poste, votre sommeil, et il propose deux ou trois changements réalistes. C''est une consultation qui sert même quand tous les résultats sont normaux.',
   'L''idée tient debout seule, y compris si rien n''est détecté.'),
  -- EO3-C5-S5 / INSUFFICIENT
  ('EO3-C5-S5', 'INSUFFICIENT',
   'Et puis ça permet de parler avec sa famille, de voir les enfants, les parents, même très loin. C''est le grand avantage, on garde le contact avec ceux qu''on aime.',
   'L''idée du lien familial est simplement redéveloppée, pas remplacée.'),
  -- EO3-C5-S5 / EXCELLENT
  ('EO3-C5-S5', 'EXCELLENT',
   'Sur un terrain complètement différent, maintenant : l''organisation locale. Dans mon immeuble, le groupe de discussion règle en cinq minutes une panne d''ascenseur ou une clé perdue. Ça n''a plus rien à voir avec la famille, c''est du service entre voisins.',
   'Le changement de domaine est explicite et l''exemple le confirme.'),
  -- EO3-C5-S6 / INSUFFICIENT
  ('EO3-C5-S6', 'INSUFFICIENT',
   'Et puis un gardien, ça fait quand même un immeuble plus propre. Les couloirs sont nettoyés, les poubelles sont sorties, l''entrée est correcte. Franchement, la propreté, c''est vraiment ce qui compte le plus.',
   'C''est la propreté redite autrement : aucune idée nouvelle n''apparaît.'),
  -- EO3-C5-S6 / EXCELLENT
  ('EO3-C5-S6', 'EXCELLENT',
   'Autre chose, et ça n''a rien à voir avec le ménage : la présence. L''an dernier, une fuite dans le parking a été repérée le matin même, simplement parce que le gardien passe par là tous les jours. Sans lui, on l''aurait découverte avec la facture d''eau.',
   'Le changement de terrain est annoncé, puis tenu par un fait précis.'),
  -- EO3-C5-S7 / INSUFFICIENT
  ('EO3-C5-S7', 'INSUFFICIENT',
   'En plus, avec un local fermé à clé, il n''y aura plus de vélos volés. Aujourd''hui on attache tout dehors et ça disparaît en une nuit. Vraiment, la question du vol, c''est le vrai problème.',
   'Le vol est simplement redéveloppé : l''idée nouvelle manque.'),
  -- EO3-C5-S7 / EXCELLENT
  ('EO3-C5-S7', 'EXCELLENT',
   'Sur un autre point encore : les parties communes. Aujourd''hui, quatre vélos dorment dans le couloir du rez-de-chaussée, dont deux devant une porte de secours. Une cave aménagée, ce n''est pas seulement des vélos protégés, c''est un couloir qu''on peut de nouveau traverser.',
   'L''idée change de terrain et s''appuie sur un détail vérifiable.'),
  -- EO3-C5-S8 / INSUFFICIENT
  ('EO3-C5-S8', 'INSUFFICIENT',
   'Et puis ceux qui travaillent tard ne peuvent jamais venir. Avec un jour de plus, les gens qui ont des horaires difficiles pourraient enfin laver leur linge tranquillement, sans courir.',
   'Les horaires de travail reviennent : c''est l''idée précédente, rien de neuf.'),
  -- EO3-C5-S8 / EXCELLENT
  ('EO3-C5-S8', 'EXCELLENT',
   'Il y a un autre intérêt, qui ne concerne plus le travail : l''attente. Le samedi après-midi, il y a six machines pour une trentaine de clients, et on tourne dans la rue en surveillant les hublots. Ouvrir un jour de plus, ça ne crée pas de clients, ça les étale.',
   'L''idée est neuve, chiffrée, et la conclusion la rend évidente.'),
  -- EO3-C5-S9 / EXCELLENT
  ('EO3-C5-S9', 'EXCELLENT',
   'Ce n''est pas le seul point, et celui-ci n''a rien à voir avec les écrans : l''emploi. Dans ce magasin, la caisse est le premier travail de beaucoup de jeunes du quartier, et souvent le seul poste qui accepte un temps partiel. Remplacer six caisses, ce n''est pas moderniser, c''est supprimer six contrats.',
   'La nouvelle idée est située, autonome, et clairement séparée de la précédente.'),
  -- EO3-C5-S10 / EXPECTED
  ('EO3-C5-S10', 'EXPECTED',
   'Une autre idée, très différente : le marché fait travailler les commerces autour. Le samedi matin, le café de la place et la boulangerie voient passer la moitié de leurs clients de la semaine.',
   'L''activité économique de la place est un terrain neuf, bien séparé.'),
  -- EO3-C5-S10 / EXCELLENT
  ('EO3-C5-S10', 'EXCELLENT',
   'Une autre idée, très différente, qui ne parle plus de ce qu''on achète : l''activité de la place. Le samedi matin, le café fait le tiers de sa semaine et la boulangerie double sa file. Supprimer le marché, ce n''est pas enlever vingt étals, c''est vider une place et fragiliser deux commerces qui, eux, restent ouverts toute l''année.',
   'Le déplacement du terrain est explicite et l''exemple le confirme.'),
  -- EO3-C5-S11 / INSUFFICIENT
  ('EO3-C5-S11', 'INSUFFICIENT',
   'Et puis le pain est vraiment meilleur. La croûte, la mie, l''odeur du matin, ça n''a rien à voir avec le pain sous plastique. Pour moi, c''est vraiment ça qui compte.',
   'Le goût est décrit plus longuement, mais reste l''idée précédente.'),
  -- EO3-C5-S11 / EXPECTED
  ('EO3-C5-S11', 'EXPECTED',
   'Il y a un autre aspect : la distance. La boulangerie est à trois minutes à pied, donc je ne sors pas la voiture pour une baguette, et ma voisine de quatre-vingts ans y descend seule.',
   'La proximité est une idée neuve, sans lien avec la qualité du pain.'),
  -- EO3-C5-S11 / EXCELLENT
  ('EO3-C5-S11', 'EXCELLENT',
   'Il y a un autre aspect, qui n''a rien à voir avec le goût : le déplacement. Trois minutes à pied, contre vingt minutes de voiture et de parking pour aller en grande surface. Et ce détail compte surtout pour ceux qui ne conduisent plus : ma voisine de quatre-vingts ans y descend seule chaque matin, et c''est sa sortie de la journée.',
   'L''idée est neuve et son effet est montré sur une personne précise.'),
  -- EO3-C5-S12 / INSUFFICIENT
  ('EO3-C5-S12', 'INSUFFICIENT',
   'Et puis tu prends ce qu''il te faut, ni plus ni moins. En barquette, tu achètes six morceaux et tu en jettes deux à la fin de la semaine. À la boucherie, rien ne part à la poubelle.',
   'La quantité et le gaspillage reviennent : aucune idée nouvelle n''apparaît.'),
  -- EO3-C5-S12 / EXCELLENT
  ('EO3-C5-S12', 'EXCELLENT',
   'Autre chose, sur un plan différent, qui ne parle plus de quantité : le conseil. La dernière fois, je voulais du filet pour un plat mijoté ; le boucher m''a orientée vers un morceau à moitié prix qui tient bien mieux la cuisson. Une barquette ne te dira jamais ça, et c''est là qu''on gagne vraiment quelque chose.',
   'L''idée neuve est illustrée par une scène précise et se suffit à elle-même.'),
  -- EO3-C5-S13 / EXPECTED
  ('EO3-C5-S13', 'EXPECTED',
   'Sur un autre plan, maintenant : l''indépendance. Vous n''aurez plus besoin d''attendre que quelqu''un soit disponible le samedi pour vous emmener au magasin.',
   'L''autonomie est un domaine neuf, sans rapport avec le transport.'),
  -- EO3-C5-S13 / EXCELLENT
  ('EO3-C5-S13', 'EXCELLENT',
   'Sur un autre plan, et ça ne concerne plus les sacs : l''autonomie. Aujourd''hui, vous attendez que votre fils ait un samedi libre, donc vos courses dépendent de son agenda. Avec la livraison, c''est vous qui choisissez le jour, l''heure et les marques. Ce n''est plus une aide qu''on vous rend, c''est vous qui décidez de nouveau.',
   'Le domaine est nommé, tenu, et l''idée tient debout sans la précédente.'),
  -- EO3-C5-S14 / EXPECTED
  ('EO3-C5-S14', 'EXPECTED',
   'Il y a un autre angle : l''emballage. C''est le vendeur qui choisit le carton, le calage et le transporteur, donc c''est lui, et lui seul, qui peut réellement éviter la casse.',
   'La question de qui peut agir est un terrain distinct de la faute.'),
  -- EO3-C5-S14 / EXCELLENT
  ('EO3-C5-S14', 'EXCELLENT',
   'Il y a un autre angle, qui ne parle plus de faute : qui a les moyens d''agir. Le vendeur choisit le carton, le calage et le transporteur ; le client, lui, ne choisit rien du tout. Tant que la casse coûte au client, personne n''améliore l''emballage ; le jour où elle coûte au vendeur, il met du papier bulle. C''est une question d''efficacité, pas de justice.',
   'Le déplacement de terrain est annoncé, puis démontré jusqu''au bout.'),
  -- EO3-C5-S15 / EXPECTED
  ('EO3-C5-S15', 'EXPECTED',
   'Autre chose, complètement indépendant de ce que j''ai dit : le budget des familles. Racheter un lave-vaisselle à cinq cents euros parce qu''une pièce à trente euros n''existe plus, c''est une dépense qui ne se justifie pas.',
   'Le coût pour les ménages est un domaine neuf, sans lien avec les déchets.'),
  -- EO3-C5-S15 / EXCELLENT
  ('EO3-C5-S15', 'EXCELLENT',
   'Autre chose, complètement indépendant de ce que j''ai dit, et qui ne parle plus de la planète : le porte-monnaie. Une carte électronique coûte trente euros, une machine neuve en coûte cinq cents. Quand la pièce n''est plus fabriquée, la même panne est multipliée par quinze pour le client. Et ce sont les foyers les plus modestes qui paient cette différence, parce que ce sont eux qui gardent leurs appareils le plus longtemps.',
   'L''idée neuve est chiffrée et tient debout même sans la précédente.'),
  -- EO3-C8-S1 / INSUFFICIENT
  ('EO3-C8-S1', 'INSUFFICIENT',
   'Le club, c''est bien. Il y a un entraîneur, des horaires, des compétitions, des amis, du matériel. Seul, on est libre, on choisit son moment. Il y a aussi le prix, et puis les déplacements le week-end.',
   'Les idées s''accumulent sans lien : le propos ne tient pas.'),
  -- EO3-C8-S1 / EXPECTED
  ('EO3-C8-S1', 'EXPECTED',
   'Je préfère le club. D''abord parce que les horaires fixes m''obligent à y aller. Par exemple, mon cours de volley est le mardi à dix-neuf heures, donc je ne réfléchis plus. Au final, c''est le club qui me fait tenir toute l''année.',
   'Les idées s''enchaînent sans rupture et le propos tient jusqu''au bout.'),
  -- EO3-C8-S1 / EXCELLENT
  ('EO3-C8-S1', 'EXCELLENT',
   'Pour moi, c''est le club, sans hésitation. La raison principale, c''est que l''horaire est décidé à ma place, donc je ne peux plus me trouver d''excuse. Par exemple, mon volley du mardi à dix-neuf heures : même fatiguée, j''y vais parce que l''équipe m''attend. Au bout du compte, ce qui me fait tenir, ce n''est pas la motivation, c''est le rendez-vous.',
   'Chaque idée prépare la suivante : le propos avance sans jamais retomber.'),
  -- EO3-C8-S2 / INSUFFICIENT
  ('EO3-C8-S2', 'INSUFFICIENT',
   'Réparer, c''est bien pour la planète, ça coûte moins cher, ça crée du travail, et puis on garde ses affaires. Racheter, c''est rapide mais on jette beaucoup. Voilà, il y a plusieurs choses à dire là-dessus.',
   'Beaucoup d''idées, aucune reliée : le propos se disperse.'),
  -- EO3-C8-S2 / EXPECTED
  ('EO3-C8-S2', 'EXPECTED',
   'Je pense qu''il faut réparer. La raison, c''est qu''un appareil réparé dure encore des années. Par exemple, ma machine à laver a été réparée pour quatre-vingts euros au lieu de quatre cents. Donc oui, l''atelier du quartier a tout son sens.',
   'L''enchaînement est net et le propos ne retombe à aucun moment.'),
  -- EO3-C8-S2 / EXCELLENT
  ('EO3-C8-S2', 'EXCELLENT',
   'Je suis clairement pour la réparation. Ce qui me convainc, c''est que la panne concerne souvent une seule pièce, pas tout l''appareil. Par exemple, ma machine à laver s''est arrêtée l''hiver dernier : une pompe changée, quatre-vingts euros, contre quatre cents pour une neuve. Au final, un atelier de quartier ne fait pas qu''économiser de l''argent, il évite de jeter une machine qui marche encore.',
   'Chaque idée sert la précédente : le propos avance sans changer de sujet.'),
  -- EO3-C8-S3 / INSUFFICIENT
  ('EO3-C8-S3', 'INSUFFICIENT',
   'Vivre en France, on entend le français partout, à la boulangerie, au travail, à la télévision. Les cours aussi c''est utile, la grammaire, l''écrit, les professeurs. Les deux ensemble, c''est mieux, je crois.',
   'Le propos s''interrompt : aucune idée n''est reprise ni développée.'),
  -- EO3-C8-S3 / EXPECTED
  ('EO3-C8-S3', 'EXPECTED',
   'Je pense que vivre ici ne suffit pas. Parce que dans la vie courante, on répète toujours les mêmes phrases. Par exemple, j''ai passé deux ans à comprendre mes collègues sans jamais savoir écrire un mail correct. Donc pour moi, les cours restent nécessaires.',
   'Les idées s''enchaînent sans rupture et le propos reste nourri.'),
  -- EO3-C8-S3 / EXCELLENT
  ('EO3-C8-S3', 'EXCELLENT',
   'Ma réponse est non, vivre ici ne suffit pas. La raison, c''est que le quotidien fait tourner un vocabulaire très limité : les courses, le travail, les horaires. Par exemple, pendant deux ans j''ai compris tous mes collègues, mais devant un courriel à écrire à l''administration, j''étais bloquée. Donc l''immersion donne l''oreille et le cours donne le reste : il faut les deux, pas l''un à la place de l''autre.',
   'Chaque reprise relance le propos au lieu de le répéter.'),
  -- EO3-C8-S4 / INSUFFICIENT
  ('EO3-C8-S4', 'INSUFFICIENT',
   'Apporter son repas, c''est moins cher et plus sain. Acheter dehors, c''est plus rapide, on sort un peu, on change d''air. Après ça dépend des gens, des horaires, du quartier, de ce qu''on aime manger.',
   'La réponse énumère puis se dilue : le propos ne tient pas.'),
  -- EO3-C8-S4 / EXCELLENT
  ('EO3-C8-S4', 'EXCELLENT',
   'Mon conseil, c''est d''apporter son repas. La raison principale, c''est le contrôle : sur le contenu de l''assiette comme sur le budget. Par exemple, je cuisine le dimanche pour trois midis, ce qui me revient à moins de trois euros par jour, contre dix à la boulangerie d''en bas. Au final, ce n''est pas seulement une question d''argent : c''est une pause de midi où je ne cours pas.',
   'Le propos avance sans rupture et reste sur le sujet du début à la fin.'),
  -- EO3-C8-S5 / INSUFFICIENT
  ('EO3-C8-S5', 'INSUFFICIENT',
   'Le tourisme amène de l''argent, des emplois, des restaurants. Mais les loyers montent, il y a du bruit, les commerces changent. Les habitants sont partagés, il y a du positif et du négatif, c''est compliqué à dire.',
   'Deux listes se répondent : les idées s''empilent sans être organisées.'),
  -- EO3-C8-S5 / EXPECTED
  ('EO3-C8-S5', 'EXPECTED',
   'Je pense que c''est plutôt une bonne chose, à condition d''encadrer. La raison, c''est que le tourisme fait vivre beaucoup de familles. Par exemple, dans la ville où j''habitais, la moitié des commerces du centre fermait en hiver sans les visiteurs. Donc oui, mais avec des règles sur les locations.',
   'Les idées sont liées et hiérarchisées : le propos reste organisé.'),
  -- EO3-C8-S5 / EXCELLENT
  ('EO3-C8-S5', 'EXCELLENT',
   'Ma réponse est oui, mais un oui encadré. Ce qui me convainc, c''est que le tourisme maintient une activité toute l''année dans des villes moyennes qui, sinon, se videraient. Par exemple, dans la ville où j''ai vécu, la moitié des commerces du centre baissait le rideau en hiver dès que les visiteurs partaient. Donc le vrai sujet n''est pas d''en avoir moins, c''est de décider ce qu''on en fait, en commençant par le logement.',
   'Le propos progresse sans jamais se transformer en énumération.'),
  -- EO3-C8-S6 / INSUFFICIENT
  ('EO3-C8-S6', 'INSUFFICIENT',
   'La visite guidée, il y a un guide qui explique, on apprend des choses, on ne rate rien. Tout seul, on va à son rythme, on reste devant ce qu''on aime. Après il y a le prix, et le nombre de gens dans le groupe aussi.',
   'Les idées s''accumulent sans lien : le propos ne tient pas.'),
  -- EO3-C8-S6 / EXPECTED
  ('EO3-C8-S6', 'EXPECTED',
   'Je préfère la visite guidée. D''abord parce que sans explication, je regarde les tableaux sans rien comprendre. Par exemple, au musée de ma ville, le guide a raconté qui avait commandé le tableau, et tout est devenu clair. Au final, une heure guidée m''apporte plus que trois heures seul.',
   'Les idées s''enchaînent sans rupture et le propos tient jusqu''au bout.'),
  -- EO3-C8-S6 / EXCELLENT
  ('EO3-C8-S6', 'EXCELLENT',
   'Entre les deux, je choisirais la visite guidée, au moins la première fois. La raison, c''est qu''une exposition ne se comprend pas toute seule : sans contexte, je vois de belles images et je passe. Par exemple, l''an dernier, un guide a expliqué en trois phrases pourquoi ce peintre avait tout repeint en noir, et je suis resté vingt minutes devant la toile. Au bout du compte, la visite guidée ne remplace pas la visite libre : elle apprend à regarder, et c''est après qu''on peut y retourner seul.',
   'Chaque idée prépare la suivante : le propos avance sans jamais retomber.'),
  -- EO3-C8-S7 / INSUFFICIENT
  ('EO3-C8-S7', 'INSUFFICIENT',
   'Un festival, ça anime la ville, ça fait venir du monde, les commerçants sont contents, les jeunes sortent. Mais ça coûte cher, il y a du bruit, et certains disent que l''argent irait mieux ailleurs. Voilà, il y a du pour et du contre.',
   'Deux listes se répondent : rien ne relie les idées entre elles.'),
  -- EO3-C8-S7 / EXPECTED
  ('EO3-C8-S7', 'EXPECTED',
   'Je trouve que c''est un bon usage de l''argent public. D''abord parce que c''est souvent le seul concert gratuit de l''année pour beaucoup de familles. Par exemple, mes voisins ne mettent jamais les pieds dans une salle payante, et ils y étaient les trois soirs. Donc oui, je suis pour.',
   'Les idées s''enchaînent sans rupture et le propos tient jusqu''au bout.'),
  -- EO3-C8-S7 / EXCELLENT
  ('EO3-C8-S7', 'EXCELLENT',
   'Sur ce financement, mon avis est favorable, mais pour une raison précise. Ce qui compte, ce n''est pas l''animation : c''est que l''entrée soit libre, parce qu''une place de concert à quarante euros écarte d''avance une partie des habitants. Par exemple, mes voisins, qui n''ont jamais mis les pieds dans une salle payante, y sont allés trois soirs de suite avec leurs enfants. Au final, un festival gratuit ne se juge pas au nombre de spectateurs, mais à ceux qui ne seraient jamais venus autrement.',
   'Le propos se déplace d''une idée à l''autre sans jamais se répéter.'),
  -- EO3-C8-S8 / INSUFFICIENT
  ('EO3-C8-S8', 'INSUFFICIENT',
   'En France, le service est compris, donc ce n''est pas obligatoire. Mais beaucoup laissent quelque chose quand même, surtout au restaurant, moins au café. Ça dépend de la ville, du montant, de comment ça s''est passé. Voilà, c''est assez variable en fait.',
   'La réponse se dilue en conditions : le propos ne tient plus.'),
  -- EO3-C8-S8 / EXPECTED
  ('EO3-C8-S8', 'EXPECTED',
   'Ma réponse, c''est que ce n''est pas obligatoire. La raison, c''est que le service est déjà inclus dans le prix affiché, contrairement à d''autres pays. Par exemple, quand je déjeune seule à douze euros, je ne laisse rien et personne ne le remarque. Donc laisse quelque chose seulement si tu as envie de le faire.',
   'L''enchaînement est net et le propos ne retombe à aucun moment.'),
  -- EO3-C8-S8 / EXCELLENT
  ('EO3-C8-S8', 'EXCELLENT',
   'Ma réponse tient en une phrase : ce n''est pas obligatoire, mais c''est toujours bien reçu. La raison, c''est que le service est compris dans le prix affiché, donc personne n''attend un pourcentage comme dans d''autres pays. Par exemple, la semaine dernière, nous avons laissé deux euros après un long déjeuner où la serveuse nous avait laissé la table deux heures ; pour un café pris debout, nous n''aurions rien laissé. Donc la vraie règle n''est pas un montant : c''est de récompenser un service, pas de compléter un salaire.',
   'L''exemple relance le propos au lieu de le clore trop tôt.'),
  -- EO3-C8-S9 / INSUFFICIENT
  ('EO3-C8-S9', 'INSUFFICIENT',
   'Un café, c''est important dans un village, les gens se retrouvent, les anciens discutent. Mais une mairie n''est pas là pour tenir un commerce, ça coûte de l''argent, il faut quelqu''un pour le gérer, et si ça ne marche pas… Enfin, c''est délicat comme sujet.',
   'Les idées s''empilent : le fil du propos se perd.'),
  -- EO3-C8-S9 / EXPECTED
  ('EO3-C8-S9', 'EXPECTED',
   'Je pense que la mairie devrait racheter les murs. La raison, c''est que sans café, il n''y a plus aucun endroit où se croiser dans le village. Par exemple, au village voisin, la fermeture du bar a fait partir le dépôt de pain dans la même année. Donc oui, je suis pour, avec un gérant qui loue le local.',
   'Le fil est tenu jusqu''au bout, sans retour en arrière.'),
  -- EO3-C8-S9 / EXCELLENT
  ('EO3-C8-S9', 'EXCELLENT',
   'Si la mairie me demandait mon avis, je dirais oui, à une condition. Ce qui me convainc, c''est qu''un café n''est pas seulement un commerce : c''est souvent le dernier endroit où l''on croise quelqu''un quand on vit seul. Par exemple, au village d''à côté, quand le bar a fermé, le dépôt de pain et le point relais ont disparu dans l''année, parce qu''ils vivaient du même passage. Donc la commune n''achète pas un commerce, elle achète un lieu de passage — et elle doit en confier la gestion à quelqu''un dont c''est le métier.',
   'Chaque reprise fait avancer le propos au lieu de le répéter.'),
  -- EO3-C8-S10 / INSUFFICIENT
  ('EO3-C8-S10', 'INSUFFICIENT',
   'Le traiteur, c''est plus cher mais on ne fait rien. Cuisiner soi-même, c''est économique, c''est souvent meilleur, mais il faut du temps, de la place, des plats, et quelqu''un pour servir. Après, ça dépend du budget et du nombre de personnes.',
   'La parole retombe : le propos s''arrête avant d''avoir tenu.'),
  -- EO3-C8-S10 / EXPECTED
  ('EO3-C8-S10', 'EXPECTED',
   'Pour cinquante personnes, je conseillerais le traiteur. D''abord parce qu''on ne peut pas recevoir et cuisiner en même temps. Par exemple, pour le mariage de ma sœur, quinze euros par personne ont réglé tout le repas. Donc c''est vraiment ce que je recommanderais à ce collègue.',
   'Le propos est nourri et l''exemple chiffré le relance sans rupture.'),
  -- EO3-C8-S10 / EXCELLENT
  ('EO3-C8-S10', 'EXCELLENT',
   'Pour cinquante personnes, je conseillerais clairement le traiteur. La raison principale, c''est qu''à ce nombre-là, celui qui cuisine ne voit pas sa propre fête : il reste en cuisine du début à la fin. Par exemple, pour les quatre-vingts ans de mon grand-père, nous avons payé quinze euros par personne, soit sept cent cinquante euros, contre trois jours de préparation à quatre. Au final, la question n''est pas le prix du plat : c''est de savoir s''il veut être invité à sa propre soirée.',
   'Le propos se relance à chaque idée, sans jamais se répéter.'),
  -- EO3-C8-S11 / INSUFFICIENT
  ('EO3-C8-S11', 'INSUFFICIENT',
   'Le tarif non remboursable est moins cher, c''est sûr. L''autre coûte plus, mais on peut annuler. Ça dépend si on est sûr de partir, si c''est pour le travail, s''il y a des enfants. Il y a aussi les assurances, et les conditions qui changent selon les hôtels.',
   'La réponse énumère des cas possibles sans jamais les relier.'),
  -- EO3-C8-S11 / EXPECTED
  ('EO3-C8-S11', 'EXPECTED',
   'À choisir, je prendrais le tarif annulable. La raison, c''est que trente euros de plus coûtent moins cher qu''une nuit perdue. Par exemple, l''hiver dernier, mon fils est tombé malade la veille et j''ai tout annulé sans rien payer. Donc pour un voyage en famille, je paie la souplesse.',
   'Les idées s''enchaînent proprement et le propos reste nourri.'),
  -- EO3-C8-S11 / EXCELLENT
  ('EO3-C8-S11', 'EXCELLENT',
   'À choisir, je prendrais plutôt le tarif annulable, sauf cas très particulier. Ce qui me décide, c''est le rapport entre les deux sommes : payer trente euros pour protéger deux cents euros, ce n''est pas une dépense, c''est un calcul. Par exemple, l''hiver dernier, mon fils a eu de la fièvre la veille du départ ; j''ai annulé à vingt-deux heures sans perdre un centime. Donc ma règle est simple : plus la réservation est lointaine et plus la famille est nombreuse, plus le tarif annulable devient le moins cher des deux.',
   'Le cas particulier devient une règle : le propos gagne en hauteur sans rupture.'),
  -- EO3-C8-S12 / INSUFFICIENT
  ('EO3-C8-S12', 'INSUFFICIENT',
   'Le camping, ce n''est pas cher, les enfants jouent dehors, il y a une piscine, on rencontre du monde. Le gîte, c''est calme, il y a une vraie cuisine, des chambres, on dort mieux. Après il y a la météo, la distance, le budget, l''âge des enfants.',
   'Deux listes se suivent, sans aucun lien entre elles.'),
  -- EO3-C8-S12 / EXPECTED
  ('EO3-C8-S12', 'EXPECTED',
   'Avec des enfants, je pencherais pour le camping. La raison, c''est qu''ils y trouvent d''autres enfants tout de suite, sans que les parents organisent quoi que ce soit. Par exemple, l''été dernier, ma fille a passé la semaine avec trois copines rencontrées le premier soir. Donc pour une famille, le camping me paraît plus reposant.',
   'Les idées sont reliées et le propos reste nourri jusqu''au bout.'),
  -- EO3-C8-S12 / EXCELLENT
  ('EO3-C8-S12', 'EXCELLENT',
   'Avec des enfants, je pencherais pour le camping, et pas du tout pour le prix. La raison, c''est l''autonomie : dans un camping, les enfants sortent seuls dès le premier soir et les parents récupèrent enfin du temps. Par exemple, l''été dernier, ma fille de neuf ans a passé la semaine avec trois copines du terrain d''à côté, et nous avons lu deux livres chacun. Au final, le vrai critère n''est pas le confort du logement : c''est le nombre d''heures où l''on n''a pas à occuper ses enfants.',
   'Le critère décisif émerge du propos lui-même, sans rupture.'),
  -- EO3-C8-S13 / INSUFFICIENT
  ('EO3-C8-S13', 'INSUFFICIENT',
   'L''office de tourisme, il y a des plans, des brochures, des gens qui connaissent la ville. Le téléphone aussi, on a tout, les avis, les horaires, les photos. Les deux marchent, ça dépend des gens et du temps qu''on a devant soi.',
   'Les idées sont posées côte à côte, sans hiérarchie ni lien.'),
  -- EO3-C8-S13 / EXPECTED
  ('EO3-C8-S13', 'EXPECTED',
   'Dans une ville inconnue, je commencerais par l''office de tourisme. La raison, c''est qu''on y apprend en dix minutes ce qui est fermé, ce qui vaut le détour et ce qui est un piège à touristes. Par exemple, à Lyon, on m''a évité une visite en travaux que l''application annonçait ouverte. Donc ces dix minutes font gagner une journée.',
   'Les idées sont liées et hiérarchisées : le propos reste organisé.'),
  -- EO3-C8-S13 / EXCELLENT
  ('EO3-C8-S13', 'EXCELLENT',
   'Dans une ville inconnue, personnellement, je commence toujours par l''office de tourisme. Ce qui me convainc, c''est qu''une application montre ce qui est populaire, alors qu''une personne vous dit ce qui est fermé, ce qui vient d''ouvrir et ce qu''il ne faut surtout pas tenter un lundi. Par exemple, à Lyon, la dame de l''accueil m''a fait rayer une visite que mon téléphone annonçait ouverte et qui était en travaux depuis trois mois. Au bout du compte, la question n''est pas papier contre téléphone : c''est d''avoir quelqu''un qui répond à votre question à vous, celle qu''aucun moteur de recherche n''a prévue.',
   'Le propos monte d''un cran à chaque idée, sans jamais s''empiler.'),
  -- EO3-C8-S14 / INSUFFICIENT
  ('EO3-C8-S14', 'INSUFFICIENT',
   'Quarante euros, ce n''est pas rien. Après, si on annule, on est remboursé. Mais souvent l''assurance ne couvre pas tout, il faut un certificat, il y a des conditions partout. Il y a aussi la carte bancaire qui assure parfois. Bref, il faudrait lire.',
   'Les cas s''empilent : aucune idée n''est développée ni reliée.'),
  -- EO3-C8-S14 / EXPECTED
  ('EO3-C8-S14', 'EXPECTED',
   'Pour quarante euros, je dirais oui dans ce cas précis. La raison, c''est qu''on réserve six mois à l''avance et que beaucoup de choses peuvent changer en six mois. Par exemple, une collègue a perdu huit cents euros l''an dernier à cause d''une opération. Donc à ce prix-là, je la prendrais sans hésiter.',
   'Une idée développée et reliée suffit : le propos tient debout.'),
  -- EO3-C8-S14 / EXCELLENT
  ('EO3-C8-S14', 'EXCELLENT',
   'Pour quarante euros, je dirais oui, mais après une vérification. Ce qui décide, c''est la distance entre aujourd''hui et le départ : sur six mois, la probabilité qu''un imprévu tombe n''a rien à voir avec celle d''un départ dans trois semaines. Par exemple, une collègue a perdu huit cents euros l''an dernier parce qu''elle a été opérée quinze jours avant son vol. Donc je paie ces quarante euros, à une condition : vérifier d''abord que ma carte bancaire ne couvre pas déjà la même chose, sinon je paie deux fois pour un seul risque.',
   'Le propos avance d''un cran à la fois, sans jamais revenir en arrière.'),
  -- EO3-C8-S15 / EXPECTED
  ('EO3-C8-S15', 'EXPECTED',
   'En entretien, je dirais toujours que je ne sais pas. La raison, c''est qu''un recruteur pose souvent cette question exprès, pour voir la réaction. Par exemple, on m''a demandé un logiciel que je n''avais jamais utilisé ; j''ai dit non, puis j''ai expliqué comment j''avais appris le précédent. Donc l''honnêteté vaut mieux que l''invention.',
   'Le fil est tenu d''un bout à l''autre, sans répétition.'),
  -- EO3-C8-S15 / EXCELLENT
  ('EO3-C8-S15', 'EXCELLENT',
   'En entretien, je choisirais toujours de le dire, mais jamais en m''arrêtant là. La raison, c''est qu''un recruteur teste rarement une connaissance : il regarde comment vous réagissez en difficulté, parce que c''est exactement ce qui arrivera au bureau. Par exemple, on m''a demandé un logiciel de comptabilité que je n''avais jamais ouvert ; j''ai répondu que je ne le connaissais pas, puis j''ai raconté comment j''avais appris le précédent en trois semaines. Au bout du compte, ce n''est pas « je ne sais pas » qui coûte le poste : c''est de le dire sans montrer ce qu''on sait faire à la place.',
   'Chaque phrase apporte quelque chose : le propos ne piétine jamais.')
) AS v(prompt_code, level, text, note), skill_prompts p
WHERE r.skill_prompt_id = p.id AND p.code = v.prompt_code AND r.level = v.level;

-- --------------------------------------------------------------------------
-- 3. Les 19 lots neufs
--
-- Pour chaque competence : les anciens sujets sortent du catalogue (jamais
-- de la base), puis 15 sujets neufs prennent les rangs 1..15.
-- --------------------------------------------------------------------------

-- 3a. Les sujets des 7 competences RETIREES par V319.
--
-- V319 a desactive les competences, pas leurs sujets : ceux-ci restaient
-- actifs sous une competence qui ne s'affiche plus. Inatteignables, mais
-- comptes comme publies par tout controle qui interroge skill_prompts seul.
-- Ils sortent ici, sans changer de rang : leur competence ne reviendra pas.
UPDATE skill_prompts p
   SET is_active = false, updated_at = '2026-09-13 09:00:00+02'
  FROM skills s
 WHERE s.id = p.skill_id AND NOT s.is_active AND p.is_active;

-- 3b. Les anciens sujets des competences a lot neuf : desactives et ranges
--     au-dela de 15, pour que les sujets neufs prennent 1..15.
-- EE1-C2 — EE1-C2 — Annoncer clairement l'objet du message (15 sujets désactivés)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = 'b8299921-bb1c-5ba0-a43f-16726ec134a5' AND display_order <= 15;
-- EE1-C1 — EE1-C1 — Adapter le message au destinataire (14 sujets désactivés, S13 repris)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e' AND display_order <= 15;
-- EE1-C9 : competence creee par V319, aucun ancien sujet.
-- EE1-C10 : competence creee par V319, aucun ancien sujet.
-- EE1-C7 — EE1-C7 — Décrire simplement une personne, un lieu ou une situation (15 sujets désactivés ; S2 et S8 repris dans leur idée)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034' AND display_order <= 15;
-- EE1-C11 : competence creee par V319, aucun ancien sujet.
-- EE1-C3 — EE1-C3 — Donner des informations pratiques précises (15 sujets désactivés)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = 'd711bcba-beb2-584a-a090-14a2f4d92efb' AND display_order <= 15;
-- EE1-C8 — EE1-C8 — Relier les informations dans un message complet (15 sujets désactivés)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = 'f7c4bb25-2de0-5531-bda2-c1b865c13b25' AND display_order <= 15;
-- EE2-C9 : competence creee par V319, aucun ancien sujet.
-- EE3-C1 — EE3-C1 — Exprimer une position claire (15 sujets désactivés : débats de société et demandes transactionnelles)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = '78182a36-43b8-5257-b8f2-4730bb504d93' AND display_order <= 15;
-- EE3-C2 — EE3-C2 — Donner un argument pertinent (15 sujets désactivés : opinions sur des mesures et des pratiques)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = '2930c13d-ce25-54af-b0c6-e602f326fa16' AND display_order <= 15;
-- EE3-C3 — EE3-C3 — Développer un argument (15 sujets désactivés)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = '50bbf456-9de7-5620-aa31-5cba27bfac70' AND display_order <= 15;
-- EE3-C4 — EE3-C4 — Illustrer avec un exemple concret (15 sujets désactivés, y compris « Le café où l'on se retrouve », dont la situation est reprise)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = '4e7ce6cc-403f-5f70-98bb-393cc625e608' AND display_order <= 15;
-- EE3-C5 — EE3-C5 — Ajouter un deuxième argument distinct (15 sujets désactivés : demandes argumentées en milieu professionnel, bâties sur un quota de deux arguments)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = '8dfda25f-5808-5e9f-ba3e-bb3970ddf134' AND display_order <= 15;
-- EE3-C9 : competence creee par V319, aucun ancien sujet.
-- EE3-C7 — EE3-C7 — Nuancer ou concéder (15 sujets désactivés : opinions sur des services et des dispositifs)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = '16b70979-21b7-53f8-91a7-70a20bd385ec' AND display_order <= 15;
-- EE3-C8 — EE3-C8 — Organiser et conclure une réponse argumentée (15 sujets désactivés)
UPDATE skill_prompts
   SET is_active = false, display_order = display_order + 15,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE skill_id = '8c9134c2-ccba-59f4-903f-40067a3737ee' AND display_order <= 15;
-- EO2-C9 : competence creee par V319, aucun ancien sujet.
-- EO3-C9 : competence creee par V319, aucun ancien sujet.

-- 3c. Les sujets neufs.
INSERT INTO skill_prompts (id, skill_id, section, code, title, context, instruction,
                           unique_criterion, recommended_min_words, recommended_max_words,
                           recommended_duration_seconds, difficulty_level, display_order,
                           checklist, constraint_tags, answer_starter, tip,
                           is_active, created_at, updated_at)
VALUES
  -- EE1-C2-S16 — EASY — Quelqu'un a sonné chez la voisine
  ('5c3812b3-7b41-57ff-9359-e09a75487425', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S16', 'Quelqu''un a sonné chez la voisine',
   'Votre voisine vous écrit : « Bonjour, une personne a sonné chez moi ce matin en disant venir de votre part. Je n''ai pas ouvert. Elle était comment ? »',
   'Répondez-lui en décrivant la personne que vous aviez envoyée.',
   'Votre réponse décrit la personne, et rien d''autre : elle ne raconte pas pourquoi vous l''aviez envoyée.',
   30, 60, NULL, 'EASY', 1,
   '["Relisez sa question", "Décrivez la personne", "Ne parlez que d''elle"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Bonjour, oui, c''était…', 'elle veut savoir à quoi elle ressemblait, pas ce qu''elle venait faire',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S17 — EASY — Un colis retrouvé dans le hall
  ('879929d0-7cd9-5f38-99b8-0dc4c8bd9320', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S17', 'Un colis retrouvé dans le hall',
   'Le gardien affiche un mot : « Un colis a été déposé dans le hall sans étiquette lisible. Si vous attendez une livraison, décrivez-moi votre colis : je vérifierai si c''est le vôtre. »',
   'Écrivez-lui une réponse qui décrit le colis que vous attendez.',
   'Votre réponse décrit le colis attendu ; elle ne réclame rien et ne raconte pas la commande.',
   30, 60, NULL, 'EASY', 2,
   '["Lisez ce qu''il demande", "Décrivez votre colis", "Ne réclamez rien"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Bonjour, j''attends en effet un colis…', 'il veut le reconnaître : forme, taille, couleur, étiquette',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S18 — MEDIUM — Quelle salle pour la réunion ?
  ('a7766ef3-764b-5d56-878a-b22b2f670cc3', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S18', 'Quelle salle pour la réunion ?',
   'Une collègue vous écrit : « Je n''ai jamais mis les pieds dans la salle Mistral où se tient la réunion de jeudi. Elle est comment ? Je voudrais savoir si mon matériel va tenir. »',
   'Répondez-lui en décrivant la salle Mistral.',
   'Votre réponse décrit la salle ; elle ne rappelle ni l''horaire ni l''ordre du jour de la réunion.',
   30, 60, NULL, 'MEDIUM', 3,
   '["Repérez sa question", "Décrivez la salle", "Laissez l''horaire de côté"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'La salle Mistral est…', 'elle pense à son matériel : taille, tables, prises, lumière',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S19 — MEDIUM — Le groupe du cours de français
  ('c9048d4e-7f30-5796-84e5-3a67f4ce2c31', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S19', 'Le groupe du cours de français',
   'Un ami hésite à s''inscrire à votre cours de français. Il vous écrit : « Tu es avec quel genre de personnes ? J''ai peur d''être le seul débutant. »',
   'Répondez-lui en décrivant le groupe avec qui vous suivez le cours.',
   'Votre réponse décrit le groupe — qui le compose, quelle ambiance — sans parler du programme ni des horaires.',
   30, 60, NULL, 'MEDIUM', 4,
   '["Voyez ce qui l''inquiète", "Décrivez le groupe", "Laissez le programme"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Nous sommes un petit groupe…', 'il a peur d''être seul de son niveau : dites qui est là',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S20 — EASY — Le vélo à vendre
  ('ed377ab0-6726-57b6-adce-1c70e7514ecb', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S20', 'Le vélo à vendre',
   'Quelqu''un répond à votre annonce : « Bonjour, votre vélo m''intéresse. Vous pouvez me le décrire un peu mieux ? La photo est floue. »',
   'Répondez-lui en décrivant le vélo que vous vendez.',
   'Votre réponse décrit le vélo ; elle ne négocie pas le prix et ne fixe pas de rendez-vous.',
   30, 60, NULL, 'EASY', 5,
   '["Notez ce qu''il demande", "Décrivez le vélo", "Ne parlez pas du prix"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Bonjour, bien sûr. C''est un vélo…', 'la photo est floue : dites ce qu''elle ne montre pas',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S21 — MEDIUM — La nouvelle collègue
  ('4145a3b7-be71-547d-b83f-1501ac99505b', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S21', 'La nouvelle collègue',
   'Votre responsable vous écrit : « La personne qui remplace Sonia arrive lundi et c''est vous qui l''accueillez. Pouvez-vous me dire comment vous la reconnaîtrez ? Elle m''a envoyé quelques indications. »',
   'Répondez en décrivant la personne que vous devez accueillir, d''après ce qu''elle a indiqué.',
   'Votre réponse décrit la personne à reconnaître ; elle ne décrit pas le poste ni la journée d''accueil.',
   30, 60, NULL, 'MEDIUM', 6,
   '["Lisez la demande", "Décrivez la personne", "Laissez le poste de côté"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Je la reconnaîtrai sans difficulté…', 'il veut savoir à quoi elle ressemble, pas ce qu''elle fera',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S22 — MEDIUM — L'appartement du dessus
  ('880e5693-087d-5482-a157-52d4769e29b2', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S22', 'L''appartement du dessus',
   'Une amie cherche un logement dans votre immeuble. Elle vous écrit : « Le studio du cinquième se libère, tu l''as déjà vu ? Dis-moi à quoi il ressemble avant que je prenne rendez-vous. »',
   'Répondez-lui en décrivant ce studio.',
   'Votre réponse décrit le studio ; elle ne donne ni le loyer ni la marche à suivre pour visiter.',
   30, 60, NULL, 'MEDIUM', 7,
   '["Repérez sa question", "Décrivez le studio", "Laissez le loyer"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Oui, je l''ai visité l''an dernier. C''est…', 'elle veut se le représenter : surface, pièces, lumière, état',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S23 — MEDIUM — Les gens du jardin partagé
  ('f52242f7-bd9b-5a34-9a20-f1feb935e160', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S23', 'Les gens du jardin partagé',
   'Un voisin vous écrit : « J''hésite à prendre une parcelle au jardin partagé. Qui s''en occupe, en fait ? J''aimerais savoir dans quoi je mets les pieds. »',
   'Répondez-lui en décrivant les personnes qui font vivre ce jardin.',
   'Votre réponse décrit le groupe des jardiniers ; elle n''explique pas comment obtenir une parcelle.',
   30, 60, NULL, 'MEDIUM', 8,
   '["Voyez ce qu''il demande", "Décrivez les jardiniers", "Laissez les démarches"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Ce sont surtout des habitants du quartier…', 'il demande qui sont les gens, pas comment s''inscrire',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S24 — EASY — Un manteau oublié au café
  ('b7e7d949-8888-551f-9903-eae625d4a497', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S24', 'Un manteau oublié au café',
   'Le gérant du café vous écrit : « Bonjour, vous nous avez appelés pour un manteau oublié hier soir. Nous en avons trois derrière le comptoir. Le vôtre, il est comment ? »',
   'Répondez-lui en décrivant votre manteau.',
   'Votre réponse décrit le manteau ; elle ne raconte pas la soirée et ne demande pas de le mettre de côté.',
   30, 60, NULL, 'EASY', 9,
   '["Lisez sa question", "Décrivez le manteau", "Ne racontez pas la soirée"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Bonjour, c''est un manteau…', 'il en a trois : donnez ce qui distingue le vôtre',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S25 — MEDIUM — Le stand du marché
  ('f496c277-4980-5134-bc3f-3d4391b7d982', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S25', 'Le stand du marché',
   'Une amie vous écrit : « Tu m''as parlé d''un stand de fromages au marché du samedi. Je n''y suis jamais allée. Comment je le repère ? »',
   'Répondez-lui en décrivant ce stand.',
   'Votre réponse décrit le stand pour qu''elle le repère ; elle ne donne ni horaires ni conseils d''achat.',
   30, 60, NULL, 'MEDIUM', 10,
   '["Repérez sa question", "Décrivez le stand", "Laissez les horaires"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Tu le verras tout de suite…', 'elle veut le reconnaître dans la foule : couleur, taille, enseigne',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S26 — MEDIUM — L'entraîneur du club
  ('ebf8f92f-9a6f-59f2-999b-e859a74f52a5', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S26', 'L''entraîneur du club',
   'Un parent de l''école vous écrit : « Ma fille voudrait s''inscrire au club où va votre fils. C''est qui, l''entraîneur ? Je voudrais savoir comment il est avec les enfants. »',
   'Répondez-lui en décrivant l''entraîneur.',
   'Votre réponse décrit l''entraîneur — sa manière d''être avec les enfants ; elle ne parle pas des tarifs ni des horaires.',
   30, 60, NULL, 'MEDIUM', 11,
   '["Voyez ce qui l''intéresse", "Décrivez l''entraîneur", "Laissez les tarifs"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'L''entraîneur s''appelle Marc. C''est…', 'elle demande comment il est, pas ce que coûte le club',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S27 — MEDIUM — La salle d'attente du centre
  ('d0132b09-c9e9-5f33-8c9e-b16c52a58109', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S27', 'La salle d''attente du centre',
   'Votre cousin vous écrit : « J''ai rendez-vous au centre de santé jeudi avec le petit. On va attendre longtemps ? La salle est comment, il y a de quoi l''occuper ? »',
   'Répondez-lui en décrivant la salle d''attente du centre.',
   'Votre réponse décrit la salle d''attente ; elle ne donne pas de conseils sur le rendez-vous lui-même.',
   30, 60, NULL, 'MEDIUM', 12,
   '["Lisez sa question", "Décrivez la salle", "Laissez le rendez-vous"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'La salle d''attente est…', 'il pense à son enfant : place, sièges, jeux, bruit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S28 — HARD — L'équipe du matin
  ('11f25597-44fe-5070-a7bb-fbe4d84fb47e', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S28', 'L''équipe du matin',
   'Votre responsable vous écrit : « Vous passez à l''équipe du matin lundi. Je vous préviens, l''ambiance n''y est pas la même que le soir — dites-moi si ce que vous avez vu aux relèves vous inquiète. »',
   'Répondez-lui. Il ne pose pas sa question directement : à vous de comprendre ce qu''il veut savoir, et d''y répondre en décrivant l''équipe.',
   'Votre réponse décrit l''équipe du matin telle que vous l''avez observée ; elle ne parle ni de votre changement d''horaires ni de vos propres tâches.',
   30, 60, NULL, 'HARD', 13,
   '["Cherchez la vraie question", "Décrivez l''équipe", "Ne parlez pas de vous"]',
   '[{"label": "Demande implicite", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Je les croise chaque soir à la relève. Ils sont…', '« l''ambiance n''y est pas la même » : c''est d''eux qu''il veut vous entendre parler',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S29 — MEDIUM — Le fauteuil à donner
  ('d4a61f4e-c65b-5df5-96e2-377baf45657e', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S29', 'Le fauteuil à donner',
   'Sur le groupe de voisins, quelqu''un répond à votre annonce : « Bonjour, je veux bien le fauteuil ! Mais mon couloir est étroit. Il fait quelle taille et il est dans quel état ? »',
   'Répondez-lui en décrivant le fauteuil.',
   'Votre réponse décrit le fauteuil — taille et état ; elle n''organise pas l''enlèvement.',
   30, 60, NULL, 'MEDIUM', 14,
   '["Notez ses deux questions", "Décrivez taille et état", "N''organisez rien"]',
   '[{"label": "Réponse ciblée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Bonjour ! C''est un fauteuil…', 'deux questions posées, deux questions à traiter',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S30 — HARD — Le village de vos parents
  ('1bbb4b5a-d438-596d-a5c6-008cec876b3c', 'b8299921-bb1c-5ba0-a43f-16726ec134a5', 'EE', 'EE1-C2-S30', 'Le village de vos parents',
   'Une collègue vous écrit : « Tu m''as dit que tes parents vivaient dans un village de montagne. On cherche du calme cet été, mais ma mère marche mal. Le village est comment, et on y trouve quoi sur place ? »',
   'Répondez-lui en décrivant le village. Sa demande contient deux points : traitez-les tous les deux.',
   'Votre réponse décrit à la fois l''aspect du village et ce qu''on y trouve sur place ; elle ne raconte pas vos souvenirs et ne propose pas de logement.',
   30, 60, NULL, 'HARD', 15,
   '["Comptez ses questions", "Décrivez le village", "Dites ce qu''on y trouve"]',
   '[{"label": "Deux points à traiter", "icon": "NUMBER"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'C''est un village de…', 'elle demande deux choses : l''allure du village, et ce qu''il y a sur place',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S16 — EASY — La responsable de la crèche
  ('6d2fed68-65ef-5ade-afb0-595889e186c3', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S16', 'La responsable de la crèche',
   'La directrice de la crèche, qui vous vouvoie depuis l''inscription, vous écrit : « Madame, nous préparons le trombinoscope des familles. Pourriez-vous nous décrire la personne autorisée à venir chercher votre fils ? »',
   'Répondez-lui en décrivant cette personne, dans le registre qui convient à une directrice d''établissement.',
   'Votre réponse garde le vouvoiement et une ouverture polie adaptée à une directrice, tout en décrivant la personne.',
   30, 60, NULL, 'EASY', 1,
   '["Gardez le vouvoiement", "Ouvrez poliment", "Décrivez la personne"]',
   '[{"label": "Registre poli", "icon": "TONE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Madame, je vous remercie de votre message…', 'elle vous vouvoie : répondez de même, poliment et simplement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S17 — EASY — Ton frère et l'appartement
  ('59939b3d-478c-50e6-bb00-45be9eaba933', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S17', 'Ton frère et l''appartement',
   'Votre frère vous écrit : « Alors, t''as visité l''appart de la rue Verte ? Il est comment ? Raconte, je suis curieux ! »',
   'Répondez-lui en décrivant l''appartement, dans le registre qui convient à un frère.',
   'Votre réponse tutoie et emploie un ton familier naturel, sans formule administrative, tout en décrivant l''appartement.',
   30, 60, NULL, 'EASY', 2,
   '["Tutoyez votre frère", "Restez naturel", "Décrivez l''appartement"]',
   '[{"label": "Registre familier", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Oui, j''y suis allée hier !…', 'à un frère, on écrit comme on parle : pas de « Madame, Monsieur »',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S18 — MEDIUM — Le voisin que vous connaissez peu
  ('daac1fc8-243f-5046-8270-3e4c11108c2b', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S18', 'Le voisin que vous connaissez peu',
   'Un voisin du troisième, à qui vous dites seulement bonjour dans l''escalier, glisse un mot sous votre porte : « Bonjour, je cherche à louer un garage dans le quartier. Vous m''avez dit qu''il y en avait un de libre. Il est comment ? »',
   'Répondez-lui en décrivant ce garage, dans le registre qui convient à un voisin peu connu.',
   'Votre réponse vouvoie sans être froide, avec un ton poli de voisinage, tout en décrivant le garage.',
   30, 60, NULL, 'MEDIUM', 3,
   '["Vouvoyez ce voisin", "Restez cordial", "Décrivez le garage"]',
   '[{"label": "Registre poli", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Bonjour, oui, celui du fond de la cour…', 'il vous vouvoie dans son mot : répondez sur le même pied',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S19 — MEDIUM — Une amie très proche
  ('69fe32ec-8cdf-5f13-95d4-7ab5c9c13d61', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S19', 'Une amie très proche',
   'Votre meilleure amie vous écrit : « Bon alors, il est comment ce fameux collègue dont tu me parles depuis trois semaines ?! Je veux tout savoir. »',
   'Répondez-lui en décrivant ce collègue, dans le registre qui convient à une amie très proche.',
   'Votre réponse tutoie sur un ton complice et spontané, sans formule de politesse, tout en décrivant la personne.',
   30, 60, NULL, 'MEDIUM', 4,
   '["Tutoyez votre amie", "Restez complice", "Décrivez le collègue"]',
   '[{"label": "Registre familier", "icon": "TONE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Alors : il a…', 'à une amie proche, aucune formule d''ouverture n''est nécessaire',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S20 — MEDIUM — Le service des objets trouvés
  ('a9f94a27-0c28-54a8-8998-a84af1fa331b', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S20', 'Le service des objets trouvés',
   'Le service des objets trouvés de la gare vous écrit : « Madame, Monsieur, suite à votre déclaration, merci de nous transmettre une description détaillée de la valise afin que nous procédions aux recherches. »',
   'Répondez-leur en décrivant la valise, dans le registre qui convient à un service administratif.',
   'Votre réponse emploie le vouvoiement et les formules d''un courrier administratif, tout en décrivant la valise.',
   30, 60, NULL, 'MEDIUM', 5,
   '["Reprenez leur formule", "Restez formel", "Décrivez la valise"]',
   '[{"label": "Registre formel", "icon": "TONE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Madame, Monsieur, il s''agit d''une valise…', 'ils écrivent « Madame, Monsieur » : restez sur ce registre, sans en rajouter',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S21 — MEDIUM — Un ancien camarade retrouvé
  ('2c3c90ad-182e-5bf3-b203-cba873c25202', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S21', 'Un ancien camarade retrouvé',
   'Un camarade de classe que vous n''avez pas vu depuis dix ans vous écrit : « Hé ! Ça fait un bail ! Tu vis toujours à Nantes ? C''est comment ton quartier maintenant ? »',
   'Répondez-lui en décrivant votre quartier, dans le registre qui convient à un ancien camarade.',
   'Votre réponse tutoie sur un ton amical mais non intime, à la hauteur d''une relation ancienne renouée, tout en décrivant le quartier.',
   30, 60, NULL, 'MEDIUM', 6,
   '["Tutoyez sans excès", "Restez chaleureux", "Décrivez le quartier"]',
   '[{"label": "Registre amical", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Salut ! Oui, toujours à Nantes…', 'dix ans sans se voir : amical, mais pas intime',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S22 — HARD — Le bailleur social
  ('a66af20f-84ab-5cc3-b5a8-429412a5a578', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S22', 'Le bailleur social',
   'Votre bailleur vous écrit : « Madame, dans le cadre de l''enquête annuelle, merci de nous décrire l''état actuel de votre salle de bains, pièce signalée lors de la dernière visite. »',
   'Répondez-lui en décrivant l''état de cette pièce, dans le registre qui convient à un bailleur.',
   'Votre réponse emploie un registre formel et mesuré, sans familiarité ni agressivité, tout en décrivant la pièce.',
   30, 60, NULL, 'HARD', 7,
   '["Restez formel", "Gardez un ton mesuré", "Décrivez la pièce"]',
   '[{"label": "Registre formel", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Madame, Monsieur, voici l''état de la pièce…', 'un désaccord se dit aussi dans un ton calme et clair',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S23 — MEDIUM — Le groupe de parents d'élèves
  ('9e2e4c30-b92a-53b4-be41-eda022e0a563', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S23', 'Le groupe de parents d''élèves',
   'Sur le groupe des parents de la classe, une mère écrit : « Bonjour à tous ! Qui a déjà vu la nouvelle équipe d''animateurs du périscolaire ? Ils sont comment ? »',
   'Répondez sur le groupe en décrivant cette équipe, dans le registre qui convient à des parents que vous connaissez peu.',
   'Votre réponse emploie un ton cordial de groupe — ni intime, ni administratif — tout en décrivant l''équipe.',
   30, 60, NULL, 'MEDIUM', 8,
   '["Saluez le groupe", "Restez cordial", "Décrivez l''équipe"]',
   '[{"label": "Registre cordial", "icon": "TONE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Bonjour à tous…', 'un groupe de parents : on salue tout le monde, on reste simple',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S24 — HARD — Votre ancien professeur
  ('cd7bd720-ec22-5b36-a867-a04d4e3da723', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S24', 'Votre ancien professeur',
   'Votre ancien professeur de français, que vous avez toujours vouvoyé, vous écrit : « Bonjour, je prépare une exposition sur les parcours de mes anciens élèves. Pourriez-vous me décrire votre lieu de travail actuel ? »',
   'Répondez-lui en décrivant votre lieu de travail, dans le registre qui convient à un ancien professeur.',
   'Votre réponse garde le vouvoiement établi, sur un ton chaleureux et sans raideur, tout en décrivant le lieu.',
   30, 60, NULL, 'HARD', 9,
   '["Vouvoyez avec respect", "Évitez la raideur", "Décrivez le lieu"]',
   '[{"label": "Registre respectueux", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Bonjour Monsieur, quel plaisir d''avoir de vos nouvelles…', 'vous l''avez toujours vouvoyé : gardez cet usage, mais restez chaleureux',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S25 — MEDIUM — Le collègue que vous croisez peu
  ('618925a0-2fd3-5d4b-8a1d-4cbc8b059143', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S25', 'Le collègue que vous croisez peu',
   'Un collègue d''un autre service, avec qui vous échangez rarement, vous écrit : « Bonjour, je dois travailler avec l''équipe du bâtiment B le mois prochain. Vous les côtoyez souvent, je crois. Ils sont comment ? »',
   'Répondez-lui en décrivant cette équipe, dans le registre qui convient à un collègue peu connu.',
   'Votre réponse vouvoie sur un ton professionnel simple, ni amical ni cérémonieux, tout en décrivant l''équipe.',
   30, 60, NULL, 'MEDIUM', 10,
   '["Vouvoyez ce collègue", "Restez professionnel", "Décrivez l''équipe"]',
   '[{"label": "Registre professionnel", "icon": "TONE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Bonjour, oui, je travaille souvent avec eux…', 'un collègue peu connu : vouvoiement simple, sans « cher monsieur »',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S26 — MEDIUM — La mairie et le local associatif
  ('523d0eb0-12b5-58fa-ae48-8024f9fb92f5', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S26', 'La mairie et le local associatif',
   'Le service des associations de la mairie vous écrit : « Madame, Monsieur, dans le cadre du recensement des locaux, merci de nous décrire l''espace que votre association occupe au 4 rue Lamartine. »',
   'Répondez-leur en décrivant ce local, dans le registre qui convient à un service municipal.',
   'Votre réponse emploie le registre d''un courrier à une administration, tout en décrivant le local.',
   30, 60, NULL, 'MEDIUM', 11,
   '["Ouvrez comme eux", "Restez clair", "Décrivez le local"]',
   '[{"label": "Registre formel", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Madame, Monsieur, notre local se compose…', 'à une administration : clair, vouvoyé, sans formules inutiles',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S27 — HARD — Votre belle-mère
  ('87d1a014-562d-58a2-8d8e-8a0dc01ab04b', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S27', 'Votre belle-mère',
   'Votre belle-mère, que vous avez toujours vouvoyée, vous écrit : « Bonjour, je voudrais offrir un cadeau à votre fille pour son anniversaire mais je ne sais pas ce qui lui plairait. Elle est comment en ce moment, qu''est-ce qui l''intéresse ? »',
   'Répondez-lui en décrivant votre fille, dans le registre qui convient à une belle-mère.',
   'Votre réponse garde le vouvoiement établi entre vous, sur un ton chaleureux, tout en décrivant l''enfant.',
   30, 60, NULL, 'HARD', 12,
   '["Restez poli et chaleureux", "Ni froid ni familier", "Décrivez votre fille"]',
   '[{"label": "Vouvoiement chaleureux", "icon": "TONE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Bonjour, c''est très gentil d''y penser…', 'vous vous êtes toujours vouvoyées : gardez cet usage, sans froideur',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S28 — HARD — Le recruteur
  ('69c39627-a193-5853-bc72-7123e451474b', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S28', 'Le recruteur',
   'Une recruteuse vous écrit : « Bonjour, avant l''entretien de mardi, pourriez-vous me décrire en quelques lignes l''équipe avec laquelle vous travailliez dans votre poste précédent ? »',
   'Répondez-lui en décrivant cette équipe, dans le registre qui convient à une recruteuse.',
   'Votre réponse tient un registre professionnel soigné, sans familiarité ni jargon interne, tout en décrivant l''équipe.',
   30, 60, NULL, 'HARD', 13,
   '["Soignez le registre", "Évitez le jargon", "Décrivez l''équipe"]',
   '[{"label": "Registre professionnel", "icon": "TONE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Bonjour, bien sûr…', 'une recruteuse ne connaît pas votre ancienne maison : pas de sigles',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S29 — MEDIUM — L'assurance après le dégât
  ('e56c550d-ab9d-5cf2-b268-996096d8a351', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S29', 'L''assurance après le dégât',
   'Votre assurance vous écrit : « Madame, Monsieur, afin d''instruire votre dossier, merci de nous adresser une description du mobilier endommagé lors du sinistre du 3 mars. »',
   'Répondez-leur en décrivant le meuble endommagé, dans le registre qui convient à un assureur.',
   'Votre réponse emploie un registre formel et factuel, sans plainte ni familiarité, tout en décrivant le meuble.',
   30, 60, NULL, 'MEDIUM', 14,
   '["Restez formel", "Restez factuel", "Décrivez le meuble"]',
   '[{"label": "Registre formel", "icon": "TONE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Madame, Monsieur, le meuble endommagé est…', 'un assureur attend des faits précis, pas de l''émotion',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S30 — HARD — Le message ambigu du syndic
  ('ce4acb9b-c4d4-58c7-a58a-e1bbb70a6fc8', '80ff00c9-9a37-5ea0-9ea7-f4ed114c2a6e', 'EE', 'EE1-C1-S30', 'Le message ambigu du syndic',
   'Le syndic de votre immeuble vous écrit : « Bonjour Madame Sanchez, on m''a signalé un problème avec le vélo laissé dans le hall. Vous pouvez me dire à quoi il ressemble ? Merci d''avance. »',
   'Répondez-lui en décrivant ce vélo. Le message mêle deux registres : à vous de choisir celui qui convient.',
   'Votre réponse tient un registre poli et professionnel du début à la fin, sans glisser vers la familiarité que le message autorise à moitié.',
   30, 60, NULL, 'HARD', 15,
   '["Choisissez un registre", "Tenez-le jusqu''au bout", "Décrivez le vélo"]',
   '[{"label": "Registre à trancher", "icon": "TONE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Bonjour, il s''agit d''un vélo…', 'un message à moitié familier ne vous autorise pas à l''être tout à fait',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S1 — EASY — Trois cartons dans le garage
  ('f8b9d2eb-92b9-5eea-b2b9-488409bc311e', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S1', 'Trois cartons dans le garage',
   'Votre colocataire vous écrit : « Il y a trois cartons dans le garage et tu m''as dit d''en descendre un à la cave. Lequel ? »',
   'Répondez-lui en décrivant le carton concerné, de façon qu''il ne puisse pas se tromper.',
   'Votre réponse permet d''identifier un seul carton parmi trois : elle dit lequel avant de le décrire.',
   30, 60, NULL, 'EASY', 1,
   '["Dites lequel des trois", "Ajoutez un signe sûr", "Écartez les deux autres"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est celui qui…', 'il y en a trois : ce que vous dites doit n''en désigner qu''un',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S2 — EASY — Laquelle de mes collègues ?
  ('f20f1c49-41f5-5f18-a9e9-3967e06051d4', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S2', 'Laquelle de mes collègues ?',
   'Votre mari vous écrit : « Tu m''as dit qu''une de tes collègues viendrait dîner samedi. Je ne sais plus laquelle, tu m''en as présenté quatre à la soirée de Noël. »',
   'Répondez-lui en décrivant la collègue concernée, de façon qu''il la reconnaisse parmi les quatre.',
   'Votre réponse désigne une seule collègue parmi quatre : elle donne d''abord ce qui la distingue des autres.',
   30, 60, NULL, 'EASY', 2,
   '["Dites laquelle", "Donnez un trait unique", "Écartez les autres"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est celle qui…', 'il en a vu quatre : commencez par ce qui n''appartient qu''à elle',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S3 — MEDIUM — Quelle salle au deuxième ?
  ('4433f886-7f3e-58c2-9492-ad2d618c72d2', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S3', 'Quelle salle au deuxième ?',
   'Un stagiaire vous écrit : « Je dois installer le matériel dans une salle du deuxième étage, mais il y en a cinq et je ne sais pas laquelle. »',
   'Répondez-lui en décrivant la salle concernée, de façon qu''il la trouve seul.',
   'Votre réponse identifie une seule salle parmi cinq : elle donne un repère qui n''appartient qu''à elle.',
   30, 60, NULL, 'MEDIUM', 3,
   '["Dites laquelle", "Donnez un repère sûr", "Situez-la à l''étage"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'C''est la salle…', 'cinq salles au même étage : trouvez ce qui n''existe que dans une',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S4 — MEDIUM — Quel groupe d'enfants ?
  ('0b87735c-9071-57a5-bf58-234fad17ac15', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S4', 'Quel groupe d''enfants ?',
   'Une animatrice vous écrit : « On m''a demandé de prendre en charge un des groupes d''enfants au centre. Il y en a trois qui partent en sortie. C''est lequel ? »',
   'Répondez-lui en décrivant le groupe concerné, de façon qu''elle sache où se placer.',
   'Votre réponse identifie un seul groupe parmi trois : elle dit ce qui le distingue des deux autres.',
   30, 60, NULL, 'MEDIUM', 4,
   '["Dites lequel des trois", "Donnez un signe visible", "Écartez les autres"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'C''est le groupe…', 'trois groupes partent : dites ce qu''on voit du vôtre et pas des autres',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S5 — EASY — Lequel des vélos ?
  ('562d65b2-163b-5bdb-b147-5695ef1817ce', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S5', 'Lequel des vélos ?',
   'Le réparateur vous écrit : « Vous avez déposé deux vélos la semaine dernière. Lequel devons-nous réviser en priorité ? »',
   'Répondez-lui en décrivant le vélo concerné, de façon qu''il n''y ait aucun doute.',
   'Votre réponse identifie un seul vélo parmi deux : elle donne ce qui les distingue l''un de l''autre.',
   30, 60, NULL, 'EASY', 5,
   '["Dites lequel des deux", "Donnez la différence", "Restez sur ce vélo"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est le vélo…', 'deux vélos : une seule différence bien choisie suffit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S6 — MEDIUM — Quel appartement visiter ?
  ('221c9511-f7ae-5d66-aba6-f53dae8cf538', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S6', 'Quel appartement visiter ?',
   'Une amie vous écrit : « L''agence m''a envoyé quatre annonces d''appartements dans ta rue. Tu m''as dit d''en visiter un en particulier. C''était lequel ? »',
   'Répondez-lui en décrivant l''appartement concerné, de façon qu''elle le retrouve dans les annonces.',
   'Votre réponse identifie un seul appartement parmi quatre : elle donne des traits qui n''appartiennent qu''à lui.',
   30, 60, NULL, 'MEDIUM', 6,
   '["Dites lequel", "Donnez deux traits sûrs", "Écartez les autres"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'C''est celui du numéro…', 'quatre annonces se ressemblent : cherchez ce qui n''est vrai que d''une',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S7 — MEDIUM — Quelle personne à l'accueil ?
  ('7c6bf611-5de8-5140-b87d-85a08722032f', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S7', 'Quelle personne à l''accueil ?',
   'Votre fille vous écrit : « Je suis arrivée à la mairie. Tu m''as dit de demander quelqu''un en particulier au guichet, mais il y a trois personnes derrière le comptoir. »',
   'Répondez-lui en décrivant la personne à qui s''adresser, de façon qu''elle la reconnaisse.',
   'Votre réponse désigne une seule personne parmi trois : elle donne un trait visible qui n''appartient qu''à elle.',
   30, 60, NULL, 'MEDIUM', 7,
   '["Dites laquelle", "Donnez un trait visible", "Écartez les autres"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est la personne…', 'elle doit choisir tout de suite : donnez ce qui se voit de loin',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S8 — MEDIUM — Quel dossier sur le bureau ?
  ('749e5212-5c40-5681-8594-aedea9097a43', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S8', 'Quel dossier sur le bureau ?',
   'Une collègue vous écrit depuis votre bureau : « Il y a une pile de dossiers sur ta table. Tu voulais que j''en apporte un à la réunion. Je prends lequel ? »',
   'Répondez-lui en décrivant le dossier concerné, de façon qu''elle le prenne du premier coup.',
   'Votre réponse identifie un seul dossier dans une pile : elle donne un signe extérieur, pas seulement son contenu.',
   30, 60, NULL, 'MEDIUM', 8,
   '["Dites lequel", "Donnez un signe visible", "Évitez le contenu seul"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est le dossier…', 'elle ne va pas les ouvrir : dites ce qui se voit de l''extérieur',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S9 — MEDIUM — Quel arrêt de bus ?
  ('661232ff-4c2b-5822-b3a7-0c3e2ee936d1', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S9', 'Quel arrêt de bus ?',
   'Votre neveu vous écrit : « Je descends bientôt, mais il y a deux arrêts qui portent presque le même nom sur la ligne. Je descends auquel ? »',
   'Répondez-lui en décrivant l''arrêt concerné, de façon qu''il ne descende pas au mauvais.',
   'Votre réponse identifie un seul arrêt parmi deux noms voisins : elle donne ce qu''on voit depuis le bus.',
   30, 60, NULL, 'MEDIUM', 9,
   '["Dites lequel des deux", "Donnez ce qu''il verra", "Écartez l''autre"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Descends au deuxième…', 'deux noms se ressemblent : dites ce qu''on voit par la fenêtre',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S10 — HARD — Quelle équipe au tournoi ?
  ('701ca849-0278-59b1-a342-4fb3e06a31c0', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S10', 'Quelle équipe au tournoi ?',
   'Un ami vous écrit depuis le stade : « Tu m''as dit de venir encourager une équipe en particulier. Il y en a six sur le terrain et je ne sais pas laquelle est la tienne. »',
   'Répondez-lui en décrivant l''équipe concernée, de façon qu''il la repère depuis les gradins.',
   'Votre réponse identifie une seule équipe parmi six : elle donne un signe visible de loin.',
   30, 60, NULL, 'HARD', 10,
   '["Dites laquelle", "Donnez un signe de loin", "Écartez les autres"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'C''est l''équipe…', 'six équipes de loin : la couleur seule risque de se répéter',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S11 — HARD — Quel arbre dans le jardin ?
  ('a50adaac-52e2-5dc7-8000-b3496293824a', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S11', 'Quel arbre dans le jardin ?',
   'Le jardinier de la copropriété vous écrit : « Vous avez signalé un arbre à tailler dans le jardin commun. Il y en a une douzaine. Lequel exactement ? »',
   'Répondez-lui en décrivant l''arbre concerné, de façon qu''il n''en taille pas un autre.',
   'Votre réponse identifie un seul arbre parmi une douzaine : elle combine sa position et son aspect.',
   30, 60, NULL, 'HARD', 11,
   '["Situez-le d''abord", "Ajoutez son aspect", "Écartez les voisins"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "PLACE"}]',
   'C''est celui qui se trouve…', 'une douzaine d''arbres : la position seule ne suffit pas toujours',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S12 — HARD — Quel enfant récupérer ?
  ('49d22f17-1b87-5de6-a8c3-9f58a5fa4166', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S12', 'Quel enfant récupérer ?',
   'Une amie qui rend service vous écrit depuis l''école : « Je suis devant la classe, mais ils sortent tous en même temps. Ton fils, il est comment ? Je ne l''ai vu qu''en photo, il y a deux ans. »',
   'Répondez-lui en décrivant votre fils aujourd''hui, de façon qu''elle le reconnaisse dans le groupe.',
   'Votre réponse identifie votre fils dans un groupe d''enfants : elle tient compte du fait que la photo a deux ans.',
   30, 60, NULL, 'HARD', 12,
   '["Dites ce qui a changé", "Donnez un signe du jour", "Restez sur lui"]',
   '[{"label": "Repère périmé", "icon": "TIME"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Il a beaucoup changé depuis…', 'sa photo a deux ans : dites d''abord ce qui n''est plus vrai',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S13 — HARD — Quel local au sous-sol ?
  ('7b6ab1d1-35d5-5c93-bbad-b483d1eaa162', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S13', 'Quel local au sous-sol ?',
   'Un déménageur vous écrit : « Nous sommes au sous-sol. Il y a une rangée de caves numérotées et deux portes sans numéro. La vôtre, c''est laquelle ? »',
   'Répondez-lui en décrivant votre cave, de façon qu''il n''ouvre pas celle d''un voisin.',
   'Votre réponse identifie une seule cave : elle tient compte du fait que le numéro peut manquer.',
   30, 60, NULL, 'HARD', 13,
   '["Donnez le numéro", "Prévoyez qu''il manque", "Ajoutez un autre signe"]',
   '[{"label": "Repère incertain", "icon": "NUMBER"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'C''est la cave 7, mais…', 'deux portes n''ont pas de numéro : ne misez pas tout sur le chiffre',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S14 — HARD — Quelle réunion de parents ?
  ('5bc4044a-2b7a-54d8-b798-d24da5349a31', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S14', 'Quelle réunion de parents ?',
   'Votre conjoint vous écrit : « L''école envoie deux convocations le même soir : une pour les parents de CE2 et une pour le conseil d''école. Tu m''as dit d''aller à une des deux. Laquelle, et qui va être là ? »',
   'Répondez-lui en décrivant le groupe qu''il va rejoindre, de façon qu''il aille dans la bonne salle.',
   'Votre réponse identifie une seule réunion et décrit le groupe attendu ; elle ne confond pas les deux.',
   30, 60, NULL, 'HARD', 14,
   '["Dites laquelle des deux", "Décrivez qui sera là", "Écartez l''autre"]',
   '[{"label": "Un seul possible", "icon": "NUMBER"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'C''est celle des parents de CE2…', 'deux réunions le même soir : dites laquelle ET qui la compose',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S15 — HARD — Quelle pièce détachée ?
  ('f758331a-0b4e-5efa-98b1-362635b077f7', '93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1-C9-S15', 'Quelle pièce détachée ?',
   'Le vendeur vous écrit : « Nous avons reçu votre demande de pièce, mais votre modèle de four existe en trois versions. Décrivez-nous la pièce à remplacer, nous n''avons pas de référence. »',
   'Répondez-lui en décrivant la pièce concernée, sans référence à donner.',
   'Votre réponse identifie la pièce par son aspect et sa place dans l''appareil, puisque aucun numéro n''est disponible.',
   30, 60, NULL, 'HARD', 15,
   '["Dites où elle se trouve", "Décrivez sa forme", "Ne cherchez pas de référence"]',
   '[{"label": "Sans référence", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'La pièce se trouve…', 'aucun numéro : c''est la forme et la place qui l''identifient',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S1 — EASY — Un fauteuil pour une chambre d'enfant
  ('7c572584-8d15-5af3-8507-013b5ca91ccf', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S1', 'Un fauteuil pour une chambre d''enfant',
   'Une voisine vous écrit : « Vous donnez un fauteuil ? Je le mettrais dans la chambre de ma fille de trois ans. Il est comment ? »',
   'Répondez-lui en décrivant le fauteuil, en ne retenant que ce qui compte pour une chambre d''enfant.',
   'Votre réponse retient les traits utiles à son projet et laisse de côté ceux qui ne lui servent à rien.',
   30, 60, NULL, 'EASY', 1,
   '["Cherchez son projet", "Gardez ce qui sert", "Laissez le reste"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Pour une chambre d''enfant, il conviendra…', 'elle pense à une enfant de trois ans : tout ne compte pas également',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S2 — MEDIUM — Un quartier pour une personne âgée
  ('74d1561b-b30b-5e6a-8621-5af663b8eb9e', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S2', 'Un quartier pour une personne âgée',
   'Un ami vous écrit : « Mes parents cherchent à s''installer près de chez toi. Mon père a quatre-vingts ans et ne conduit plus. Ton quartier, il est comment ? »',
   'Répondez-lui en décrivant votre quartier, en ne retenant que ce qui compte pour ses parents.',
   'Votre réponse retient les traits utiles à des personnes âgées sans voiture et laisse de côté ce qui ne les concerne pas.',
   30, 60, NULL, 'MEDIUM', 2,
   '["Voyez leur situation", "Gardez ce qui sert", "Laissez le reste"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Pour eux, l''essentiel est que…', 'quatre-vingts ans, pas de voiture : cela trie tout seul',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S3 — MEDIUM — Une collègue pour un covoiturage
  ('ea6d25c5-a396-5134-ab86-2f34e4a05663', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S3', 'Une collègue pour un covoiturage',
   'Un ami vous écrit : « Tu m''as parlé d''une collègue qui cherche un covoiturage. Je peux la prendre, mais je pars très tôt et je n''ai qu''une place. Elle est comment ? »',
   'Répondez-lui en décrivant cette collègue, en ne retenant que ce qui compte pour un covoiturage.',
   'Votre réponse retient les traits utiles à un trajet partagé et laisse de côté ce qui relève de la vie privée ou du travail.',
   30, 60, NULL, 'MEDIUM', 3,
   '["Voyez sa contrainte", "Gardez ce qui sert", "Laissez le privé"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Pour un trajet partagé…', 'il part tôt et n''a qu''une place : c''est cela qui trie',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S4 — MEDIUM — Un logement pour un étudiant
  ('63e21f7a-b69e-54c8-958d-c179b0d67bb3', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S4', 'Un logement pour un étudiant',
   'Votre cousine vous écrit : « Mon fils entre à la fac en septembre, budget très serré. Tu m''as dit qu''un studio se libérait dans ton immeuble. Il est comment ? »',
   'Répondez-lui en décrivant ce studio, en ne retenant que ce qui compte pour un étudiant au budget serré.',
   'Votre réponse retient les traits utiles à un étudiant et laisse de côté ce qui ne pèse pas dans sa décision.',
   30, 60, NULL, 'MEDIUM', 4,
   '["Voyez sa contrainte", "Gardez ce qui sert", "Laissez le reste"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Pour un étudiant, ce qui compte…', 'budget serré et fac : deux filtres qui éliminent beaucoup',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S5 — MEDIUM — Un groupe pour une visite guidée
  ('ee26b63a-b35f-5899-9521-6304f6b7999c', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S5', 'Un groupe pour une visite guidée',
   'L''office de tourisme vous écrit : « Vous avez réservé une visite pour votre famille. Décrivez-nous votre groupe, nous adapterons le parcours et le rythme. »',
   'Répondez-leur en décrivant votre groupe, en ne retenant que ce qui compte pour adapter une visite.',
   'Votre réponse retient les traits qui pèsent sur le parcours et le rythme, et laisse de côté ce qui n''a pas d''effet.',
   30, 60, NULL, 'MEDIUM', 5,
   '["Voyez leur besoin", "Gardez ce qui sert", "Laissez le reste"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Nous serons sept, et ce qui compte…', 'ils adaptent parcours et rythme : dites ce qui les y oblige',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S6 — MEDIUM — Une machine à laver à reprendre
  ('be9e390a-6006-58cb-93b4-ba7f355bfeff', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S6', 'Une machine à laver à reprendre',
   'Un acheteur vous écrit : « Votre machine m''intéresse. Je suis au troisième sans ascenseur et je viens en voiture. Elle est comment ? »',
   'Répondez-lui en décrivant la machine, en ne retenant que ce qui compte pour son transport et son installation.',
   'Votre réponse retient les traits qui pèsent sur le transport et l''installation, et laisse de côté les fonctions du programme.',
   30, 60, NULL, 'MEDIUM', 6,
   '["Voyez sa contrainte", "Gardez ce qui sert", "Laissez les programmes"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Pour la monter, voici l''essentiel…', 'troisième sans ascenseur : le poids et les dimensions passent devant',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S7 — HARD — Une personne à reconnaître à la gare
  ('382c9390-122b-51fe-803e-4265660ad591', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S7', 'Une personne à reconnaître à la gare',
   'Votre belle-sœur vous écrit : « Je récupère ton amie à la gare demain, mais je ne l''ai jamais vue et il y aura foule. Elle est comment ? »',
   'Répondez-lui en décrivant votre amie, en ne retenant que ce qui se repère dans une gare bondée.',
   'Votre réponse retient les traits visibles de loin et dans la foule, et laisse de côté ceux qui ne se voient pas.',
   30, 60, NULL, 'HARD', 7,
   '["Pensez à la foule", "Gardez ce qui se voit", "Laissez le reste"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Dans la foule, tu repéreras…', 'dans une gare, on voit de loin et de dos : triez sur ce critère',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S8 — HARD — Une salle pour une personne en fauteuil
  ('36ea5488-c447-5b10-b3c5-5f138596ecca', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S8', 'Une salle pour une personne en fauteuil',
   'Une association vous écrit : « Nous voudrions louer votre salle pour une réunion. Trois de nos membres sont en fauteuil roulant. Elle est comment ? »',
   'Répondez-leur en décrivant la salle, en ne retenant que ce qui compte pour des personnes en fauteuil.',
   'Votre réponse retient les traits qui décident de l''accessibilité et laisse de côté ce qui relève du confort ou de la décoration.',
   30, 60, NULL, 'HARD', 8,
   '["Pensez aux fauteuils", "Gardez ce qui décide", "Laissez la déco"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Pour des fauteuils, voici les points décisifs…', 'trois fauteuils : largeur, marches, toilettes passent devant tout',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S9 — HARD — Une équipe pour un remplacement
  ('494b40f1-5c21-56b2-9b84-fa248643d962', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S9', 'Une équipe pour un remplacement',
   'Un intérimaire vous écrit : « J''arrive lundi pour une semaine dans votre service. Je ne connais personne. L''équipe est comment, pour que je sache à qui m''adresser ? »',
   'Répondez-lui en décrivant l''équipe, en ne retenant que ce qui compte pour quelqu''un qui reste une semaine.',
   'Votre réponse retient les traits utiles à un remplaçant de courte durée et laisse de côté l''histoire du service.',
   30, 60, NULL, 'HARD', 9,
   '["Pensez à sa semaine", "Dites à qui parler", "Laissez l''histoire"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'En une semaine, l''essentiel…', 'il reste cinq jours : il lui faut des repères, pas l''historique',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S10 — HARD — Un appareil photo pour débuter
  ('947f4a2d-2196-52ce-ac8c-3fb5e4ffee00', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S10', 'Un appareil photo pour débuter',
   'Votre neveu vous écrit : « Tu vends ton appareil photo ? Je débute complètement, je n''y connais rien. Il est comment ? »',
   'Répondez-lui en décrivant l''appareil, en ne retenant que ce qui compte pour un débutant.',
   'Votre réponse retient les traits parlants pour un débutant et laisse de côté les caractéristiques techniques qu''il ne peut pas interpréter.',
   30, 60, NULL, 'HARD', 10,
   '["Pensez au débutant", "Gardez ce qu''il comprend", "Laissez la technique"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Pour débuter, il est très bien…', 'il n''y connaît rien : un chiffre qu''il ne sait pas lire ne sert à rien',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S11 — EASY — Un jardin pour un chien
  ('b80e275c-c3b6-5739-a613-0a6391ad4749', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S11', 'Un jardin pour un chien',
   'Une amie vous écrit : « On visite la maison que tu m''avais conseillée. On a un grand chien qui saute partout. Le jardin est comment ? »',
   'Répondez-lui en décrivant le jardin, en ne retenant que ce qui compte quand on a un grand chien.',
   'Votre réponse retient les traits qui pèsent pour un chien et laisse de côté ce qui relève du jardinage d''agrément.',
   30, 60, NULL, 'EASY', 11,
   '["Pensez au chien", "Gardez ce qui compte", "Laissez les fleurs"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Avec un grand chien, ce qui compte…', 'un chien qui saute : clôture, surface, sol passent devant les massifs',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S12 — MEDIUM — Un artisan pour de petits travaux
  ('20955a66-2d8d-57b3-bb93-d0d256bf8659', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S12', 'Un artisan pour de petits travaux',
   'Un voisin vous écrit : « Tu m''avais parlé d''un artisan pour de petits travaux. J''ai juste deux prises à déplacer, rien d''énorme. Il est comment ? »',
   'Répondez-lui en décrivant cet artisan, en ne retenant que ce qui compte pour un petit chantier.',
   'Votre réponse retient les traits qui pèsent pour un petit chantier et laisse de côté ses références sur de gros travaux.',
   30, 60, NULL, 'MEDIUM', 12,
   '["Pensez au petit chantier", "Gardez ce qui pèse", "Laissez les gros travaux"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Pour deux prises, il est parfait…', 'deux prises, ce n''est pas un chantier : triez sur cette échelle',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S13 — HARD — Des voisins avant d'emménager
  ('74d3cf85-a662-5315-a384-671907be0194', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S13', 'Des voisins avant d''emménager',
   'Un ami vous écrit : « On signe pour l''appartement du deuxième. On a un bébé qui pleure la nuit. Les voisins sont comment ? »',
   'Répondez-lui en décrivant les voisins, en ne retenant que ce qui compte quand on a un bébé.',
   'Votre réponse retient les traits qui pèsent pour une famille avec un bébé et laisse de côté les portraits sans effet.',
   30, 60, NULL, 'HARD', 13,
   '["Pensez au bébé", "Gardez ce qui pèse", "Laissez les portraits"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Avec un bébé, ce qui compte…', 'un bébé qui pleure la nuit : c''est le bruit et la tolérance qui trient',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S14 — EASY — Une table pour un petit appartement
  ('c57e4396-6832-5bb2-9ba5-30ce71ec6ea1', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S14', 'Une table pour un petit appartement',
   'Votre sœur vous écrit : « Tu donnes ta table ? Ma cuisine fait sept mètres carrés et je reçois souvent quatre personnes. Elle est comment ? »',
   'Répondez-lui en décrivant la table, en ne retenant que ce qui compte pour une petite cuisine.',
   'Votre réponse retient les traits qui décident de la place occupée et du nombre de convives, et laisse de côté l''esthétique.',
   30, 60, NULL, 'EASY', 14,
   '["Pensez aux sept mètres", "Gardez taille et places", "Laissez le style"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Pour sept mètres carrés…', 'deux contraintes chiffrées : répondez avec des chiffres',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S15 — HARD — Une chambre pour deux nuits
  ('13713622-48c4-574b-8108-3b077cc46e81', '3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1-C10-S15', 'Une chambre pour deux nuits',
   'Un collègue vous écrit : « Tu m''héberges pour le séminaire ? Je viens juste deux nuits, j''arrive tard et je pars tôt. Ta chambre d''amis est comment ? »',
   'Répondez-lui en décrivant la chambre, en ne retenant que ce qui compte pour deux nuits courtes.',
   'Votre réponse retient les traits utiles pour deux nuits et laisse de côté ce qui ne servirait qu''à un séjour long.',
   30, 60, NULL, 'HARD', 15,
   '["Pensez aux deux nuits", "Gardez ce qui sert", "Laissez le superflu"]',
   '[{"label": "Traits choisis", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Pour deux nuits, l''essentiel…', 'il arrive tard et part tôt : le placard ne lui servira jamais',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S16 — EASY — Qui viendra chercher les clés
  ('f38b4129-5485-5af2-863a-8e46695a2d7d', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S16', 'Qui viendra chercher les clés',
   'L''agence immobilière vous écrit : « Madame, vous nous annoncez qu''une autre personne viendra rendre les clés. Pouvez-vous nous la décrire, afin que nous la reconnaissions à l''accueil ? »',
   'Répondez-leur en décrivant cette personne.',
   'Votre réponse décrit une personne par des traits qui permettent de la reconnaître à l''accueil.',
   30, 60, NULL, 'EASY', 1,
   '["Donnez son allure", "Ajoutez un vêtement", "Restez sur elle"]',
   '[{"label": "Aspect physique", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Il s''agit de ma belle-sœur…', 'à l''accueil, on reconnaît une allure avant un prénom',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S17 — EASY — Décrire son groupe à l'office
  ('624e058f-4232-59db-af7e-d68af48beb9c', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S17', 'Décrire son groupe à l''office',
   'L''office de tourisme vous écrit : « Bonjour, vous avez réservé pour une visite en famille. Décrivez-nous votre groupe : cela nous aide à vous conseiller un parcours. »',
   'Répondez-leur en décrivant votre groupe.',
   'Votre réponse décrit la composition du groupe et ce qui le caractérise, pas le programme de votre séjour.',
   30, 60, NULL, 'EASY', 2,
   '["Dites combien", "Donnez les âges", "Ajoutez l''ambiance"]',
   '[{"label": "Composition", "icon": "PERSON"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Nous serons six…', 'un groupe se décrit par qui le compose, pas par ce qu''il fera',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S18 — EASY — Le nouveau voisin de palier
  ('2c0c9646-914d-5319-812b-645b56692523', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S18', 'Le nouveau voisin de palier',
   'Une voisine du troisième vous écrit : « Il paraît que quelqu''un a emménagé au deuxième. Vous l''avez croisé ? Il est comment ? J''aimerais savoir à qui je dis bonjour. »',
   'Répondez-lui en décrivant ce nouveau voisin.',
   'Votre réponse décrit la personne — son allure et sa manière d''être — et non son emménagement.',
   30, 60, NULL, 'EASY', 3,
   '["Donnez son âge", "Décrivez son allure", "Dites comment il est"]',
   '[{"label": "Aspect et caractère", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Oui, je l''ai croisé deux fois. C''est…', 'elle veut mettre un visage sur un bonjour',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S19 — MEDIUM — L'équipe de bénévoles
  ('a18eecd8-06f2-54a6-89ae-a7e05c86dead', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S19', 'L''équipe de bénévoles',
   'La mairie vous écrit : « Bonjour, vous coordonnez les bénévoles de la fête de quartier. Décrivez-nous l''équipe que vous avez réunie cette année. »',
   'Répondez-leur en décrivant cette équipe de bénévoles.',
   'Votre réponse décrit la composition et l''ambiance de l''équipe, pas l''organisation de la fête.',
   30, 60, NULL, 'MEDIUM', 4,
   '["Dites combien", "Donnez les profils", "Ajoutez l''ambiance"]',
   '[{"label": "Composition", "icon": "PERSON"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'L''équipe compte…', 'ils demandent qui est l''équipe, pas ce qu''elle va organiser',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S20 — MEDIUM — La personne qui garde les enfants
  ('a4bdbcac-66ed-5efd-803f-40d3f4d98419', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S20', 'La personne qui garde les enfants',
   'Votre belle-mère vous écrit : « Tu m''as dit que quelqu''un garderait les petits samedi. Je passerai leur dire bonjour. Elle est comment, pour que je ne me trompe pas ? »',
   'Répondez-lui en décrivant cette personne.',
   'Votre réponse décrit la personne et sa manière d''être avec les enfants, pas l''organisation de la garde.',
   30, 60, NULL, 'MEDIUM', 5,
   '["Donnez son allure", "Dites comment elle est", "Laissez l''organisation"]',
   '[{"label": "Aspect et caractère", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est Élodie…', 'elle veut la reconnaître et savoir à qui elle confie les petits',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S21 — MEDIUM — Les gens du cours de sport
  ('feec348c-2384-53ba-bfb0-bd9b3d3dcad7', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S21', 'Les gens du cours de sport',
   'Une amie vous écrit : « J''hésite à venir à ton cours de gym. J''ai cinquante ans et je n''ai plus fait de sport depuis dix ans. Les autres sont comment ? »',
   'Répondez-lui en décrivant le groupe du cours.',
   'Votre réponse décrit qui compose le groupe et son ambiance, pas le contenu des séances.',
   30, 60, NULL, 'MEDIUM', 6,
   '["Dites combien", "Donnez les profils", "Ajoutez l''ambiance"]',
   '[{"label": "Composition", "icon": "PERSON"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Nous sommes une quinzaine, et…', 'elle craint d''être à part : dites qui sont les gens',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S22 — MEDIUM — Le médecin remplaçant
  ('8f04c9c7-6175-5e08-9c3c-070441b557a3', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S22', 'Le médecin remplaçant',
   'Votre père vous écrit : « J''ai rendez-vous jeudi mais tu m''as dit que mon médecin était remplacé. C''est qui ? Je n''aime pas arriver sans savoir. »',
   'Répondez-lui en décrivant ce médecin remplaçant.',
   'Votre réponse décrit la personne — son allure, son âge, sa façon d''être — et non le fonctionnement du cabinet.',
   30, 60, NULL, 'MEDIUM', 7,
   '["Donnez son âge", "Décrivez son allure", "Dites comment il est"]',
   '[{"label": "Aspect et caractère", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est le docteur Belkacem…', 'il est inquiet : décrivez la personne, pas le cabinet',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S23 — MEDIUM — L'équipe qui reprend le commerce
  ('91a8092a-2105-5f68-a872-e5184ce0dd43', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S23', 'L''équipe qui reprend le commerce',
   'Un habitué du quartier vous écrit : « On dit que la boulangerie est reprise. Vous les avez rencontrés ? Ils sont comment, ceux qui arrivent ? »',
   'Répondez-lui en décrivant les personnes qui reprennent la boulangerie.',
   'Votre réponse décrit le groupe qui reprend le commerce, pas les travaux ni les futurs produits.',
   30, 60, NULL, 'MEDIUM', 8,
   '["Dites combien", "Donnez qui ils sont", "Laissez les travaux"]',
   '[{"label": "Composition", "icon": "PERSON"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Ils sont trois…', 'il veut savoir qui arrive, pas ce qui sera vendu',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S24 — HARD — La personne au bout du fil
  ('cc79e190-920e-55ab-9d1d-9dba970f4637', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S24', 'La personne au bout du fil',
   'Votre sœur vous écrit : « Une dame a appelé chez maman en disant qu''elle te connaissait. Maman s''inquiète. Tu vois qui c''est ? Elle est comment ? »',
   'Répondez-lui en décrivant cette personne, pour rassurer votre mère.',
   'Votre réponse décrit la personne — qui elle est, son âge, sa manière d''être — sans se contenter d''expliquer l''appel.',
   30, 60, NULL, 'HARD', 9,
   '["Dites qui c''est", "Décrivez-la", "Ne racontez pas l''appel"]',
   '[{"label": "Aspect et caractère", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est Martine…', 'pour rassurer, il faut un portrait, pas une explication',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S25 — MEDIUM — Le groupe du voyage scolaire
  ('c69e0c60-c915-5676-ab8c-bc9bb1fafb39', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S25', 'Le groupe du voyage scolaire',
   'Le responsable du centre d''hébergement vous écrit : « Bonjour, vous arrivez lundi avec une classe. Décrivez-nous le groupe : nous répartissons les chambres à l''avance. »',
   'Répondez-lui en décrivant votre groupe d''élèves.',
   'Votre réponse décrit la composition du groupe, pas le programme du séjour ni les horaires d''arrivée.',
   30, 60, NULL, 'MEDIUM', 10,
   '["Dites combien", "Donnez la composition", "Laissez le programme"]',
   '[{"label": "Composition", "icon": "PERSON"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Le groupe compte…', 'ils répartissent des chambres : dites qui, pas quoi',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S26 — HARD — L'homme du marché
  ('37145258-97a8-5b40-9165-a9101825f35f', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S26', 'L''homme du marché',
   'Une amie vous écrit : « Tu m''as dit d''aller voir un maraîcher en particulier au marché du mardi. Je ne connais pas son nom. Il est comment ? »',
   'Répondez-lui en décrivant ce maraîcher.',
   'Votre réponse décrit la personne pour qu''elle le reconnaisse, et non son étal ni ses produits.',
   30, 60, NULL, 'HARD', 11,
   '["Décrivez l''homme", "Ajoutez sa manière", "Laissez l''étal"]',
   '[{"label": "Aspect et caractère", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est un homme…', 'elle demande une personne : l''étal viendrait trop facilement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S27 — HARD — Les habitants de l'immeuble
  ('172b23b8-d23e-5778-a935-1a92b6935e8b', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S27', 'Les habitants de l''immeuble',
   'Une future locataire vous écrit : « Je visite un appartement dans votre immeuble jeudi. Vous y vivez depuis longtemps, je crois. Les habitants sont comment ? »',
   'Répondez-lui en décrivant les habitants de l''immeuble.',
   'Votre réponse décrit qui habite l''immeuble et l''ambiance entre voisins, et non l''état du bâtiment.',
   30, 60, NULL, 'HARD', 12,
   '["Dites qui habite là", "Donnez l''ambiance", "Laissez le bâtiment"]',
   '[{"label": "Composition", "icon": "PERSON"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Nous sommes huit foyers…', 'elle demande les gens : l''immeuble viendrait trop naturellement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S28 — HARD — Le jeune qui cherche un stage
  ('06b68b61-d518-5c3e-8b5d-bd8a9ec9f4bb', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S28', 'Le jeune qui cherche un stage',
   'Une connaissance vous écrit : « Tu m''as parlé d''un jeune qui cherche un stage. Je peux peut-être le prendre. Il est comment ? Je veux savoir à qui j''aurai affaire. »',
   'Répondez-lui en décrivant ce jeune.',
   'Votre réponse décrit la personne — son âge, sa manière d''être, son sérieux — sans se limiter à son parcours scolaire.',
   30, 60, NULL, 'HARD', 13,
   '["Donnez son âge", "Dites comment il est", "Pas que le diplôme"]',
   '[{"label": "Aspect et caractère", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est Yanis…', 'elle veut savoir qui elle accueille, pas ce qu''il a étudié',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S29 — HARD — Le public du concert
  ('4c47a9fc-739c-559e-90e5-cb500d99bcc3', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S29', 'Le public du concert',
   'Un musicien ami vous écrit : « Je joue dans cette salle le mois prochain et je ne sais pas quoi préparer. Tu y vas souvent : le public est comment ? »',
   'Répondez-lui en décrivant le public de cette salle.',
   'Votre réponse décrit le public — qui il est, comment il réagit — et non la salle ni la programmation.',
   30, 60, NULL, 'HARD', 14,
   '["Dites qui vient", "Décrivez ses réactions", "Laissez la salle"]',
   '[{"label": "Composition", "icon": "PERSON"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Le public est…', 'il demande le public : la salle et la programmation ne sont pas lui',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S30 — HARD — La personne qui vous remplace
  ('565b5ccc-f262-59a7-a416-0ca05e497a45', 'b4ca6bf8-4f11-5341-9b3f-85e7d2baa034', 'EE', 'EE1-C7-S30', 'La personne qui vous remplace',
   'Votre responsable vous écrit : « Vous partez en congé trois semaines. Décrivez-moi la personne que vous proposez pour vous remplacer, je ne la connais pas. »',
   'Répondez-lui en décrivant cette personne.',
   'Votre réponse décrit la personne et sa façon de travailler, sans se transformer en liste de tâches à transmettre.',
   30, 60, NULL, 'HARD', 15,
   '["Dites qui elle est", "Décrivez sa façon", "Pas la liste des tâches"]',
   '[{"label": "Aspect et caractère", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Je propose Fatou…', 'il ne la connaît pas : c''est un portrait qu''il attend',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S1 — EASY — Le studio à louer
  ('db781b4a-efaa-5b6a-ad77-a146211424e5', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S1', 'Le studio à louer',
   'Une étudiante répond à votre annonce : « Bonjour, votre studio est encore libre ? Les photos ne montrent qu''une pièce. Il est comment exactement ? »',
   'Répondez-lui en décrivant le studio.',
   'Votre réponse caractérise le logement : surface, agencement, lumière, état.',
   30, 60, NULL, 'EASY', 1,
   '["Donnez la surface", "Dites l''agencement", "Ajoutez la lumière"]',
   '[{"label": "Surface et agencement", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'C''est une pièce de…', 'un logement se décrit par ses mesures avant ses qualités',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S2 — EASY — Le sac oublié dans le bus
  ('9db0edd9-34b3-52ce-aa45-f54daafd77a0', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S2', 'Le sac oublié dans le bus',
   'Le service des objets trouvés vous écrit : « Bonjour, nous avons plusieurs sacs pour la ligne 12 hier. Décrivez-nous le vôtre. »',
   'Répondez-leur en décrivant votre sac.',
   'Votre réponse caractérise l''objet : forme, taille, matière, couleur, signes particuliers.',
   30, 60, NULL, 'EASY', 2,
   '["Dites la forme", "Donnez la matière", "Ajoutez un signe"]',
   '[{"label": "Forme et matière", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est un sac…', 'un objet se décrit par ce qu''on en voit, pas par ce qu''il contient',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S3 — EASY — Le quartier depuis la fenêtre
  ('4a055e34-909c-5ff2-acd5-8e2059b2985f', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S3', 'Le quartier depuis la fenêtre',
   'Votre sœur, installée à l''étranger, vous écrit : « Tu as déménagé et je n''ai vu aucune photo. C''est comment autour de chez toi ? »',
   'Répondez-lui en décrivant votre quartier.',
   'Votre réponse caractérise le quartier : ce qu''on y voit, son ambiance, ce qu''on y trouve.',
   30, 60, NULL, 'EASY', 3,
   '["Dites ce qu''on voit", "Donnez l''ambiance", "Citez un commerce"]',
   '[{"label": "Ambiance et repères", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'De ma fenêtre, je vois…', 'elle n''a aucune image : partez de ce qu''on voit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S4 — MEDIUM — Le vélo volé
  ('3efbf76b-2901-5ebc-a553-be57bc6c353a', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S4', 'Le vélo volé',
   'Votre assurance vous écrit : « Madame, pour instruire votre déclaration de vol, merci de nous décrire précisément le vélo dérobé. »',
   'Répondez-leur en décrivant ce vélo.',
   'Votre réponse caractérise le vélo : type, couleur, équipements, état, signes particuliers.',
   30, 60, NULL, 'MEDIUM', 4,
   '["Donnez le type", "Listez les équipements", "Ajoutez un signe"]',
   '[{"label": "Équipements et état", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Il s''agit d''un vélo…', 'un signe particulier vaut mieux que trois adjectifs',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S5 — MEDIUM — La chambre d'hôte
  ('1f0beb22-0f79-53fc-87c0-ddbe6397d2ea', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S5', 'La chambre d''hôte',
   'Un couple vous écrit : « Bonjour, nous hésitons à réserver votre chambre. Le site ne montre qu''une photo. Elle est comment ? »',
   'Répondez-leur en décrivant la chambre.',
   'Votre réponse caractérise la chambre : dimensions, mobilier, exposition, équipements.',
   30, 60, NULL, 'MEDIUM', 5,
   '["Donnez la taille", "Dites le mobilier", "Ajoutez l''exposition"]',
   '[{"label": "Mobilier et exposition", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'La chambre fait…', 'une seule photo : dites ce qu''elle ne montre pas',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S6 — MEDIUM — Le four à donner
  ('5c6ca7d3-f01e-5776-94e2-133d4f897cbd', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S6', 'Le four à donner',
   'Une voisine vous écrit : « Vous donnez votre four ? Ma cuisine est petite et je cuisine beaucoup. Il est comment ? »',
   'Répondez-lui en décrivant le four.',
   'Votre réponse caractérise l''appareil : dimensions, aspect, état, fonctionnement.',
   30, 60, NULL, 'MEDIUM', 6,
   '["Donnez les dimensions", "Dites l''état", "Ajoutez un défaut"]',
   '[{"label": "Dimensions et état", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est un four…', 'un objet donné se décrit avec ses défauts, sinon la personne se déplace pour rien',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S7 — MEDIUM — La salle des fêtes
  ('be52610b-0abb-537a-a936-b3139e8b0b93', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S7', 'La salle des fêtes',
   'Une association vous écrit : « Bonjour, on nous a conseillé la salle de votre village pour notre assemblée. Elle est comment ? »',
   'Répondez-leur en décrivant cette salle.',
   'Votre réponse caractérise la salle : dimensions, capacité, équipements, état.',
   30, 60, NULL, 'MEDIUM', 7,
   '["Donnez la capacité", "Dites les équipements", "Ajoutez l''état"]',
   '[{"label": "Capacité et équipements", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'La salle accueille…', 'une salle se décrit d''abord par ce qu''elle peut contenir',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S8 — HARD — La montre de famille
  ('558232b4-40c0-5848-be8d-1ad2923f50d0', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S8', 'La montre de famille',
   'Un horloger vous écrit : « Bonjour, vous nous avez appelés pour une réparation. Avant de vous donner une estimation, décrivez-nous la montre. »',
   'Répondez-lui en décrivant cette montre.',
   'Votre réponse caractérise l''objet : matière, taille, mécanisme visible, état, marques.',
   30, 60, NULL, 'HARD', 8,
   '["Donnez la matière", "Dites la taille", "Ajoutez les marques"]',
   '[{"label": "Matière et marques", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est une montre…', 'un horloger estime d''après la matière et le mécanisme, pas d''après l''histoire',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S9 — HARD — Le local commercial
  ('68be9f12-3bf6-551d-88c3-b7e20e85ad97', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S9', 'Le local commercial',
   'Une amie qui veut ouvrir un salon vous écrit : « Tu m''as parlé du local libre en bas de chez toi. Il est comment ? Je n''ose pas appeler l''agence sans savoir. »',
   'Répondez-lui en décrivant ce local.',
   'Votre réponse caractérise le local : surface, vitrine, état, aménagement existant.',
   30, 60, NULL, 'HARD', 9,
   '["Donnez la surface", "Décrivez la vitrine", "Dites l''état"]',
   '[{"label": "Surface et état", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Le local fait…', 'un local vide se décrit par ce qui reste, pas par ce qu''on pourrait y faire',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S10 — HARD — Le meuble à restaurer
  ('1ae90a42-fde6-5743-9d04-27f383bec90d', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S10', 'Le meuble à restaurer',
   'Un menuisier vous écrit : « Bonjour, vous souhaitez faire restaurer un meuble. Décrivez-le-moi avant que je me déplace. »',
   'Répondez-lui en décrivant ce meuble.',
   'Votre réponse caractérise le meuble : dimensions, bois, assemblage visible, dégâts.',
   30, 60, NULL, 'HARD', 10,
   '["Donnez les dimensions", "Dites le bois", "Décrivez les dégâts"]',
   '[{"label": "Dimensions et dégâts", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est une commode…', 'un artisan se déplace sur une description, pas sur une intention',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S11 — HARD — Le jardin à entretenir
  ('01f499c2-8800-5a5e-a029-228048a20d89', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S11', 'Le jardin à entretenir',
   'Un jardinier vous écrit : « Bonjour, vous cherchez quelqu''un pour un entretien régulier. Décrivez-moi le jardin, je vous ferai un devis. »',
   'Répondez-lui en décrivant ce jardin.',
   'Votre réponse caractérise le jardin : surface, ce qui le compose, accès, état.',
   30, 60, NULL, 'HARD', 11,
   '["Donnez la surface", "Dites ce qu''il y a", "Précisez l''accès"]',
   '[{"label": "Surface et composition", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Le jardin fait…', 'un devis se fait sur des surfaces et des accès, pas sur des envies',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S12 — MEDIUM — L'instrument prêté
  ('2a2e86d5-4a14-5057-9dbf-326b26f407a1', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S12', 'L''instrument prêté',
   'Le professeur de musique vous écrit : « Bonjour, votre fils doit rapporter l''instrument prêté. Décrivez-le-moi, j''ai plusieurs retours à vérifier. »',
   'Répondez-lui en décrivant cet instrument.',
   'Votre réponse caractérise l''instrument : type, taille, matière, état, marques.',
   30, 60, NULL, 'MEDIUM', 12,
   '["Dites le type", "Donnez la taille", "Précisez l''état"]',
   '[{"label": "Type et état", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est un violon…', 'plusieurs retours à vérifier : dites ce qui distingue celui-ci',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S13 — HARD — La cave à visiter
  ('4d5c3b8e-acc7-5786-ac60-10dedb864c49', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S13', 'La cave à visiter',
   'Un acheteur potentiel vous écrit : « Bonjour, l''annonce mentionne une cave mais aucune photo. Elle est comment ? J''y stockerais du matériel. »',
   'Répondez-lui en décrivant cette cave.',
   'Votre réponse caractérise la cave : surface, hauteur, humidité, accès, état.',
   30, 60, NULL, 'HARD', 13,
   '["Donnez la surface", "Dites la hauteur", "Précisez l''humidité"]',
   '[{"label": "Surface et état", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'La cave fait…', 'pour stocker, l''humidité et l''accès comptent autant que la surface',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S14 — HARD — L'appareil en panne
  ('03a7ca1e-250e-589f-a74a-e46b0282635e', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S14', 'L''appareil en panne',
   'Le service après-vente vous écrit : « Bonjour, nous n''avons pas retrouvé votre modèle dans nos fichiers. Décrivez-nous l''appareil et son comportement. »',
   'Répondez-leur en décrivant l''appareil.',
   'Votre réponse caractérise l''appareil : aspect, dimensions, commandes visibles, et ce qu''il fait.',
   30, 60, NULL, 'HARD', 14,
   '["Décrivez l''appareil", "Dites les commandes", "Ajoutez son comportement"]',
   '[{"label": "Aspect et fonctionnement", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est un appareil…', 'sans référence, ce sont les commandes visibles qui identifient un modèle',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S15 — HARD — La pièce d'eau du parc
  ('959e75f0-0c70-5290-ae72-27eeaa19219d', 'c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1-C11-S15', 'La pièce d''eau du parc',
   'Un journaliste du journal municipal vous écrit : « Bonjour, vous présidez l''association du parc. Décrivez-nous le bassin, nous préparons un article sur sa rénovation. »',
   'Répondez-lui en décrivant ce bassin.',
   'Votre réponse caractérise le bassin : dimensions, forme, matériaux, état, environnement immédiat.',
   30, 60, NULL, 'HARD', 15,
   '["Donnez les dimensions", "Dites les matériaux", "Décrivez l''état"]',
   '[{"label": "Forme et matériaux", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Le bassin est…', 'un article a besoin d''images : décrivez, ne militez pas',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S16 — EASY — Un chèque envoyé sans détail
  ('d7c65e2f-9a7d-5fc4-a7e1-5caaf8264a6c', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S16', 'Un chèque envoyé sans détail',
   'Votre banque vous écrit : « Bonjour, vous signalez un chèque perdu. Plusieurs correspondent à votre compte. Décrivez celui-ci précisément. »',
   'Répondez-leur en décrivant ce chèque avec des éléments vérifiables.',
   'Votre réponse s''appuie sur des éléments vérifiables — montant, date, numéro, aspect — et non sur des impressions.',
   30, 60, NULL, 'EASY', 1,
   '["Donnez un chiffre", "Donnez une date", "Évitez le vague"]',
   '[{"label": "Chiffres exacts", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Il s''agit du chèque de…', '« assez récent » ne se vérifie pas, une date oui',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S17 — EASY — L'endroit exact de la fuite
  ('a70c7fba-9c0a-5823-8e3f-480d8b13eb88', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S17', 'L''endroit exact de la fuite',
   'Le plombier vous écrit : « Bonjour, avant de venir, dites-moi où ça fuit exactement. Cela change le matériel que j''emporte. »',
   'Répondez-lui en décrivant précisément l''endroit et l''aspect de la fuite.',
   'Votre réponse situe la fuite par des repères vérifiables — pièce, hauteur, élément — et en donne l''ampleur chiffrée.',
   30, 60, NULL, 'EASY', 2,
   '["Situez précisément", "Donnez une quantité", "Évitez le vague"]',
   '[{"label": "Emplacement exact", "icon": "PLACE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'La fuite se trouve…', '« ça fuit beaucoup » n''aide pas : dites combien et où',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S18 — EASY — Le colis à reconnaître
  ('bf712839-fd0c-5f91-b25e-7931e7dc17c7', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S18', 'Le colis à reconnaître',
   'Le gardien vous écrit : « Bonjour, deux colis attendent au même nom. Décrivez-moi le vôtre précisément, je ne veux pas me tromper. »',
   'Répondez-lui en décrivant votre colis avec des éléments vérifiables.',
   'Votre réponse s''appuie sur des éléments mesurables ou visibles, pas sur une appréciation générale.',
   30, 60, NULL, 'EASY', 3,
   '["Donnez une dimension", "Donnez une couleur", "Ajoutez un repère"]',
   '[{"label": "Mesures et couleurs", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Le mien mesure…', '« assez grand » dépend de qui regarde : donnez des centimètres',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S19 — MEDIUM — Une trace sur le mur
  ('835318e4-62c0-5a63-9c7c-85e68152a265', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S19', 'Une trace sur le mur',
   'Votre assurance vous écrit : « Madame, décrivez-nous précisément les traces d''humidité constatées, l''expert passera avec ces éléments. »',
   'Répondez-leur en décrivant ces traces avec des éléments vérifiables.',
   'Votre réponse donne l''emplacement, l''étendue et l''aspect des traces en termes vérifiables.',
   30, 60, NULL, 'MEDIUM', 4,
   '["Situez sur le mur", "Donnez l''étendue", "Décrivez l''aspect"]',
   '[{"label": "Étendue chiffrée", "icon": "NUMBER"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Les traces se trouvent…', 'un expert mesure : donnez-lui des mesures',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S20 — MEDIUM — L'inconnu filmé par l'interphone
  ('af343de7-7345-5fc8-88b7-388a668cac15', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S20', 'L''inconnu filmé par l''interphone',
   'Le syndic vous écrit : « Bonjour, vous signalez un passage suspect mardi. Décrivez-nous précisément la personne, nous consulterons les enregistrements. »',
   'Répondez-leur en décrivant cette personne avec des éléments vérifiables.',
   'Votre réponse donne des éléments vérifiables — taille, moment, vêtements, objets portés — sans jugement.',
   30, 60, NULL, 'MEDIUM', 5,
   '["Donnez l''heure", "Décrivez les vêtements", "Évitez le jugement"]',
   '[{"label": "Faits vérifiables", "icon": "TIME"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'La personne est passée…', '« l''air louche » ne se vérifie pas, une heure et une veste oui',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S21 — MEDIUM — Le bruit qui revient
  ('69cf4bcf-b134-5766-873b-a788ed043ee4', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S21', 'Le bruit qui revient',
   'Le garagiste vous écrit : « Bonjour, vous parlez d''un bruit. Décrivez-le précisément : quand, où, à quelle vitesse. Sinon je ne le retrouverai pas. »',
   'Répondez-lui en décrivant ce bruit avec des éléments vérifiables.',
   'Votre réponse situe le phénomène par des conditions précises et reproductibles.',
   30, 60, NULL, 'MEDIUM', 6,
   '["Dites quand", "Dites où", "Donnez la vitesse"]',
   '[{"label": "Conditions précises", "icon": "TIME"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Le bruit apparaît…', 'il doit pouvoir reproduire le bruit : donnez-lui les conditions',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S22 — MEDIUM — La plante à identifier
  ('95f4213b-aa2a-5ca8-85e8-77ec89fe5802', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S22', 'La plante à identifier',
   'Une jardinerie vous écrit : « Bonjour, sans photo nous ne pouvons pas identifier votre plante. Décrivez-la précisément : feuilles, taille, fleurs. »',
   'Répondez-leur en décrivant cette plante avec des éléments vérifiables.',
   'Votre réponse décrit la plante par des caractères observables et mesurables, pas par son effet sur vous.',
   30, 60, NULL, 'MEDIUM', 7,
   '["Décrivez les feuilles", "Donnez la taille", "Dites la floraison"]',
   '[{"label": "Caractères observables", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'La plante mesure…', '« très belle » ne l''identifie pas : comptez, mesurez, regardez',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S23 — MEDIUM — La place de parking
  ('503236a9-7aaf-5ce3-9143-e4e2e16cff00', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S23', 'La place de parking',
   'Un futur locataire vous écrit : « Bonjour, l''annonce mentionne une place de parking. Elle est comment exactement ? J''ai un monospace. »',
   'Répondez-lui en décrivant cette place avec des éléments vérifiables.',
   'Votre réponse donne les dimensions et les contraintes d''accès réelles, sans les qualifier de « suffisantes ».',
   30, 60, NULL, 'MEDIUM', 8,
   '["Donnez les dimensions", "Dites l''accès", "Évitez « suffisant »"]',
   '[{"label": "Dimensions exactes", "icon": "NUMBER"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'La place fait…', '« ça passe largement » ne se vérifie pas : donnez des mètres',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S24 — HARD — Le document manquant
  ('53f3cc6c-bf61-5edf-b45a-a9fe257f4ac9', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S24', 'Le document manquant',
   'La préfecture vous écrit : « Madame, vous indiquez qu''un document ne figure pas dans votre dossier. Décrivez précisément la pièce concernée. »',
   'Répondez-leur en décrivant précisément ce document.',
   'Votre réponse identifie le document par des éléments vérifiables — nature, date, émetteur, format.',
   30, 60, NULL, 'HARD', 9,
   '["Nommez la pièce", "Donnez sa date", "Dites qui l''a émise"]',
   '[{"label": "Références exactes", "icon": "NUMBER"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Il s''agit de…', 'une administration retrouve une pièce par sa date et son émetteur',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S25 — HARD — Le passage difficile
  ('fdc7defc-d074-584e-80ce-c8fac475c478', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S25', 'Le passage difficile',
   'Une entreprise de déménagement vous écrit : « Bonjour, vous parlez d''un accès compliqué. Décrivez-le précisément, cela détermine le camion que nous envoyons. »',
   'Répondez-leur en décrivant cet accès avec des éléments vérifiables.',
   'Votre réponse donne les largeurs, hauteurs et distances réelles, sans qualifier l''accès de « juste » ou « difficile ».',
   30, 60, NULL, 'HARD', 10,
   '["Donnez les largeurs", "Donnez les distances", "Évitez « difficile »"]',
   '[{"label": "Mesures d''accès", "icon": "NUMBER"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'L''accès se fait par…', 'ils choisissent un camion sur des chiffres, pas sur un adjectif',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S26 — HARD — La personne à l'accueil du salon
  ('57b6aa6b-ccc1-52fc-8ee6-32ce397bbb25', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S26', 'La personne à l''accueil du salon',
   'Une collègue vous écrit : « Je te rejoins au salon professionnel. Tu m''as dit de demander quelqu''un à l''accueil du stand. Elle est comment, précisément ? »',
   'Répondez-lui en décrivant cette personne avec des éléments vérifiables.',
   'Votre réponse donne des traits observables et un repère de position, sans jugement de caractère.',
   30, 60, NULL, 'HARD', 11,
   '["Donnez des traits visibles", "Situez-la au stand", "Évitez le caractère"]',
   '[{"label": "Faits vérifiables", "icon": "PERSON"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Tu la trouveras…', 'un salon est bondé : ce qui se voit prime sur ce qu''on sait d''elle',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S27 — HARD — L'horaire de la panne
  ('1f251b67-1a99-592c-a73d-b67d40ec0ce0', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S27', 'L''horaire de la panne',
   'Le fournisseur d''électricité vous écrit : « Bonjour, pour traiter votre réclamation, décrivez précisément les coupures : dates, heures, durées. »',
   'Répondez-leur en décrivant ces coupures avec des éléments vérifiables.',
   'Votre réponse donne des dates, des heures et des durées précises, sans généralisation.',
   30, 60, NULL, 'HARD', 12,
   '["Donnez les dates", "Donnez les heures", "Donnez les durées"]',
   '[{"label": "Dates et durées", "icon": "TIME"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'J''ai relevé trois coupures…', '« tout le temps » n''ouvre aucun dossier : relevez, datez, chronométrez',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S28 — HARD — Le trajet à pied
  ('04598999-329c-53a9-8faf-7bb3cd97167f', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S28', 'Le trajet à pied',
   'Un livreur vous écrit : « Bonjour, le GPS s''arrête à l''entrée de la résidence. Décrivez-moi précisément le chemin jusqu''à votre porte. »',
   'Répondez-lui en décrivant ce chemin avec des repères vérifiables.',
   'Votre réponse s''appuie sur des repères visibles et des distances, pas sur des indications relatives comme « après » ou « pas loin ».',
   30, 60, NULL, 'HARD', 13,
   '["Donnez des repères visibles", "Donnez une distance", "Évitez le relatif"]',
   '[{"label": "Repères visibles", "icon": "PLACE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Après le portail, comptez…', 'il ne connaît rien : chaque repère doit se voir depuis le précédent',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S29 — HARD — Les participants attendus
  ('b21205c7-b558-5280-a060-eb619834ffe8', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S29', 'Les participants attendus',
   'Un traiteur vous écrit : « Bonjour, pour établir le devis, décrivez précisément le groupe attendu : nombre, âges, contraintes alimentaires. »',
   'Répondez-lui en décrivant le groupe avec des éléments vérifiables.',
   'Votre réponse donne des nombres exacts et des contraintes nommées, sans approximation du type « une trentaine ».',
   30, 60, NULL, 'HARD', 14,
   '["Donnez les nombres", "Détaillez les régimes", "Évitez l''à-peu-près"]',
   '[{"label": "Nombres exacts", "icon": "NUMBER"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Nous serons exactement…', 'un devis se calcule sur des nombres, pas sur « une trentaine »',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S30 — HARD — Le créneau resté libre
  ('2c000a7c-85e7-5d90-a2d9-91515714431b', 'd711bcba-beb2-584a-a090-14a2f4d92efb', 'EE', 'EE1-C3-S30', 'Le créneau resté libre',
   'La secrétaire du cabinet vous écrit : « Bonjour, vous dites être venue mais ne pas avoir été reçue. Décrivez précisément ce que vous avez constaté sur place. »',
   'Répondez-lui en décrivant précisément ce que vous avez constaté.',
   'Votre réponse s''appuie sur des faits datés et observables, sans interprétation ni reproche.',
   30, 60, NULL, 'HARD', 15,
   '["Donnez l''heure", "Notez les faits vus", "Pas d''interprétation"]',
   '[{"label": "Faits vérifiables", "icon": "TIME"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Je me suis présentée…', 'un constat se vérifie, une interprétation non',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S16 — EASY — La maison de vacances
  ('3b3bddf9-b179-590d-a704-3c9fdea541b9', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S16', 'La maison de vacances',
   'Un ami vous écrit : « On hésite à louer cette maison pour cet été. Tu y es allé l''an dernier : elle est comment ? »',
   'Répondez-lui en décrivant la maison, en enchaînant vos informations dans un ordre lisible.',
   'Votre description suit un ordre que le lecteur peut suivre, et ne saute pas d''un détail à l''autre.',
   30, 60, NULL, 'EASY', 1,
   '["Choisissez un ordre", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'De l''extérieur…', 'du dehors vers le dedans : un ordre vaut mieux qu''aucun',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S17 — EASY — Le collègue à accueillir
  ('4cefd021-3aa7-5fa3-a1d9-9d69484207e2', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S17', 'Le collègue à accueillir',
   'Un membre de l''équipe vous écrit : « Tu as rencontré le nouveau hier. Il est comment ? Je voudrais savoir avant de le croiser. »',
   'Répondez-lui en décrivant ce collègue, en enchaînant vos informations dans un ordre lisible.',
   'Votre description suit un ordre lisible et se referme, au lieu d''accumuler des traits sans lien.',
   30, 60, NULL, 'EASY', 2,
   '["Choisissez un ordre", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est un homme d''une quarantaine d''années…', 'l''aspect d''abord, la manière d''être ensuite : le lecteur suit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S18 — MEDIUM — Le carnet perdu
  ('2f30588d-1dce-556e-b059-561661a5fd30', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S18', 'Le carnet perdu',
   'Le personnel de la bibliothèque vous écrit : « Bonjour, plusieurs carnets ont été oubliés cette semaine. Décrivez le vôtre. »',
   'Répondez-leur en décrivant ce carnet, en enchaînant vos informations dans un ordre lisible.',
   'Votre description suit un ordre lisible — de l''ensemble au détail — et se referme sans énumération sèche.',
   30, 60, NULL, 'MEDIUM', 3,
   '["Allez du grand au petit", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est un carnet…', 'l''ensemble d''abord, les détails ensuite : on ne fait pas l''inverse',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S19 — MEDIUM — L'atelier du quartier
  ('27ab7989-570a-5115-ba45-152a87e65651', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S19', 'L''atelier du quartier',
   'Une voisine vous écrit : « J''ai vu qu''un atelier partagé a ouvert rue Basse. Tu y es allé, je crois. Il est comment ? »',
   'Répondez-lui en décrivant cet atelier, en enchaînant vos informations dans un ordre lisible.',
   'Votre description suit un parcours que le lecteur peut suivre et se referme sans liste.',
   30, 60, NULL, 'MEDIUM', 4,
   '["Suivez un parcours", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'On entre par…', 'faites-la entrer avec vous : l''ordre vient tout seul',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S20 — MEDIUM — L'équipe du club
  ('24564798-d240-564e-8d3c-44eaedd0a367', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S20', 'L''équipe du club',
   'Un parent vous écrit : « Ma fille voudrait rejoindre le club. Tu connais l''équipe. Elle est comment ? »',
   'Répondez-lui en décrivant l''équipe, en enchaînant vos informations dans un ordre lisible.',
   'Votre description organise les informations sur le groupe et se referme, au lieu de les empiler.',
   30, 60, NULL, 'MEDIUM', 5,
   '["Groupez vos idées", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'L''équipe compte…', 'combien, qui, comment : trois temps, dans cet ordre',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S21 — MEDIUM — Le fauteuil de bureau
  ('13a6ac9a-221f-5b4a-9587-73027baa6774', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S21', 'Le fauteuil de bureau',
   'Un collègue vous écrit : « Tu revends ton fauteuil de bureau ? Il est comment ? Je cherche quelque chose de confortable. »',
   'Répondez-lui en décrivant le fauteuil, en enchaînant vos informations dans un ordre lisible.',
   'Votre description suit un ordre lisible et se referme, sans mélanger l''aspect, les réglages et l''état.',
   30, 60, NULL, 'MEDIUM', 6,
   '["Groupez vos idées", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est un fauteuil…', 'l''aspect, puis les réglages, puis l''état : ne mélangez pas',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S22 — HARD — La boutique reprise
  ('f028c2c4-8ccb-5ce8-bdce-9f3636899920', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S22', 'La boutique reprise',
   'Une amie vous écrit : « On dit que la librairie a rouvert autrement. Tu y es passée ? C''est comment maintenant ? »',
   'Répondez-lui en décrivant la boutique, en enchaînant vos informations dans un ordre lisible.',
   'Votre description suit un ordre lisible et relie ce qui a changé à ce qui est resté.',
   30, 60, NULL, 'HARD', 7,
   '["Séparez avant et après", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'La vitrine n''a pas bougé, mais…', 'ce qui reste, puis ce qui change : le lecteur se repère',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S23 — HARD — Le voisin de chambre d'hôpital
  ('c7951ce1-0fcf-511f-bf85-250bac66f117', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S23', 'Le voisin de chambre d''hôpital',
   'Votre tante vous écrit : « Je passe voir ton oncle demain. Tu m''as dit qu''il partageait la chambre. La personne à côté est comment ? »',
   'Répondez-lui en décrivant cette personne, en enchaînant vos informations dans un ordre lisible.',
   'Votre description organise l''aspect et la manière d''être, et se referme sans juger la personne.',
   30, 60, NULL, 'HARD', 8,
   '["Groupez vos idées", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est un monsieur âgé…', 'l''aspect, puis la manière d''être, puis une phrase qui referme',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S24 — HARD — La machine à café de l'étage
  ('fe53d5fc-9ee6-59b0-8d4e-1dcfa9e4358d', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S24', 'La machine à café de l''étage',
   'Un nouveau collègue vous écrit : « On m''a dit de me méfier de la machine à café du deuxième. Elle est comment ? »',
   'Répondez-lui en décrivant cette machine, en enchaînant vos informations dans un ordre lisible.',
   'Votre description suit un ordre lisible et relie l''aspect au fonctionnement, au lieu de les séparer.',
   30, 60, NULL, 'HARD', 9,
   '["Allez du visible à l''usage", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est une vieille machine…', 'ce qu''on voit, puis ce qu''elle fait : l''usage vient après l''aspect',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S25 — HARD — Le groupe de marche
  ('c11c2e34-66a7-5d84-b903-6e75a6bb46df', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S25', 'Le groupe de marche',
   'Une connaissance vous écrit : « Tu marches avec un groupe le dimanche, non ? Il est comment ? J''aimerais savoir avant de venir. »',
   'Répondez-lui en décrivant ce groupe, en enchaînant vos informations dans un ordre lisible.',
   'Votre description relie la composition du groupe à sa manière de fonctionner, au lieu de juxtaposer.',
   30, 60, NULL, 'HARD', 10,
   '["Reliez vos idées", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Nous sommes une douzaine…', 'reliez : qui compose le groupe explique comment il marche',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S26 — HARD — Le rez-de-chaussée à visiter
  ('dc7e0397-28d4-5c0b-ba7f-399b5f445027', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S26', 'Le rez-de-chaussée à visiter',
   'Votre sœur vous écrit : « Tu as visité la maison de la rue Pasteur pour moi. Raconte-moi le rez-de-chaussée. »',
   'Répondez-lui en décrivant le rez-de-chaussée, en enchaînant vos informations dans un ordre lisible.',
   'Votre description suit un parcours continu d''une pièce à l''autre et se referme.',
   30, 60, NULL, 'HARD', 11,
   '["Suivez un parcours", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'En entrant, on tombe sur…', 'avancez pièce par pièce, sans revenir en arrière',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S27 — HARD — Le violon d'occasion
  ('c2004014-8329-5a0a-901b-b70c1fa4f380', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S27', 'Le violon d''occasion',
   'Un professeur de musique vous écrit : « Vous vendez un violon, je crois. Décrivez-le-moi, je cherche pour une élève. »',
   'Répondez-lui en décrivant ce violon, en enchaînant vos informations dans un ordre lisible.',
   'Votre description va de l''instrument à ses accessoires puis à son état, sans mélanger les trois.',
   30, 60, NULL, 'HARD', 12,
   '["Groupez vos idées", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est un violon…', 'l''instrument, puis ce qui l''accompagne, puis l''état',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S28 — MEDIUM — Les gens du covoiturage
  ('312b55bb-cbf1-52a5-9f2d-da463d9f51da', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S28', 'Les gens du covoiturage',
   'Un collègue vous écrit : « Tu fais du covoiturage tous les jours. Les gens avec qui tu roules, ils sont comment ? »',
   'Répondez-lui en décrivant ce groupe, en enchaînant vos informations dans un ordre lisible.',
   'Votre description relie les personnes à la manière dont le trajet se passe, sans simple énumération.',
   30, 60, NULL, 'MEDIUM', 13,
   '["Reliez vos idées", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Nous sommes quatre…', 'qui ils sont explique comment le trajet se passe : montrez-le',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S29 — MEDIUM — Le chantier d'à côté
  ('e80a9ed8-63e4-579f-bc10-c9734c056e5f', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S29', 'Le chantier d''à côté',
   'Une amie qui veut acheter dans la rue vous écrit : « Il y a un chantier près de chez toi. Il est comment ? Je voudrais savoir ce qui se construit. »',
   'Répondez-lui en décrivant ce chantier, en enchaînant vos informations dans un ordre lisible.',
   'Votre description organise ce qu''on voit et où cela se trouve, et se referme sans commentaire d''opinion.',
   30, 60, NULL, 'MEDIUM', 14,
   '["Situez d''abord", "Décrivez ensuite", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Le chantier occupe…', 'd''abord où, ensuite quoi : sinon le lecteur cherche',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S30 — HARD — L'appareil ancien
  ('0a5e7b55-bfbe-56c1-86ee-ef42a10f6b96', 'f7c4bb25-2de0-5531-bda2-c1b865c13b25', 'EE', 'EE1-C8-S30', 'L''appareil ancien',
   'Un brocanteur vous écrit : « Bonjour, vous souhaitez vendre un appareil ancien. Décrivez-le-moi avant que je me déplace. »',
   'Répondez-lui en décrivant cet appareil, en enchaînant vos informations dans un ordre lisible.',
   'Votre description va de l''ensemble aux détails puis à l''état, sans revenir en arrière.',
   30, 60, NULL, 'HARD', 15,
   '["Allez du grand au petit", "Tenez cet ordre", "Refermez la description"]',
   '[{"label": "Ordre suivi", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'C''est un appareil photo…', 'un brocanteur suit votre ordre : ne le faites pas revenir en arrière',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S1 — EASY — Le train de six heures dix
  ('c8e5f66e-e9c2-542a-9fdc-a83e3cc26ef6', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S1', 'Le train de six heures dix',
   'Vous deviez être à Nantes à onze heures. Vous avez pris le train de six heures dix, alors qu''un autre partait à huit heures et arrivait à dix heures trente.',
   'Expliquez en deux phrases pourquoi vous avez choisi le train de six heures dix.',
   'La raison du choix est donnée, pas seulement le déroulement du voyage.',
   25, 55, NULL, 'EASY', 1,
   '["Dites pourquoi ce train", "Reliez la raison au choix", "Écrivez deux phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Un choix", "icon": "NUMBER"}]',
   'J''ai pris celui de six heures dix parce que…', 'raconter le trajet ne répond pas à la question : dites pourquoi ce train-là',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S2 — EASY — La machine s'est arrêtée
  ('783f6136-9a29-5873-b8ea-cffe6bb8cd4a', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S2', 'La machine s''est arrêtée',
   'Vous avez lancé une lessive et la machine s''est arrêtée au bout de dix minutes, le tambour plein d''eau.',
   'Expliquez en deux phrases pourquoi la machine s''est arrêtée.',
   'La cause de l''arrêt est donnée, pas seulement le constat de la panne.',
   25, 55, NULL, 'EASY', 2,
   '["Dites pourquoi elle s''est arrêtée", "Donnez une cause précise", "Écrivez deux phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Une cause", "icon": "NUMBER"}]',
   'Elle s''est arrêtée parce que…', 'décrire la panne n''est pas l''expliquer : dites ce qui l''a causée',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S3 — EASY — Le café refusé
  ('8376662f-0b1f-5f74-8892-1cf2d2bffa85', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S3', 'Le café refusé',
   'Un collègue vous a proposé un café à quinze heures et vous avez refusé, alors que vous en prenez un tous les matins.',
   'Expliquez en deux phrases pourquoi vous avez refusé ce café.',
   'La raison du refus est donnée, et elle rend la réaction compréhensible.',
   25, 55, NULL, 'EASY', 3,
   '["Dites pourquoi vous avez refusé", "Reliez la raison au refus", "Écrivez deux phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Une réaction", "icon": "NUMBER"}]',
   'J''ai refusé parce que…', 'un refus s''explique en une phrase : sinon, il paraît sec',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S4 — EASY — Les escaliers plutôt que l'ascenseur
  ('b20fa551-52e7-5a90-88b7-29124a455ac4', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S4', 'Les escaliers plutôt que l''ascenseur',
   'Au travail, vous montez toujours les quatre étages à pied, alors que l''ascenseur fonctionne très bien.',
   'Expliquez en deux phrases pourquoi vous prenez toujours les escaliers.',
   'La raison du choix est donnée, pas seulement l''habitude constatée.',
   25, 55, NULL, 'EASY', 4,
   '["Dites pourquoi les escaliers", "Donnez une raison claire", "Écrivez deux phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Un choix", "icon": "NUMBER"}]',
   'Je prends les escaliers parce que…', '« c''est mon habitude » ne dit pas pourquoi : cherchez la vraie raison',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S5 — EASY — Le rendez-vous annulé
  ('4dee591b-3e43-545b-8fdb-f4d6b41a699d', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S5', 'Le rendez-vous annulé',
   'Vous aviez rendez-vous chez le coiffeur samedi matin et vous l''avez annulé la veille au soir.',
   'Expliquez en deux phrases pourquoi vous avez annulé ce rendez-vous.',
   'La raison de l''annulation est donnée, pas seulement le fait d''avoir annulé.',
   25, 55, NULL, 'EASY', 5,
   '["Dites pourquoi vous avez annulé", "Donnez une raison précise", "Écrivez deux phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Une décision", "icon": "NUMBER"}]',
   'J''ai annulé parce que…', '« je ne pouvais pas venir » n''explique rien : dites ce qui vous en a empêché',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S6 — MEDIUM — L'appartement le plus cher
  ('6cc8f335-0e21-50a3-9d72-3883c732ba8c', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S6', 'L''appartement le plus cher',
   'Vous avez visité deux appartements de la même taille. Vous avez choisi celui qui coûte cent euros de plus par mois.',
   'Expliquez en trois phrases pourquoi vous avez choisi le plus cher.',
   'La raison du choix explique pourquoi le prix plus élevé a été accepté.',
   30, 65, NULL, 'MEDIUM', 6,
   '["Dites pourquoi celui-là", "Expliquez le prix accepté", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Choix coûteux", "icon": "NUMBER"}]',
   'J''ai choisi le plus cher parce que…', 'un choix qui coûte plus demande une raison qui pèse autant',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S7 — MEDIUM — La facture a doublé
  ('beed6da5-fb54-557d-ab44-2912b0de14d9', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S7', 'La facture a doublé',
   'Votre facture d''électricité de janvier est deux fois plus élevée que celle de novembre.',
   'Expliquez en trois phrases pourquoi cette facture a doublé.',
   'La cause de l''augmentation est expliquée, pas seulement constatée.',
   30, 65, NULL, 'MEDIUM', 7,
   '["Dites pourquoi elle a doublé", "Reliez la cause au montant", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Une cause", "icon": "NUMBER"}]',
   'Elle a doublé parce que…', 'comparer deux chiffres ne suffit pas : dites ce qui a changé entre les deux',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S8 — MEDIUM — Vous n'avez rien dit
  ('5131bfc8-9ab0-5fe1-aaf6-fd61559143af', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S8', 'Vous n''avez rien dit',
   'Un client s''est énervé à votre guichet devant toute la file. Vous l''avez laissé parler sans lui répondre.',
   'Expliquez en trois phrases pourquoi vous n''avez pas répondu.',
   'La raison du silence est donnée, et elle rend la réaction compréhensible.',
   30, 65, NULL, 'MEDIUM', 8,
   '["Dites pourquoi vous vous êtes tu", "Reliez la raison au silence", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Une réaction", "icon": "NUMBER"}]',
   'Je n''ai rien répondu parce que…', 'ne pas réagir est aussi une décision : expliquez-la',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S9 — MEDIUM — Les heures supplémentaires refusées
  ('1ea67799-baf5-5a15-af8c-e6dc1a61824c', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S9', 'Les heures supplémentaires refusées',
   'Votre responsable vous a proposé six heures supplémentaires par semaine, bien payées. Vous avez refusé.',
   'Expliquez en trois phrases pourquoi vous avez refusé ces heures.',
   'La raison du refus explique pourquoi l''argent n''a pas suffi à convaincre.',
   30, 65, NULL, 'MEDIUM', 9,
   '["Dites pourquoi vous avez refusé", "Montrez ce qui pesait plus", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Refus expliqué", "icon": "NUMBER"}]',
   'J''ai dit non parce que…', 'refuser de l''argent surprend : donnez la raison qui pèse plus lourd',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S10 — MEDIUM — Le colis reparti
  ('0cf14ffd-5532-5132-8ef1-fa34eac3fe96', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S10', 'Le colis reparti',
   'Vous attendiez un colis mardi après-midi. Le livreur est passé, puis il est reparti avec le colis.',
   'Expliquez en trois phrases pourquoi le colis est reparti.',
   'La cause du départ du livreur est expliquée, pas seulement le fait.',
   30, 65, NULL, 'MEDIUM', 10,
   '["Dites pourquoi il est reparti", "Donnez une cause précise", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Une cause", "icon": "NUMBER"}]',
   'Il est reparti avec parce que…', '« il n''a pas pu livrer » n''explique rien : dites ce qui l''en a empêché',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S11 — HARD — Vous l'avez remerciée
  ('1e998c4e-888e-5ea7-a3bf-9317c535b04d', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S11', 'Vous l''avez remerciée',
   'À la caisse du supermarché, une dame est passée devant vous sans un mot. Au moment de partir, vous l''avez remerciée.',
   'Expliquez en trois phrases pourquoi vous l''avez remerciée, alors qu''elle était passée devant vous.',
   'L''explication rend compréhensible une réaction qui, sans elle, paraît illogique.',
   30, 70, NULL, 'HARD', 11,
   '["Dites pourquoi ce remerciement", "Levez la contradiction", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Réaction surprenante", "icon": "TONE"}]',
   'Je l''ai remerciée parce que…', 'une réaction étonnante ne s''excuse pas : elle s''explique',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S12 — HARD — Le téléphone rendu
  ('f7e6046e-8e12-5043-ba24-5f5ed7f13e0d', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S12', 'Le téléphone rendu',
   'Votre beau-frère vous a offert un téléphone neuf pour votre anniversaire. Vous le lui avez rendu deux jours plus tard.',
   'Expliquez en trois phrases pourquoi vous l''avez rendu, sans que votre beau-frère se sente visé.',
   'La raison du refus du cadeau est donnée et elle ne met pas la personne en cause.',
   30, 70, NULL, 'HARD', 12,
   '["Dites pourquoi vous l''avez rendu", "Ne mettez personne en cause", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Sans blesser", "icon": "TONE"}]',
   'Je le lui ai rendu parce que…', 'expliquer un refus, ce n''est pas reprocher : parlez de vous',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S13 — HARD — Ce n'était pas la pluie
  ('f776ace3-e26e-5625-9c64-9bb00ce0e1db', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S13', 'Ce n''était pas la pluie',
   'Le match de votre fils a été annulé samedi. Tout le monde a cru que c''était à cause de la pluie, mais ce n''était pas la raison.',
   'Expliquez en trois phrases pourquoi le match a été annulé, en écartant la raison que tout le monde imagine.',
   'La vraie cause est donnée et la cause supposée est explicitement écartée.',
   30, 70, NULL, 'HARD', 13,
   '["Écartez la cause supposée", "Donnez la vraie cause", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Cause écartée", "icon": "NUMBER"}]',
   'Ce n''est pas la pluie qui…', 'écarter une fausse cause rend la vraie beaucoup plus claire',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S14 — HARD — Vous avez ri
  ('fff9183b-f562-5294-9b55-1040b2a5e2c5', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S14', 'Vous avez ri',
   'Pendant une réunion, une collègue a annoncé une nouvelle difficile pour le service. Vous avez éclaté de rire.',
   'Expliquez en trois phrases pourquoi vous avez ri à ce moment-là.',
   'L''explication rend compréhensible un rire qui, sans elle, paraît déplacé.',
   30, 70, NULL, 'HARD', 14,
   '["Dites pourquoi vous avez ri", "Levez le malentendu", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Réaction surprenante", "icon": "TONE"}]',
   'J''ai ri parce que…', 'ce qui paraît déplacé a souvent une raison simple : donnez-la',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S15 — HARD — Le retour au travail avancé
  ('558e163c-6446-5d49-81a1-4b551e7f0539', '09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2-C9-S15', 'Le retour au travail avancé',
   'Votre arrêt de travail courait encore dix jours. Vous êtes revenu travailler avant la fin, avec l''accord du médecin.',
   'Expliquez en trois phrases pourquoi vous êtes revenu plus tôt que prévu.',
   'La raison du retour anticipé est donnée et elle ne se réduit pas à l''ennui.',
   30, 70, NULL, 'HARD', 15,
   '["Dites pourquoi ce retour", "Donnez une raison solide", "Écrivez trois phrases"]',
   '[{"label": "Le pourquoi", "icon": "STRUCTURE"}, {"label": "Choix inattendu", "icon": "NUMBER"}]',
   'Je suis revenu plus tôt parce que…', '« je m''ennuyais » est un peu court : cherchez ce qui a vraiment pesé',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S16 — EASY — Le nouveau square du quartier
  ('efe9e382-92b7-5d0d-87f1-015db7bb2658', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S16', 'Le nouveau square du quartier',
   'Le journal de quartier interroge ses lecteurs : « Le square Lamartine a rouvert après six mois de travaux. Qu''en pensez-vous ? »',
   'Donnez votre avis sur ce square, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur ce square est identifiable dès la première phrase, sans qu''il faille le deviner.',
   40, 90, NULL, 'EASY', 1,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur ce square"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce square est…', 'le lecteur doit connaître votre avis avant la deuxième phrase',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S17 — EASY — La nouvelle machine de la laverie
  ('b8089520-9d1d-5658-80ac-d778404d6b96', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S17', 'La nouvelle machine de la laverie',
   'Le gérant de la laverie affiche un cahier : « Nous avons remplacé la grande machine du fond. Dites-nous ce que vous pensez de celle-ci. »',
   'Donnez votre avis sur cette machine, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur cette machine est identifiable dès la première phrase, pas seulement à la fin.',
   40, 90, NULL, 'EASY', 2,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur la machine"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Cette nouvelle machine est…', 'commencez par votre avis, les raisons viennent après',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S18 — MEDIUM — Le gardien de l'immeuble
  ('37f49d41-4e87-5ddb-a4ed-e5cd87b92555', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S18', 'Le gardien de l''immeuble',
   'Le conseil syndical écrit aux copropriétaires : « Monsieur Sarr termine sa première année à la loge. Nous recueillons votre avis sur son travail. »',
   'Donnez votre avis sur ce gardien, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur cette personne est identifiable dès la première phrase, sans détour.',
   40, 90, NULL, 'MEDIUM', 3,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur lui"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Monsieur Sarr fait…', 'on doit savoir si vous êtes satisfait avant les exemples',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S19 — MEDIUM — L'équipe de la médiathèque
  ('150bcbe3-bb0a-55c6-9c77-3f49000121f2', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S19', 'L''équipe de la médiathèque',
   'La médiathèque affiche un questionnaire : « Que pensez-vous de l''équipe qui vous accueille ? Votre retour nous aide à nous améliorer. »',
   'Donnez votre avis sur cette équipe, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur ce groupe est identifiable dès la première phrase, sans qu''on ait à le déduire.',
   40, 90, NULL, 'MEDIUM', 4,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur l''équipe"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'L''équipe de la médiathèque est…', 'votre avis d''abord, les exemples ensuite',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S20 — MEDIUM — Le banc devant la boulangerie
  ('43ba3f06-0be5-5ac4-b824-782262f558f9', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S20', 'Le banc devant la boulangerie',
   'La mairie consulte les habitants : « Un banc a été installé devant la boulangerie de la place. Donnez-nous votre avis. »',
   'Donnez votre avis sur ce banc, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur cet objet est identifiable dès la première phrase, et porte sur lui.',
   40, 90, NULL, 'MEDIUM', 5,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur ce banc"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce banc est…', 'un banc, pas les bancs : restez sur celui de la place',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S21 — MEDIUM — La nouvelle boulangère
  ('a76001d0-59bd-5771-ad76-b75d4cda0d7e', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S21', 'La nouvelle boulangère',
   'Un voisin vous écrit : « La boulangerie a changé de main. Vous y allez tous les jours, je crois. Que pensez-vous de la nouvelle boulangère ? »',
   'Donnez votre avis sur cette personne, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur cette personne est identifiable dès la première phrase, et ne se confond pas avec un avis sur le pain.',
   40, 90, NULL, 'MEDIUM', 6,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur elle"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'La nouvelle boulangère est…', 'il demande la personne, pas les produits',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S22 — MEDIUM — La halle du marché
  ('893f5d28-938d-55a3-a82f-ae5fbf68d4ca', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S22', 'La halle du marché',
   'Un site d''avis vous propose : « Vous connaissez la halle couverte de la place Verte. Laissez votre avis aux futurs visiteurs. »',
   'Donnez votre avis sur cette halle, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur ce lieu est identifiable dès la première phrase, sans se réduire à un inventaire.',
   40, 90, NULL, 'MEDIUM', 7,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur la halle"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette halle vaut…', 'un avis n''est pas une liste de stands',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S23 — MEDIUM — Le fauteuil hérité
  ('91242cf7-a35e-5e78-a060-74132025937b', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S23', 'Le fauteuil hérité',
   'Votre cousine vous écrit : « Tante Suzanne veut nous donner son vieux fauteuil vert. Tu l''as vu chez elle. Tu en penses quoi ? »',
   'Donnez votre avis sur ce fauteuil, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur cet objet est identifiable dès la première phrase, et porte sur lui, pas sur la personne qui le donne.',
   40, 90, NULL, 'MEDIUM', 8,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur le fauteuil"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce fauteuil est…', 'l''avis porte sur le fauteuil, pas sur tante Suzanne',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S24 — HARD — Le groupe de bénévoles
  ('969a7465-3898-5e1e-bc07-110f4b545a78', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S24', 'Le groupe de bénévoles',
   'La responsable de l''association vous écrit : « Vous avez travaillé avec l''équipe de bénévoles du samedi. Qu''en pensez-vous ? »',
   'Donnez votre avis sur ce groupe, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur ce groupe est identifiable dès la première phrase et ne se transforme pas en compte rendu d''activité.',
   40, 90, NULL, 'HARD', 9,
   '["Dites ce que vous pensez", "Placez-le au début", "Pas un compte rendu"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe du samedi est…', 'on vous demande un avis, pas le récit de la journée',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S25 — HARD — Le vélo en libre-service du coin
  ('bad9d7bc-85bf-5d4a-8035-73df0a3d874a', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S25', 'Le vélo en libre-service du coin',
   'Un site de la ville demande : « Une station de vélos a été installée devant la poste. Que pensez-vous des vélos qui s''y trouvent ? »',
   'Donnez votre avis sur ces vélos, en le rendant identifiable dès les premiers mots.',
   'Votre avis porte sur les vélos eux-mêmes et se lit dès la première phrase.',
   40, 90, NULL, 'HARD', 10,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur les vélos"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ces vélos sont…', 'l''avis porte sur les vélos, pas sur la circulation en ville',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S26 — HARD — La salle d'attente refaite
  ('4ceaf0b8-c52f-5a46-bd19-127de9cf0e9f', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S26', 'La salle d''attente refaite',
   'Votre cabinet médical affiche : « Nous avons réaménagé la salle d''attente. Dites-nous ce que vous en pensez. »',
   'Donnez votre avis sur cette salle, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur ce lieu est identifiable dès la première phrase et ne dérive pas vers l''organisation des rendez-vous.',
   40, 90, NULL, 'HARD', 11,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur la salle"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette salle est…', 'la salle, pas les délais de rendez-vous',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S27 — HARD — Le professeur de musique
  ('41ba636d-9478-5666-bdc3-0c8ce2d3c1d2', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S27', 'Le professeur de musique',
   'L''école de musique vous écrit : « Votre fils termine son année avec Monsieur Perez. Nous aimerions votre avis sur son enseignement. »',
   'Donnez votre avis sur ce professeur, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur cette personne est identifiable dès la première phrase et ne se limite pas aux progrès de votre fils.',
   40, 90, NULL, 'HARD', 12,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur lui"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Monsieur Perez est…', 'les progrès de votre fils sont une preuve, pas le sujet',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S28 — HARD — Les voisins du dessus
  ('fbb10e53-6f0f-574d-8895-78517c45c5f2', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S28', 'Les voisins du dessus',
   'Une amie qui visite l''appartement au-dessous du vôtre vous écrit : « Tu connais les gens du troisième ? Ils sont comment, à ton avis ? »',
   'Donnez votre avis sur ces voisins, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur ce groupe est identifiable dès la première phrase et repose sur ce que vous avez vécu.',
   40, 90, NULL, 'HARD', 13,
   '["Dites ce que vous pensez", "Placez-le au début", "Appuyez sur du vécu"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Les voisins du troisième sont…', 'un avis se soutient par ce que vous avez vu, pas par ce qu''on dit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S29 — MEDIUM — La table de la salle commune
  ('ff28502f-3d67-507b-8dae-c5bc2dedc8dd', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S29', 'La table de la salle commune',
   'Le conseil de la résidence écrit : « La grande table de la salle commune a été remplacée. Merci de nous donner votre avis sur celle-ci. »',
   'Donnez votre avis sur cette table, en le rendant identifiable dès les premiers mots.',
   'Votre avis porte sur cette table et se lit dès la première phrase, sans glisser vers l''usage de la salle.',
   40, 90, NULL, 'MEDIUM', 14,
   '["Dites ce que vous pensez", "Placez-le au début", "Restez sur la table"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Cette table est…', 'la table, pas les réunions qu''on y tient',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S30 — HARD — Le chemin le long de la rivière
  ('b0c3a515-6cac-5fab-8799-99d03caa98e8', '78182a36-43b8-5257-b8f2-4730bb504d93', 'EE', 'EE3-C1-S30', 'Le chemin le long de la rivière',
   'Un office de tourisme vous écrit : « Vous avez emprunté le chemin de halage entre les deux ponts. Votre avis nous intéresse. »',
   'Donnez votre avis sur ce chemin, en le rendant identifiable dès les premiers mots.',
   'Votre avis sur ce lieu est identifiable dès la première phrase et ne se réduit pas au récit de votre promenade.',
   40, 90, NULL, 'HARD', 15,
   '["Dites ce que vous pensez", "Placez-le au début", "Pas le récit"]',
   '[{"label": "Position nette", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce chemin est…', 'un avis n''est pas le récit de votre après-midi',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S16 — EASY — La cour de l'école
  ('7ad52ac2-904b-58f8-9dbd-e5f68a189899', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S16', 'La cour de l''école',
   'Un parent d''élève vous écrit : « Tu trouves que la cour de l''école est un bon endroit pour les enfants. Pourquoi exactement ? »',
   'Donnez votre avis sur cette cour et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur la cour elle-même et soutient réellement votre avis.',
   40, 90, NULL, 'EASY', 1,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la à la cour"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette cour est bien conçue parce que…', 'une raison doit expliquer votre avis, pas l''accompagner',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S17 — EASY — Le four de la cuisine partagée
  ('6b420d3e-935f-5177-8d47-5626e926cd45', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S17', 'Le four de la cuisine partagée',
   'Une colocataire vous écrit : « Tu dis que le four est le meilleur appareil de la cuisine. Pourquoi lui plutôt qu''un autre ? »',
   'Donnez votre avis sur ce four et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur le four lui-même et soutient l''avis annoncé.',
   40, 90, NULL, 'EASY', 2,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la au four"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce four est le meilleur appareil parce qu''…', 'la raison doit venir du four, pas de votre façon de cuisiner',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S18 — MEDIUM — Le pharmacien du coin
  ('e1a6f738-ac76-5697-9bc9-c338104158cd', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S18', 'Le pharmacien du coin',
   'Une voisine vous écrit : « Vous dites toujours du bien du pharmacien de la rue Blanche. Qu''est-ce qui le rend si différent ? »',
   'Donnez votre avis sur ce pharmacien et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur cette personne et sa manière de travailler, pas sur la pharmacie ni sur ses prix.',
   40, 90, NULL, 'MEDIUM', 3,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la à lui"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Ce pharmacien est remarquable parce qu''…', 'la raison doit venir de lui, pas du magasin',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S19 — MEDIUM — L'équipe du service après-vente
  ('fd6b18eb-74bb-5a8d-add5-77f32e9a97e1', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S19', 'L''équipe du service après-vente',
   'Un collègue vous écrit : « Tu trouves que l''équipe du service après-vente travaille bien. Qu''est-ce qui te fait dire ça ? »',
   'Donnez votre avis sur cette équipe et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur la façon de travailler de cette équipe, pas sur les produits ni sur l''entreprise.',
   40, 90, NULL, 'MEDIUM', 4,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la à l''équipe"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe travaille bien parce qu''…', 'la raison doit décrire ce que l''équipe fait, pas ce qu''elle vend',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S20 — MEDIUM — Le marché couvert du samedi
  ('5b0e5849-3bc6-547d-b053-15874e408322', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S20', 'Le marché couvert du samedi',
   'Une amie vous écrit : « Tu préfères le marché couvert au supermarché. Donne-moi une vraie raison, je n''y vais jamais. »',
   'Donnez votre avis sur ce marché et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur ce marché et soutient votre avis, sans se réduire à une préférence personnelle.',
   40, 90, NULL, 'MEDIUM', 5,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la au marché"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce marché vaut mieux parce qu''…', '« j''aime bien » n''est pas une raison : dites ce qui s''y passe',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S21 — MEDIUM — Le siège auto d'occasion
  ('b7624f52-e3cc-5e71-bfe2-ebe5ab8e579f', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S21', 'Le siège auto d''occasion',
   'Votre sœur vous écrit : « Tu déconseilles ce siège auto d''occasion. Pourquoi ? Il a l''air en très bon état. »',
   'Donnez votre avis sur ce siège et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur ce siège précis et soutient votre avis.',
   40, 90, NULL, 'MEDIUM', 6,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la au siège"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Je déconseille ce siège parce que…', 'une raison visible sur l''objet vaut mieux qu''un principe général',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S22 — HARD — La classe de votre fille
  ('de4d2b95-dec5-5fbd-a0cb-e7c5f4a63402', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S22', 'La classe de votre fille',
   'Un parent vous écrit : « Tu sembles très content de la classe de ta fille cette année. Qu''est-ce qui fait la différence ? »',
   'Donnez votre avis sur ce groupe d''élèves et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur le groupe d''élèves, et non sur l''enseignante ni sur les programmes.',
   40, 90, NULL, 'HARD', 7,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la aux élèves"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette classe est…', 'on vous demande la classe : la maîtresse n''est pas le groupe',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S23 — HARD — L'ancien pont de pierre
  ('3e3c8be7-3dfd-51cd-bd5c-e11b2726a213', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S23', 'L''ancien pont de pierre',
   'Un journal local demande : « Beaucoup d''habitants tiennent au vieux pont de pierre. Et vous, qu''en pensez-vous, et pour quelle raison ? »',
   'Donnez votre avis sur ce pont et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur ce pont et soutient votre avis, sans devenir un discours sur le patrimoine.',
   40, 90, NULL, 'HARD', 8,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la au pont"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce pont mérite…', 'restez sur ce pont : le patrimoine en général n''est pas le sujet',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S24 — MEDIUM — La perceuse prêtée
  ('81e1cfc7-9d8f-5e88-a0f6-e4cff1cfd24d', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S24', 'La perceuse prêtée',
   'Un voisin vous écrit : « Tu m''as dit que ta perceuse n''était pas adaptée à mon projet. Pourquoi, au juste ? »',
   'Donnez votre avis sur cet outil et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur la perceuse elle-même, pas sur votre expérience de bricolage.',
   40, 90, NULL, 'MEDIUM', 9,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la à l''outil"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Cette perceuse ne conviendra pas parce qu''…', 'dites ce que l''outil ne peut pas faire, pas ce que vous savez faire',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S25 — MEDIUM — Le kinésithérapeute
  ('df78ea32-10f0-571d-80be-23add7e3e187', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S25', 'Le kinésithérapeute',
   'Votre père vous écrit : « Tu me recommandes ce kinésithérapeute plutôt qu''un autre. Explique-moi pourquoi. »',
   'Donnez votre avis sur cette personne et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur cette personne et sa pratique, pas sur le cabinet ni sur les délais.',
   40, 90, NULL, 'MEDIUM', 10,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la à lui"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Je te le recommande parce qu''…', 'un cabinet bien situé n''est pas une raison sur le praticien',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S26 — HARD — Le local des associations
  ('cd2b5a48-68f7-503f-b0da-8f2a9d720874', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S26', 'Le local des associations',
   'La mairie consulte : « Que pensez-vous du local associatif de la rue Jean-Moulin ? Merci d''appuyer votre avis sur une raison précise. »',
   'Donnez votre avis sur ce local et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur le local et soutient l''avis, sans devenir une demande de moyens.',
   40, 90, NULL, 'HARD', 11,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la au local"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce local est…', 'un avis n''est pas une demande de subvention',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S27 — MEDIUM — Le portail automatique
  ('e975598f-0b69-5464-a26a-91accc449cb7', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S27', 'Le portail automatique',
   'Le syndic vous écrit : « Vous avez émis un avis sur le nouveau portail automatique. Pouvez-vous préciser sur quoi il repose ? »',
   'Donnez votre avis sur ce portail et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur le portail lui-même et non sur l''entreprise qui l''a posé.',
   40, 90, NULL, 'MEDIUM', 12,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la au portail"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce portail est…', 'l''entreprise n''est pas le portail : restez sur l''objet',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S28 — HARD — Le groupe de discussion des parents
  ('55eca851-ce2f-55aa-a0a1-a44468eeeea7', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S28', 'Le groupe de discussion des parents',
   'Une mère vous écrit : « Tu as quitté le groupe de discussion des parents. Tu peux me dire pourquoi ? »',
   'Donnez votre avis sur ce groupe et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur le fonctionnement du groupe, sans viser une personne en particulier.',
   40, 90, NULL, 'HARD', 13,
   '["Donnez votre avis", "Ajoutez une raison", "Visez le groupe"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'J''ai quitté ce groupe parce qu''…', 'une raison sur le groupe, pas sur une personne nommée',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S29 — HARD — La cantine de l'entreprise
  ('34b60772-db65-570c-9420-0af846821e84', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S29', 'La cantine de l''entreprise',
   'Le comité vous écrit : « Vous avez donné un avis négatif sur la cantine. Merci de préciser la raison principale. »',
   'Donnez votre avis sur cette cantine et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur la cantine comme lieu, et non sur le prix des repas ni sur la direction.',
   40, 90, NULL, 'HARD', 14,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la au lieu"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette cantine est…', 'le lieu, pas la politique tarifaire de l''entreprise',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S30 — MEDIUM — Le nouvel arrêt de tramway
  ('f45c6e1e-fb1d-57da-8671-f06ada14238f', '2930c13d-ce25-54af-b0c6-e602f326fa16', 'EE', 'EE3-C2-S30', 'Le nouvel arrêt de tramway',
   'Un site de la ville demande : « L''arrêt Jean-Jaurès a été déplacé de cent mètres. Que pensez-vous du nouvel emplacement ? »',
   'Donnez votre avis sur ce nouvel arrêt et appuyez-le sur une raison qui s''y rapporte directement.',
   'Votre raison porte sur cet emplacement précis et soutient votre avis.',
   40, 90, NULL, 'MEDIUM', 15,
   '["Donnez votre avis", "Ajoutez une raison", "Reliez-la à l''arrêt"]',
   '[{"label": "Raison liée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce nouvel emplacement est…', 'cet arrêt-ci : cent mètres suffisent à tout changer',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S16 — EASY — La piscine municipale
  ('8c0fab25-6ccf-57a7-8693-971884562996', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S16', 'La piscine municipale',
   'Un site d''avis vous écrit : « Vous avez noté la piscine municipale. Développez en quelques lignes ce qui explique votre note. »',
   'Donnez votre avis sur cette piscine et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée : on comprend par quel enchaînement elle soutient votre avis.',
   40, 90, NULL, 'EASY', 1,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette piscine est…', 'une raison posée puis abandonnée ne développe rien',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S17 — EASY — Le lave-linge partagé
  ('54f29ca1-d4d8-52f7-b40f-f2b6ef08a86f', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S17', 'Le lave-linge partagé',
   'Votre colocataire vous écrit : « Tu dis que ce lave-linge est un bon choix pour une colocation. Développe un peu. »',
   'Donnez votre avis sur cet appareil et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée : on comprend par quel enchaînement elle soutient votre avis.',
   40, 90, NULL, 'EASY', 2,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce lave-linge convient bien parce qu''…', 'expliquez le chemin entre la raison et l''avis',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S18 — MEDIUM — La coiffeuse du quartier
  ('011a4b0e-e5a3-51f8-bb89-ec54b6180c68', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S18', 'La coiffeuse du quartier',
   'Une voisine vous écrit : « Vous recommandez cette coiffeuse à tout le monde. Expliquez-moi vraiment pourquoi. »',
   'Donnez votre avis sur cette personne et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée : on comprend l''enchaînement entre sa manière de travailler et votre avis.',
   40, 90, NULL, 'MEDIUM', 3,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Je la recommande parce qu''…', 'une qualité citée n''est pas une qualité démontrée',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S19 — MEDIUM — L'équipe de nuit de l'hôtel
  ('9f1c0a82-579b-5032-a005-9ada499f914f', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S19', 'L''équipe de nuit de l''hôtel',
   'Un site d''avis vous écrit : « Vous avez souligné la qualité de l''équipe de nuit. Développez ce qui justifie ce jugement. »',
   'Donnez votre avis sur cette équipe et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée : on comprend comment le comportement du groupe soutient votre avis.',
   40, 90, NULL, 'MEDIUM', 4,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe de nuit est…', 'montrez comment leur façon de faire produit le résultat',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S20 — MEDIUM — Le parking souterrain
  ('cad16a73-8267-5448-9903-d11a09ed4138', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S20', 'Le parking souterrain',
   'La ville consulte : « Que pensez-vous du parking souterrain de la place ? Merci de développer votre réponse. »',
   'Donnez votre avis sur ce parking et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à son effet, et porte sur ce parking.',
   40, 90, NULL, 'MEDIUM', 5,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce parking est…', 'un défaut mérite d''être expliqué autant qu''une qualité',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S21 — MEDIUM — Le réfrigérateur de la salle de pause
  ('01c43eca-aafc-51df-8cef-ac1ec44064da', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S21', 'Le réfrigérateur de la salle de pause',
   'Le comité vous écrit : « Vous avez commenté le nouveau réfrigérateur de la salle de pause. Développez ce que vous en pensez. »',
   'Donnez votre avis sur cet appareil et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à son effet sur l''usage quotidien.',
   40, 90, NULL, 'MEDIUM', 6,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce réfrigérateur est…', 'l''effet sur l''usage vaut mieux qu''une caractéristique de plus',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S22 — HARD — Le professeur remplaçant
  ('5c753bd2-0a55-5d22-818e-19f7a623b732', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S22', 'Le professeur remplaçant',
   'L''établissement vous écrit : « Vous avez apprécié le travail du professeur remplaçant. Développez ce qui vous fait dire cela. »',
   'Donnez votre avis sur cette personne et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à un effet observable, sans se limiter aux résultats de votre enfant.',
   40, 90, NULL, 'HARD', 7,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Ce remplaçant a fait…', 'la note de votre enfant est un effet, pas une explication',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S23 — HARD — L'association de quartier
  ('1594cf55-e96b-56e7-b109-d60669f9c14b', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S23', 'L''association de quartier',
   'La mairie vous écrit : « Vous avez un avis favorable sur l''association du quartier Nord. Développez ce qui le fonde. »',
   'Donnez votre avis sur ce groupe et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à un effet visible, sans se réduire à une liste d''activités.',
   40, 90, NULL, 'HARD', 8,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette association est…', 'la liste des activités ne dit pas pourquoi elle fonctionne',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S24 — MEDIUM — Le jardin partagé de la résidence
  ('90288940-9a57-5ce9-ae10-97f3dd115463', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S24', 'Le jardin partagé de la résidence',
   'Le bailleur vous écrit : « Vous avez donné un avis sur le jardin partagé. Merci de développer votre réponse. »',
   'Donnez votre avis sur ce jardin et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à son effet, et porte sur ce jardin.',
   40, 90, NULL, 'MEDIUM', 9,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce jardin est…', 'montrez ce que sa configuration produit, pas ce qu''il contient',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S25 — HARD — Le nouvel abri à vélos
  ('31884a6e-5527-5faf-8e95-5fa0136c2417', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S25', 'Le nouvel abri à vélos',
   'Le syndic vous écrit : « Vous avez commenté le nouvel abri à vélos. Développez votre avis, nous transmettrons au conseil. »',
   'Donnez votre avis sur cet abri et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à son effet sur l''usage, et porte sur cet abri.',
   40, 90, NULL, 'HARD', 10,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Cet abri est…', 'un détail de conception peut suffire, s''il est mené jusqu''au bout',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S26 — HARD — La bibliothécaire du secteur jeunesse
  ('38b825d4-797c-5ad6-9870-55fd3d90ca08', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S26', 'La bibliothécaire du secteur jeunesse',
   'La médiathèque vous écrit : « Vous avez souligné le travail de la responsable jeunesse. Développez ce qui justifie votre avis. »',
   'Donnez votre avis sur cette personne et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à son effet sur les enfants, sans se limiter à des qualités générales.',
   40, 90, NULL, 'HARD', 11,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Cette bibliothécaire est…', 'montrez ce qu''elle fait, puis ce que cela produit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S27 — MEDIUM — Le groupe de randonnée
  ('8bff745f-ff08-5648-ae99-28fdbb820166', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S27', 'Le groupe de randonnée',
   'Une connaissance vous écrit : « Tu dis que ce groupe de randonnée est bien organisé. Développe, j''hésite à m''inscrire. »',
   'Donnez votre avis sur ce groupe et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à son effet sur les marcheurs, et porte sur ce groupe.',
   40, 90, NULL, 'MEDIUM', 12,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Ce groupe est bien organisé parce qu''…', 'une règle du groupe se juge à ce qu''elle évite',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S28 — HARD — La gare routière
  ('9a3aa9a9-f48c-5d2b-adac-04e0fb6d7f40', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S28', 'La gare routière',
   'Un site de voyage vous écrit : « Vous avez donné une note basse à la gare routière. Développez ce qui l''explique. »',
   'Donnez votre avis sur ce lieu et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à son effet sur les voyageurs, et porte sur ce lieu.',
   40, 90, NULL, 'HARD', 13,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette gare routière est…', 'un seul défaut bien mené convainc plus que huit cités',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S29 — HARD — Le tableau blanc interactif
  ('05a8daf6-ef56-5941-b460-b45c6358c857', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S29', 'Le tableau blanc interactif',
   'L''école vous écrit : « Vous avez commenté le tableau interactif de la classe. Merci de développer votre avis. »',
   'Donnez votre avis sur cet équipement et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à son effet sur les élèves, et porte sur cet objet.',
   40, 90, NULL, 'HARD', 14,
   '["Donnez une raison", "Expliquez comment", "Allez à l''effet"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce tableau est…', 'l''effet sur les élèves est le bout de l''argument',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S30 — MEDIUM — Le voisin qui arrose les plantes
  ('4304cc2d-0ca3-537f-98ac-70ec7534ee9e', '50bbf456-9de7-5620-aa31-5cba27bfac70', 'EE', 'EE3-C3-S30', 'Le voisin qui arrose les plantes',
   'Une amie vous écrit : « Tu dis que ton voisin est quelqu''un sur qui on peut compter. Développe, je cherche quelqu''un pour cet été. »',
   'Donnez votre avis sur cette personne et développez une raison jusqu''à son effet concret.',
   'Votre raison est développée jusqu''à un fait vérifiable, sans se limiter à une impression.',
   40, 90, NULL, 'MEDIUM', 15,
   '["Donnez une raison", "Expliquez comment", "Allez au fait"]',
   '[{"label": "Raison développée", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'On peut compter sur lui parce qu''…', '« il est sérieux » ne prouve rien : montrez comment cela se voit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S16 — EASY — Le café du bas de l'immeuble
  ('80c4adc9-46ce-5d81-8269-102a1cf557e9', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S16', 'Le café du bas de l''immeuble',
   'Le conseil de quartier vous écrit : « Le café du 14 rue Basse risque de fermer. Vous le fréquentez : donnez-nous votre avis sur ce commerce. »',
   'Donnez votre avis sur ce café et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est une situation précise vécue dans ce café, pas une généralité sur les cafés.',
   40, 90, NULL, 'EASY', 1,
   '["Donnez votre avis", "Racontez un cas", "Restez sur ce café"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce café compte vraiment ici. Un jour…', 'un cas précis vaut mieux qu''une vérité sur les cafés',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S17 — EASY — Le robot de cuisine
  ('b0ca0390-85f6-5e3b-b816-a718658a0d1a', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S17', 'Le robot de cuisine',
   'Votre sœur vous écrit : « Tu dis que ce robot t''a changé la vie. Donne-moi un exemple, je ne vois pas bien. »',
   'Donnez votre avis sur cet appareil et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est une situation précise avec cet appareil, pas une affirmation sur ses qualités.',
   40, 90, NULL, 'EASY', 2,
   '["Donnez votre avis", "Racontez un cas", "Restez sur l''appareil"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce robot m''a vraiment changé la vie. Mardi dernier…', '« il fait gagner du temps » n''est pas un exemple',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S18 — MEDIUM — Le facteur du secteur
  ('6f3d129d-9c7b-5d79-9f2e-d123c192f5ad', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S18', 'Le facteur du secteur',
   'La poste vous écrit : « Nous recueillons l''avis des habitants sur leur facteur. Merci d''illustrer votre réponse. »',
   'Donnez votre avis sur cette personne et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est une situation précise avec cette personne, pas une liste de qualités.',
   40, 90, NULL, 'MEDIUM', 3,
   '["Donnez votre avis", "Racontez un cas", "Restez sur lui"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Notre facteur est remarquable. La semaine dernière…', 'une anecdote réelle prouve ce que dix adjectifs affirment',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S19 — MEDIUM — L'équipe des urgences
  ('afc77bf9-3c8e-57f4-bb88-79c3ed6a8d8b', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S19', 'L''équipe des urgences',
   'L''hôpital vous écrit : « Vous avez été reçu aux urgences le mois dernier. Donnez-nous votre avis sur l''équipe, en l''illustrant. »',
   'Donnez votre avis sur cette équipe et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est un moment précis vécu avec cette équipe, pas un jugement sur l''hôpital.',
   40, 90, NULL, 'MEDIUM', 4,
   '["Donnez votre avis", "Racontez un moment", "Restez sur l''équipe"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe a été remarquable. Vers deux heures du matin…', 'un moment précis, avec une heure et un geste',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S20 — MEDIUM — La salle de sport du quartier
  ('bf9a2b40-0332-5c1d-823f-6f05cc5503b3', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S20', 'La salle de sport du quartier',
   'Un ami vous écrit : « Tu dis que cette salle est différente des grandes chaînes. Donne-moi un exemple concret. »',
   'Donnez votre avis sur cette salle et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est une scène précise dans cette salle, pas une comparaison abstraite.',
   40, 90, NULL, 'MEDIUM', 5,
   '["Donnez votre avis", "Racontez un cas", "Restez sur la salle"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette salle est vraiment différente. Le mois dernier…', 'montrez une scène, pas une comparaison de principes',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S21 — MEDIUM — Le manteau acheté d'occasion
  ('cb4fac48-803e-557e-b4ce-cdf4c72b1dec', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S21', 'Le manteau acheté d''occasion',
   'Une amie vous écrit : « Tu défends ce manteau d''occasion, mais il a cinq ans. Donne-moi un exemple qui le prouve. »',
   'Donnez votre avis sur ce vêtement et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est une situation précise vécue avec ce vêtement, pas un principe sur la seconde main.',
   40, 90, NULL, 'MEDIUM', 6,
   '["Donnez votre avis", "Racontez un cas", "Restez sur ce manteau"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce manteau est excellent. En février…', 'un principe sur l''occasion n''illustre pas ce manteau-là',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S22 — HARD — La conseillère de l'agence d'emploi
  ('6375fa17-1961-55ce-aeb5-733de691707b', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S22', 'La conseillère de l''agence d''emploi',
   'L''agence vous écrit : « Vous avez été suivi par Madame Colin. Merci de donner votre avis, en l''illustrant par un fait précis. »',
   'Donnez votre avis sur cette personne et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est un fait précis de votre propre suivi, et non un jugement sur l''accompagnement dans son ensemble.',
   40, 90, NULL, 'HARD', 7,
   '["Donnez votre avis", "Racontez un fait", "Restez sur elle"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Madame Colin m''a beaucoup aidé. Au troisième rendez-vous…', 'l''accompagnement pour tous n''est pas votre accompagnement à vous',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S23 — HARD — Le groupe de parole
  ('1957f5a2-91cc-51e6-b4cf-8d197101a7b4', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S23', 'Le groupe de parole',
   'L''association vous écrit : « Vous participez au groupe du jeudi. Merci de nous donner votre avis, illustré par un moment vécu. »',
   'Donnez votre avis sur ce groupe et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est un moment précis du groupe, sans nommer les personnes ni raconter leur histoire.',
   40, 90, NULL, 'HARD', 8,
   '["Donnez votre avis", "Racontez un moment", "Ne nommez personne"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Ce groupe fonctionne vraiment. Un jeudi…', 'illustrez le fonctionnement du groupe, pas le cas d''une personne',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S24 — MEDIUM — Le lavoir restauré
  ('e089927e-c359-5824-9f3e-a0a1d4553923', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S24', 'Le lavoir restauré',
   'La commune vous écrit : « Le lavoir du chemin des Prés a été restauré l''an dernier. Donnez-nous votre avis, avec un exemple. »',
   'Donnez votre avis sur ce lieu et illustrez-le par un exemple précis que vous avez vécu ou observé.',
   'Votre exemple est une scène précise qui s''est déroulée à cet endroit.',
   40, 90, NULL, 'MEDIUM', 9,
   '["Donnez votre avis", "Racontez une scène", "Restez sur le lavoir"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette restauration est réussie. Dimanche dernier…', 'une scène qui s''y est passée, pas une réflexion sur le patrimoine',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S25 — MEDIUM — Le voisin bricoleur
  ('093ba14c-d0e9-5512-93b0-5afbe379b858', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S25', 'Le voisin bricoleur',
   'Une amie vous écrit : « Tu dis toujours du bien de ton voisin du premier. Donne-moi un exemple, ça m''aiderait à comprendre. »',
   'Donnez votre avis sur cette personne et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est un fait précis, avec un moment et un geste, pas une série de qualités.',
   40, 90, NULL, 'MEDIUM', 10,
   '["Donnez votre avis", "Racontez un fait", "Restez sur lui"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Mon voisin du premier est quelqu''un de rare. Un soir…', 'un geste daté prouve plus que trois qualités nommées',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S26 — HARD — L'équipe de la crèche
  ('4232e29d-1c51-5f0e-95ea-48ac4c8942da', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S26', 'L''équipe de la crèche',
   'La crèche vous écrit : « Merci de nous donner votre avis sur l''équipe, en l''illustrant par une situation vécue. »',
   'Donnez votre avis sur cette équipe et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est une situation précise vécue avec l''équipe, pas un avis sur les crèches.',
   40, 90, NULL, 'HARD', 11,
   '["Donnez votre avis", "Racontez un cas", "Restez sur l''équipe"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe est excellente. En septembre…', 'ce qui s''est passé avec votre enfant, pas ce que font les crèches',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S27 — MEDIUM — La médiathèque le samedi
  ('88b9fb5c-c902-5dee-b956-032445b20dcf', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S27', 'La médiathèque le samedi',
   'Un site d''avis vous écrit : « Vous fréquentez la médiathèque le samedi. Donnez votre avis sur ce lieu, avec un exemple. »',
   'Donnez votre avis sur ce lieu et illustrez-le par un exemple précis que vous avez vécu ou observé.',
   'Votre exemple est une scène précise dans cette médiathèque, pas un avis sur la lecture.',
   40, 90, NULL, 'MEDIUM', 12,
   '["Donnez votre avis", "Racontez une scène", "Restez sur le lieu"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette médiathèque est un lieu précieux. Samedi dernier…', 'une scène, avec des gens et une heure',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S28 — HARD — Le vélo pliant
  ('37d7bb41-b253-596c-9479-6015dcfb432c', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S28', 'Le vélo pliant',
   'Un collègue vous écrit : « Tu dis que ton vélo pliant a résolu ton problème de trajet. Donne-moi un exemple. »',
   'Donnez votre avis sur cet objet et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est une situation précise vécue avec cet objet, pas une réflexion sur les transports.',
   40, 90, NULL, 'HARD', 13,
   '["Donnez votre avis", "Racontez un cas", "Restez sur le vélo"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce vélo a résolu mon problème. Un lundi…', 'les transports en général ne sont pas votre trajet',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S29 — HARD — Le médecin de garde
  ('034a4165-6b2d-5e87-97e4-06c8f658aa22', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S29', 'Le médecin de garde',
   'La maison médicale vous écrit : « Vous avez consulté un dimanche. Merci de donner votre avis sur le praticien, avec un exemple. »',
   'Donnez votre avis sur cette personne et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est un moment précis de la consultation, pas un avis sur la médecine de garde.',
   40, 90, NULL, 'HARD', 14,
   '["Donnez votre avis", "Racontez un moment", "Restez sur lui"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Ce médecin a été très bon. Pendant la consultation…', 'un geste de la consultation, pas un avis sur le système',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S30 — HARD — Le club de lecture
  ('7b01eaa0-01e8-510d-ac0a-929cf8d6bdfa', '4e7ce6cc-403f-5f70-98bb-393cc625e608', 'EE', 'EE3-C4-S30', 'Le club de lecture',
   'La bibliothèque vous écrit : « Vous participez au club de lecture. Merci de nous donner votre avis sur le groupe, illustré. »',
   'Donnez votre avis sur ce groupe et illustrez-le par un exemple précis que vous avez vécu.',
   'Votre exemple est une séance précise du groupe, pas une réflexion sur les bienfaits de la lecture.',
   40, 90, NULL, 'HARD', 15,
   '["Donnez votre avis", "Racontez une séance", "Restez sur le groupe"]',
   '[{"label": "Exemple vécu", "icon": "EXAMPLE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Ce club est très vivant. À la séance de mars…', 'une séance précise, avec ce qui s''y est dit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S16 — EASY — Le parc du bord de l'eau
  ('e348d0be-c85f-5d43-aa7a-71669371bdde', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S16', 'Le parc du bord de l''eau',
   'Un site de la ville vous écrit : « Vous avez commencé votre avis sur le parc en parlant de son calme. Poursuivez votre réponse. »',
   'Donnez votre avis sur ce parc en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte quelque chose de nouveau sur ce parc : aucune ne redit la précédente autrement.',
   40, 90, NULL, 'EASY', 1,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce parc est un endroit très calme…', 'reformuler n''est pas avancer : passez à autre chose',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S17 — EASY — L'aspirateur sans fil
  ('09e2836a-88c9-5f47-8782-801c50d55f85', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S17', 'L''aspirateur sans fil',
   'Votre frère vous écrit : « Tu as commencé à me dire du bien de ton aspirateur. Continue, je veux comprendre. »',
   'Donnez votre avis sur cet appareil en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cet appareil, sans reformuler la précédente.',
   40, 90, NULL, 'EASY', 2,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Cet aspirateur est très pratique…', '« pratique », « commode », « facile » sont le même mot',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S18 — MEDIUM — La maîtresse de CE1
  ('6c74cd98-f776-55c3-a3ee-c98f74209ec5', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S18', 'La maîtresse de CE1',
   'Un parent vous écrit : « Tu as commencé à me parler de la maîtresse de CE1. Continue, je voudrais en savoir plus. »',
   'Donnez votre avis sur cette personne en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cette personne, sans reformuler la précédente.',
   40, 90, NULL, 'MEDIUM', 3,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Cette maîtresse est très bien…', 'patiente, calme, douce : trois mots pour une seule idée',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S19 — MEDIUM — L'équipe du chantier
  ('edc39a2c-925f-5263-845b-70442b13b728', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S19', 'L''équipe du chantier',
   'Un voisin vous écrit : « Tu as commencé à parler de l''équipe qui a refait ta salle de bains. Continue. »',
   'Donnez votre avis sur cette équipe en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cette équipe, sans reformuler la précédente.',
   40, 90, NULL, 'MEDIUM', 4,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe a été très sérieuse…', 'sérieux, professionnel, rigoureux : une seule idée',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S20 — MEDIUM — Le camping au bord du lac
  ('5f92abb3-064b-5411-8f86-23ce5051bb96', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S20', 'Le camping au bord du lac',
   'Un site de voyage vous écrit : « Vous avez commencé votre avis sur ce camping. Poursuivez, votre retour aidera les visiteurs. »',
   'Donnez votre avis sur ce camping en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur ce lieu, sans reformuler la précédente.',
   40, 90, NULL, 'MEDIUM', 5,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce camping est une bonne adresse…', 'un avis qui tourne en rond n''aide personne à choisir',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S21 — MEDIUM — Le matelas acheté en ligne
  ('e8b25f6b-465e-5916-9985-798d7d175334', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S21', 'Le matelas acheté en ligne',
   'Une amie vous écrit : « Tu as commencé à me parler de ton matelas. Continue, j''hésite à commander le même. »',
   'Donnez votre avis sur cet objet en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cet objet, sans reformuler la précédente.',
   40, 90, NULL, 'MEDIUM', 6,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce matelas est un bon achat…', 'confortable dit trois fois reste une seule information',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S22 — HARD — Le kiné du centre
  ('d7292682-4774-5b86-935c-4a139b9e9c87', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S22', 'Le kiné du centre',
   'Votre voisin vous écrit : « Tu as commencé à me parler de ce kiné. Continue, je dois choisir cette semaine. »',
   'Donnez votre avis sur cette personne en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cette personne, sans reformuler la précédente.',
   40, 90, NULL, 'HARD', 7,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Ce kiné est très bon…', 'trois qualités voisines n''en font qu''une seule',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S23 — HARD — Les habitants de l'allée
  ('02e3beae-25e3-57d4-b0b3-f5197c380d36', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S23', 'Les habitants de l''allée',
   'Un futur voisin vous écrit : « Tu as commencé à me décrire les gens de l''allée. Continue, ça m''intéresse beaucoup. »',
   'Donnez votre avis sur ce groupe en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur ce groupe, sans reformuler la précédente.',
   40, 90, NULL, 'HARD', 8,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Les gens de l''allée sont très bien…', 'sympa, gentil, agréable, aimable : un seul mot',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S24 — HARD — La halle aux grains
  ('c6c57b0a-9654-5d42-b841-ea4790917cf7', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S24', 'La halle aux grains',
   'L''office du tourisme vous écrit : « Vous avez commencé un avis sur la halle aux grains. Poursuivez, nous le publierons. »',
   'Donnez votre avis sur ce lieu en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur ce lieu, sans reformuler la précédente.',
   40, 90, NULL, 'HARD', 9,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'La halle aux grains mérite le détour…', 'beau, magnifique, superbe, splendide : une seule idée',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S25 — MEDIUM — Le sèche-linge de la buanderie
  ('fd422e0f-4820-5668-87d5-cc8f9b788bb5', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S25', 'Le sèche-linge de la buanderie',
   'La résidence vous écrit : « Vous avez commencé un avis sur le sèche-linge commun. Merci de poursuivre. »',
   'Donnez votre avis sur cet appareil en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cet appareil, sans reformuler la précédente.',
   40, 90, NULL, 'MEDIUM', 10,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce sèche-linge est décevant…', 'un défaut répété reste un seul défaut',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S26 — HARD — Le gérant de la supérette
  ('64789f7e-8a90-5aea-a860-eb3ca078c027', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S26', 'Le gérant de la supérette',
   'Un site d''avis vous écrit : « Vous avez commencé un avis sur le gérant de cette supérette. Poursuivez votre réponse. »',
   'Donnez votre avis sur cette personne en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cette personne, sans reformuler la précédente.',
   40, 90, NULL, 'HARD', 11,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Ce gérant tient très bien son magasin…', 'chaque phrase doit apprendre quelque chose de neuf',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S27 — MEDIUM — L'atelier théâtre
  ('a3dc8151-d024-5d60-b0f0-a52871076ca1', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S27', 'L''atelier théâtre',
   'La maison de quartier vous écrit : « Vous avez commencé un avis sur le groupe de l''atelier théâtre. Merci de poursuivre. »',
   'Donnez votre avis sur ce groupe en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur ce groupe, sans reformuler la précédente.',
   40, 90, NULL, 'MEDIUM', 12,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Ce groupe est très accueillant…', 'accueillant, ouvert, chaleureux : gardez-en un seul',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S28 — HARD — Le sentier du plateau
  ('a1b2241c-be3b-5a3a-bfcd-274eba147c4c', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S28', 'Le sentier du plateau',
   'Un club de randonnée vous écrit : « Vous avez commencé un avis sur le sentier du plateau. Poursuivez pour nos adhérents. »',
   'Donnez votre avis sur ce sentier en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur ce sentier, sans reformuler la précédente.',
   40, 90, NULL, 'HARD', 13,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce sentier est exigeant…', 'dur, difficile, éprouvant, costaud : un seul mot suffit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S29 — MEDIUM — La cafetière du bureau
  ('bfff318c-19c2-5e04-8175-b7cc093a8ee1', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S29', 'La cafetière du bureau',
   'Le comité vous écrit : « Vous avez commencé un avis sur la nouvelle cafetière. Merci de développer votre réponse. »',
   'Donnez votre avis sur cet objet en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cet objet, sans reformuler la précédente.',
   40, 90, NULL, 'MEDIUM', 14,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Cette cafetière est un bon choix…', 'bon, bien, réussi, satisfaisant : la même chose',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S30 — HARD — L'entraîneur de l'équipe de jeunes
  ('284e22e8-7a28-542e-a121-b756c2e8b711', '8dfda25f-5808-5e9f-ba3e-bb3970ddf134', 'EE', 'EE3-C5-S30', 'L''entraîneur de l''équipe de jeunes',
   'Le club vous écrit : « Vous avez commencé un avis sur l''entraîneur des moins de treize ans. Poursuivez, s''il vous plaît. »',
   'Donnez votre avis sur cette personne en faisant avancer votre propos, sans revenir sur ce qui est déjà dit.',
   'Chaque phrase apporte une idée nouvelle sur cette personne, sans reformuler la précédente.',
   40, 90, NULL, 'HARD', 15,
   '["Posez votre avis", "Changez d''idée", "Ne redites rien"]',
   '[{"label": "Idée nouvelle", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Cet entraîneur est excellent…', 'excellent dit de cinq façons reste une seule information',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S1 — EASY — Le même avis, à votre sœur
  ('6d1e7071-6125-528d-a284-e0279349587d', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S1', 'Le même avis, à votre sœur',
   'Votre sœur vous écrit : « Alors, il est comment ce resto où tu es allée hier soir ? Raconte ! »',
   'Donnez votre avis sur ce restaurant, dans le registre qui convient à votre sœur.',
   'Votre avis est exprimé sur un ton familier naturel, sans formule administrative ni distance.',
   40, 90, NULL, 'EASY', 1,
   '["Donnez votre avis", "Tutoyez simplement", "Pas de formule"]',
   '[{"label": "Registre familier", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Franchement, on a bien mangé…', 'à une sœur, on écrit comme on parle',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S2 — EASY — Le même avis, à la mairie
  ('e7656b98-0545-5909-bed7-1879c15c7833', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S2', 'Le même avis, à la mairie',
   'La mairie vous écrit : « Madame, Monsieur, vous avez fréquenté la salle municipale le mois dernier. Merci de nous transmettre votre avis. »',
   'Donnez votre avis sur cette salle, dans le registre qui convient à un service municipal.',
   'Votre avis est exprimé sur un ton clair et vouvoyé qui convient à une administration, sans familiarité.',
   40, 90, NULL, 'EASY', 2,
   '["Donnez votre avis", "Vouvoyez", "Restez clair"]',
   '[{"label": "Registre formel", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Madame, Monsieur, cette salle nous a…', 'clair et vouvoyé suffit : pas besoin de formules compliquées',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S3 — MEDIUM — Le voisin qu'on connaît peu
  ('5d42eb8c-cae3-59f5-85a8-e90cd2e04fe7', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S3', 'Le voisin qu''on connaît peu',
   'Un voisin du quatrième glisse un mot sous votre porte : « Bonjour, vous avez fait appel à ce plombier je crois. Qu''en avez-vous pensé ? »',
   'Donnez votre avis sur cet artisan, dans le registre qui convient à un voisin peu connu.',
   'Votre avis est exprimé sur un ton poli et vouvoyé, ni familier ni cérémonieux.',
   40, 90, NULL, 'MEDIUM', 3,
   '["Donnez votre avis", "Vouvoyez simplement", "Restez cordial"]',
   '[{"label": "Registre poli", "icon": "TONE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Bonjour, oui, nous l''avons fait venir…', 'il vous vouvoie dans son mot : répondez sur le même pied',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S4 — MEDIUM — L'avis publié sur un site
  ('c86a9424-5612-5bc3-aac5-14e009353c26', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S4', 'L''avis publié sur un site',
   'Un site d''avis vous écrit : « Votre commentaire sera lu par des inconnus qui hésitent à réserver ce camping. Rédigez-le. »',
   'Donnez votre avis sur ce camping, dans le registre qui convient à des lecteurs inconnus.',
   'Votre avis est exprimé sur un ton clair et neutre, compréhensible par un lecteur qui ne vous connaît pas.',
   40, 90, NULL, 'MEDIUM', 4,
   '["Donnez votre avis", "Restez neutre", "Pensez aux inconnus"]',
   '[{"label": "Registre neutre", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Séjour de cinq nuits en août…', 'des inconnus vous lisent : pas d''allusion, pas de sous-entendu',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S5 — HARD — L'avis donné à un enfant
  ('0a8b180e-6419-51c6-8b66-371e8196ea0e', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S5', 'L''avis donné à un enfant',
   'Votre nièce de huit ans vous écrit : « Tonton, tu as vu mon vélo neuf ? Il est bien ? Dis-moi la vérité ! »',
   'Donnez votre avis sur ce vélo, dans le registre qui convient à une enfant de huit ans.',
   'Votre avis est exprimé dans des mots simples et un ton adapté à une enfant, sans condescendance.',
   40, 90, NULL, 'HARD', 5,
   '["Donnez votre avis", "Mots simples", "Ne la rabaissez pas"]',
   '[{"label": "Registre adapté", "icon": "TONE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Oui, je l''ai vu, et je le trouve…', 'simple ne veut pas dire bébête : elle a huit ans, pas trois',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S6 — HARD — Un avis à un supérieur
  ('a2b19181-4dec-5daa-9203-f5f484383eb2', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S6', 'Un avis à un supérieur',
   'Votre directrice vous écrit : « Vous avez testé le nouveau logiciel avant son déploiement. J''aimerais votre avis avant la réunion de jeudi. »',
   'Donnez votre avis sur cet outil, dans le registre qui convient à une directrice.',
   'Votre avis est exprimé sur un ton professionnel, franc mais mesuré, sans familiarité ni flatterie.',
   40, 90, NULL, 'HARD', 6,
   '["Donnez votre avis", "Restez professionnel", "Ni flatterie ni familiarité"]',
   '[{"label": "Registre professionnel", "icon": "TONE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Bonjour, voici mon retour après trois semaines d''essai…', 'un désaccord se dit aussi, calmement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S7 — MEDIUM — Un avis au groupe de la classe
  ('2a829c82-50ff-5af1-9373-5f143b100dc3', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S7', 'Un avis au groupe de la classe',
   'Sur le groupe des parents d''élèves, quelqu''un demande : « Certains ont essayé le centre de loisirs du mercredi. Vos retours ? »',
   'Donnez votre avis sur cette équipe d''animateurs, dans le registre qui convient à un groupe de parents.',
   'Votre avis est exprimé sur un ton cordial de groupe, sans familiarité excessive ni distance.',
   40, 90, NULL, 'MEDIUM', 7,
   '["Donnez votre avis", "Restez cordial", "Pensez à tout le groupe"]',
   '[{"label": "Registre cordial", "icon": "TONE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Bonjour à tous, nous y allons depuis septembre…', 'un groupe se salue, et personne n''y est votre intime',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S8 — HARD — Un avis à un ancien professeur
  ('24eed41d-9cc6-50e2-8703-c63027ebc687', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S8', 'Un avis à un ancien professeur',
   'Votre ancienne professeure, que vous avez toujours vouvoyée, vous écrit : « Vous avez suivi la visite guidée dont je vous avais parlé. Que pensez-vous de la conférencière ? »',
   'Donnez votre avis sur cette personne, dans le registre qui convient à cette relation.',
   'Votre avis garde le vouvoiement établi, sur un ton chaleureux et sans raideur.',
   40, 90, NULL, 'HARD', 8,
   '["Donnez votre avis", "Gardez le vouvoiement", "Restez chaleureux"]',
   '[{"label": "Registre respectueux", "icon": "TONE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Bonjour Madame, j''ai suivi sa visite samedi…', 'vous l''avez toujours vouvoyée : gardez cet usage, sans froideur',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S9 — HARD — Un avis dans un cadre officiel
  ('1225841e-2b62-5068-b97e-a5924042f43b', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S9', 'Un avis dans un cadre officiel',
   'La préfecture vous écrit : « Madame, dans le cadre de l''enquête publique sur l''aménagement du square Dubois, vous pouvez déposer votre avis. »',
   'Donnez votre avis sur ce square, dans le registre qui convient à une enquête publique.',
   'Votre avis est exprimé sur un ton formel et argumenté, sans plainte ni familiarité.',
   40, 90, NULL, 'HARD', 9,
   '["Donnez votre avis", "Restez formel", "Argumentez"]',
   '[{"label": "Registre formel", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Madame, Monsieur, je souhaite formuler un avis favorable…', 'une enquête publique se lit : la colère y pèse moins qu''un fait',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S10 — HARD — Un avis à quelqu'un qu'on ménage
  ('2d4c695a-1713-54da-86d6-f02c250484e4', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S10', 'Un avis à quelqu''un qu''on ménage',
   'Votre belle-mère, que vous avez toujours vouvoyée, vous écrit : « J''ai choisi ce fauteuil pour votre salon. Il vous plaît vraiment ? Dites-moi franchement. »',
   'Donnez votre avis sur ce fauteuil, dans le registre qui convient à cette relation.',
   'Votre avis est exprimé avec franchise et ménagement à la fois, en gardant le vouvoiement établi.',
   40, 90, NULL, 'HARD', 10,
   '["Donnez votre avis", "Restez franc", "Gardez le vouvoiement"]',
   '[{"label": "Franchise ménagée", "icon": "TONE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Merci beaucoup, il est arrivé hier…', 'franc ne veut pas dire brutal, ménager ne veut pas dire mentir',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S11 — MEDIUM — Un avis à un inconnu qui demande
  ('1b6afc3a-33d0-5db6-8142-75268ed578fd', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S11', 'Un avis à un inconnu qui demande',
   'Une personne vous aborde sur un forum de quartier : « Bonjour, je viens d''emménager. Les commerçants du marché du mardi sont comment ? »',
   'Donnez votre avis sur ces commerçants, dans le registre qui convient à un inconnu du quartier.',
   'Votre avis est exprimé sur un ton accueillant et vouvoyé, compréhensible par quelqu''un qui ne connaît personne ici.',
   40, 90, NULL, 'MEDIUM', 11,
   '["Donnez votre avis", "Vouvoyez", "Pensez au nouveau venu"]',
   '[{"label": "Registre accueillant", "icon": "TONE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Bonjour et bienvenue !…', 'il ne connaît personne : évitez les prénoms que vous seul situez',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S12 — HARD — Un avis écrit sous le coup de l'agacement
  ('d9de56ca-ad99-52cf-871e-231c2136ddb8', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S12', 'Un avis écrit sous le coup de l''agacement',
   'Le syndic vous écrit : « Madame, vous avez signalé un problème avec l''entreprise de nettoyage. Merci de nous transmettre votre avis par écrit. »',
   'Donnez votre avis sur cette équipe de nettoyage, dans le registre qui convient à un syndic.',
   'Votre avis critique est exprimé sur un ton mesuré et vouvoyé, sans agressivité.',
   40, 90, NULL, 'HARD', 12,
   '["Donnez votre avis", "Restez mesuré", "Pas d''agressivité"]',
   '[{"label": "Registre mesuré", "icon": "TONE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Madame, Monsieur, mon avis sur cette équipe est réservé…', 'un reproche mesuré se lit ; un reproche crié se classe',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S13 — HARD — Un avis à un ami qui a fait le choix
  ('b3895052-d0b0-5b7a-8e58-9baeca7a0b55', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S13', 'Un avis à un ami qui a fait le choix',
   'Un ami vous écrit : « J''ai enfin acheté la voiture dont je t''avais parlé. Tu la trouves comment, franchement ? »',
   'Donnez votre avis sur cet objet, dans le registre qui convient à un ami qui a déjà acheté.',
   'Votre avis est exprimé sur un ton amical et honnête, sans complaisance ni jugement blessant.',
   40, 90, NULL, 'HARD', 13,
   '["Donnez votre avis", "Restez honnête", "Ne blessez pas"]',
   '[{"label": "Franchise amicale", "icon": "TONE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Je l''ai vue hier soir…', 'il a déjà acheté : la franchise ne sert plus à le faire changer d''avis',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S14 — HARD — Un avis en tant que représentant
  ('10b994a8-831e-5ab6-9f42-08ea13e00d19', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S14', 'Un avis en tant que représentant',
   'La direction vous écrit : « Vous parlez au nom de l''équipe. Quel est l''avis collectif sur les nouveaux bureaux ? »',
   'Donnez l''avis de l''équipe sur ce lieu, dans le registre qui convient quand on parle pour d''autres.',
   'Votre avis est exprimé au nom du groupe, sur un ton mesuré, sans se confondre avec votre avis personnel.',
   40, 90, NULL, 'HARD', 14,
   '["Parlez au nom du groupe", "Restez mesuré", "Pas votre avis seul"]',
   '[{"label": "Registre collectif", "icon": "TONE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Bonjour, voici l''avis recueilli auprès de l''équipe…', 'vous parlez pour douze personnes : « je » n''est pas la bonne place',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S15 — HARD — Un avis à quelqu'un qui décide
  ('dfd36fe8-9f69-5225-b8ca-bf94b741d9d5', 'a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3-C9-S15', 'Un avis à quelqu''un qui décide',
   'La responsable du recrutement vous écrit : « Vous avez travaillé avec ce candidat. Votre avis pèsera dans la décision. »',
   'Donnez votre avis sur cette personne, dans le registre qui convient quand votre parole engage.',
   'Votre avis est exprimé sur un ton professionnel et prudent, sans emballement ni sous-entendu.',
   40, 90, NULL, 'HARD', 15,
   '["Donnez votre avis", "Restez professionnel", "Pas de sous-entendu"]',
   '[{"label": "Registre engageant", "icon": "TONE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Bonjour, j''ai travaillé six mois avec lui…', 'votre parole engage quelqu''un : ni emballement, ni allusion',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S16 — EASY — La bibliothèque du quartier
  ('0c27c9b6-255b-5487-a61f-8401ac94c0a6', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S16', 'La bibliothèque du quartier',
   'Un site d''avis vous écrit : « Vous recommandez cette bibliothèque. Certains lui reprochent ses horaires. Quel est votre avis complet ? »',
   'Donnez votre avis sur cette bibliothèque, en reconnaissant ce qui lui est reproché sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'EASY', 1,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette bibliothèque est un vrai atout…', 'reconnaître un défaut ne veut pas dire changer d''avis',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S17 — EASY — Le téléphone reconditionné
  ('ec9b7221-c7e2-5977-b1f3-3ac02d996ebe', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S17', 'Le téléphone reconditionné',
   'Un ami vous écrit : « Tu défends ton téléphone reconditionné, mais on dit que la batterie tient mal. Ton avis complet ? »',
   'Donnez votre avis sur cet appareil, en reconnaissant ce qui lui est reproché sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'EASY', 2,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce téléphone est un très bon achat…', 'une concession sincère renforce l''avis au lieu de l''affaiblir',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S18 — MEDIUM — Le coach sportif
  ('edeaff78-eb68-594b-a0c0-79f92aa86ef4', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S18', 'Le coach sportif',
   'Une amie vous écrit : « Tu es content de ce coach, mais on m''a dit qu''il était très exigeant. Qu''en penses-tu vraiment ? »',
   'Donnez votre avis sur cette personne, en reconnaissant ce qui lui est reproché sans changer de position.',
   'Vous reconnaissez une limite réelle chez cette personne et votre position reste la même à la fin.',
   40, 90, NULL, 'MEDIUM', 3,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Ce coach est excellent…', 'on peut reconnaître un défaut sans l''excuser ni s''y rendre',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S19 — MEDIUM — L'équipe du restaurant associatif
  ('167752eb-1a1f-5e22-a78c-b7d33403edd4', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S19', 'L''équipe du restaurant associatif',
   'La mairie vous écrit : « Vous soutenez cette équipe. Des usagers trouvent l''accueil brusque. Quel est votre avis complet ? »',
   'Donnez votre avis sur cette équipe, en reconnaissant ce qui lui est reproché sans changer de position.',
   'Vous reconnaissez une limite réelle du groupe et votre position reste la même à la fin.',
   40, 90, NULL, 'MEDIUM', 4,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe fait un travail essentiel…', 'reconnaître un reproche n''oblige pas à l''endosser entièrement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S20 — MEDIUM — Le camping en pleine nature
  ('59d5d273-7015-52b1-9fe2-4cb9e289ed11', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S20', 'Le camping en pleine nature',
   'Un site de voyage vous écrit : « Vous avez noté ce camping très favorablement, mais plusieurs avis parlent du manque de confort. Développez. »',
   'Donnez votre avis sur ce camping, en reconnaissant ce qui lui est reproché sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'MEDIUM', 5,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce camping est un endroit rare…', 'une limite peut même devenir la raison d''aimer le lieu',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S21 — MEDIUM — Le manteau de pluie
  ('6aa23cad-fe3f-544e-a6e1-0da7f1d4fcd3', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S21', 'Le manteau de pluie',
   'Votre sœur vous écrit : « Tu adores ce manteau, mais tu m''as dit qu''il était lourd. Alors, tu le recommandes ou pas ? »',
   'Donnez votre avis sur ce vêtement, en reconnaissant sa limite sans changer de position.',
   'Vous reconnaissez une limite réelle de l''objet et votre position reste la même à la fin.',
   40, 90, NULL, 'MEDIUM', 6,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Je le recommande vraiment…', 'on peut recommander quelque chose sans le trouver parfait',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S22 — HARD — Le médecin qui ne prend pas de rendez-vous
  ('aacc409f-e7c3-5d53-973b-b6b23234bcaa', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S22', 'Le médecin qui ne prend pas de rendez-vous',
   'Une voisine vous écrit : « Vous conseillez ce médecin, mais il ne prend pas de rendez-vous. Ce n''est pas un problème ? »',
   'Donnez votre avis sur cette personne, en reconnaissant cette limite sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'HARD', 7,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Je le conseille sans hésiter…', 'un inconvénient réel peut avoir une contrepartie réelle',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S23 — MEDIUM — Le groupe de course du dimanche
  ('3c353f7c-cf9d-535f-93c7-83055fe04a4e', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S23', 'Le groupe de course du dimanche',
   'Un ami vous écrit : « Tu veux que je rejoigne ce groupe, mais tu dis qu''ils partent tôt. Ça vaut le coup ou pas ? »',
   'Donnez votre avis sur ce groupe, en reconnaissant cette limite sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'MEDIUM', 8,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Ce groupe vaut vraiment le coup…', 'reconnaître l''inconvénient, puis dire ce qu''il achète',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S24 — HARD — La salle de concert en sous-sol
  ('7748002a-bfac-55da-aada-414b2ea1c2a9', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S24', 'La salle de concert en sous-sol',
   'Un site d''avis vous écrit : « Vous défendez cette salle, mais son accès est réputé difficile. Donnez votre avis complet. »',
   'Donnez votre avis sur ce lieu, en reconnaissant cette limite sans changer de position.',
   'Vous reconnaissez une limite réelle du lieu et votre position reste la même à la fin.',
   40, 90, NULL, 'HARD', 9,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette salle est la meilleure de la ville…', 'certaines limites ne se compensent pas : dites-le quand même',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S25 — MEDIUM — Le vélo électrique
  ('27ed707b-7e56-5496-bac1-eee9d3033a6f', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S25', 'Le vélo électrique',
   'Un collègue vous écrit : « Tu es content de ton vélo électrique, mais il paraît qu''il est très lourd à porter. Ton avis ? »',
   'Donnez votre avis sur cet objet, en reconnaissant cette limite sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'MEDIUM', 10,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce vélo a changé mes trajets…', 'une limite chiffrée pèse moins qu''une limite vague',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S26 — HARD — La responsable de l'agence
  ('7c627567-c965-513f-a7c8-4480326b74cc', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S26', 'La responsable de l''agence',
   'Un ami vous écrit : « Tu dis du bien de cette responsable, mais on la dit difficile à joindre. Tu maintiens ? »',
   'Donnez votre avis sur cette personne, en reconnaissant cette limite sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'HARD', 11,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Je maintiens tout à fait…', 'maintenir ne veut pas dire nier ce qu''on vous oppose',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S27 — MEDIUM — L'équipe de la ressourcerie
  ('4864a4a8-4d3a-5076-9de0-20aa519affaa', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S27', 'L''équipe de la ressourcerie',
   'La commune vous écrit : « Vous soutenez cette équipe. Certains trouvent l''organisation brouillonne. Quel est votre avis ? »',
   'Donnez votre avis sur ce groupe, en reconnaissant ce qui lui est reproché sans changer de position.',
   'Vous reconnaissez une limite réelle du groupe et votre position reste la même à la fin.',
   40, 90, NULL, 'MEDIUM', 12,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe mérite d''être soutenue…', 'un défaut d''organisation n''efface pas un résultat',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S28 — HARD — Le sentier côtier
  ('e540ed23-0644-5b0a-ae0e-37bf2d95a9e5', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S28', 'Le sentier côtier',
   'Un club vous écrit : « Vous recommandez ce sentier, mais il est exposé au vent et sans ombre. Votre avis complet ? »',
   'Donnez votre avis sur ce sentier, en reconnaissant cette limite sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'HARD', 13,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce sentier est à faire absolument…', 'une limite peut se contourner par le choix du moment',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S29 — HARD — La table en bois brut
  ('539773f4-4a92-54ff-aaa4-7a361ea55e72', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S29', 'La table en bois brut',
   'Une amie vous écrit : « Tu adores ta table, mais tu m''as dit qu''elle marquait. Je la prends ou pas ? »',
   'Donnez votre avis sur cet objet, en reconnaissant cette limite sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'HARD', 14,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Je la reprendrais sans hésiter…', 'dire à qui la limite poserait problème est plus utile que la nier',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S30 — HARD — Le bénévole de l'atelier vélo
  ('b1e9ac7c-84bb-53b9-9c32-b85861416295', '16b70979-21b7-53f8-91a7-70a20bd385ec', 'EE', 'EE3-C7-S30', 'Le bénévole de l''atelier vélo',
   'Un voisin vous écrit : « Tu conseilles d''aller le voir pour réparer un vélo, mais il paraît qu''il ne fait rien à ta place. C''est vrai ? »',
   'Donnez votre avis sur cette personne, en reconnaissant cette limite sans changer de position.',
   'Vous reconnaissez une limite réelle et votre position reste la même à la fin.',
   40, 90, NULL, 'HARD', 15,
   '["Donnez votre avis", "Reconnaissez la limite", "Gardez votre position"]',
   '[{"label": "Limite reconnue", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'C''est vrai, et je le conseille quand même…', 'le reproche peut être exactement la qualité : montrez-le',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S16 — EASY — Le gymnase municipal
  ('d13dee17-9e2e-545e-951b-f470dc2efc4e', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S16', 'Le gymnase municipal',
   'La ville vous écrit : « Vous utilisez le gymnase chaque semaine. Merci de nous donner votre avis. »',
   'Donnez votre avis sur ce gymnase en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent : chacune se relie à la précédente au lieu d''être posée à côté.',
   40, 90, NULL, 'EASY', 1,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce gymnase est bien tenu…', 'un texte qui s''enchaîne n''a pas besoin de « pour conclure »',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S17 — EASY — Le grille-pain hérité
  ('f0d5ec61-3a43-5cb7-808c-961fb3049e20', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S17', 'Le grille-pain hérité',
   'Votre cousine vous écrit : « Tu gardes ce vieux grille-pain alors qu''il a vingt ans. Explique-moi ton avis. »',
   'Donnez votre avis sur cet objet en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, et le texte se referme sans formule de conclusion imposée.',
   40, 90, NULL, 'EASY', 2,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Je le garde parce qu''il marche encore…', '« en conclusion » en quatre-vingt-dix mots sonne faux',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S18 — MEDIUM — L'infirmière à domicile
  ('0c569c16-eeaf-5680-beb6-55896d624f2a', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S18', 'L''infirmière à domicile',
   'Le cabinet vous écrit : « Vous êtes suivie par cette infirmière depuis six mois. Merci de nous donner votre avis. »',
   'Donnez votre avis sur cette personne en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'MEDIUM', 3,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Cette infirmière est excellente…', 'les connecteurs montrent que vous pensez, pas que vous récitez',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S19 — MEDIUM — L'équipe du centre aéré
  ('58779e16-bab6-5d6e-8895-591eac7b01cc', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S19', 'L''équipe du centre aéré',
   'La mairie vous écrit : « Votre enfant fréquente le centre aéré. Merci de nous donner votre avis sur l''équipe. »',
   'Donnez votre avis sur cette équipe en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'MEDIUM', 4,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe est très bien…', 'une idée qui explique la suivante vaut mieux qu''une liste',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S20 — MEDIUM — Le refuge de montagne
  ('904ccad9-82ce-5440-b2ef-b47feb08f961', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S20', 'Le refuge de montagne',
   'Un club vous écrit : « Vous avez dormi au refuge des Bans. Merci de nous donner votre avis pour nos adhérents. »',
   'Donnez votre avis sur ce refuge en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'MEDIUM', 5,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Ce refuge est une bonne étape…', 'reliez : ce qui précède doit expliquer ce qui suit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S21 — MEDIUM — Le casque audio
  ('62b20725-2a99-5c45-9667-698b53279bdf', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S21', 'Le casque audio',
   'Un collègue vous écrit : « Tu utilises ce casque au bureau toute la journée. Qu''en penses-tu ? »',
   'Donnez votre avis sur cet objet en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'MEDIUM', 6,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Ce casque me convient très bien…', 'chaque phrase doit s''appuyer sur celle d''avant',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S22 — HARD — La libraire
  ('8b9de2c7-88b6-5f9a-be14-e7f6d35c7a1a', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S22', 'La libraire',
   'Un site d''avis vous écrit : « Vous êtes cliente de cette librairie. Merci de nous dire ce que vous pensez de la libraire. »',
   'Donnez votre avis sur cette personne en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'HARD', 7,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Cette libraire est précieuse…', 'une idée qui en entraîne une autre, c''est cela enchaîner',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S23 — HARD — Le collectif du local à vélos
  ('d823bff7-4779-5bd4-b714-7b7050497ded', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S23', 'Le collectif du local à vélos',
   'Le syndic vous écrit : « Un collectif d''habitants gère le local à vélos. Merci de nous donner votre avis sur ce groupe. »',
   'Donnez votre avis sur ce groupe en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'HARD', 8,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Ce collectif fonctionne bien…', 'montrez comment une chose en permet une autre',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S24 — MEDIUM — La halte-garderie
  ('6810fbb7-24c2-5b68-9a3e-b9365abc0617', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S24', 'La halte-garderie',
   'Le centre social vous écrit : « Vous déposez votre fils à la halte-garderie. Merci de nous donner votre avis sur ce lieu. »',
   'Donnez votre avis sur ce lieu en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'MEDIUM', 9,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette halte-garderie est bien pensée…', 'reliez la configuration du lieu à ce qu''elle permet',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S25 — HARD — Le four à pain du village
  ('bfa69a55-f1c4-571a-a566-6171fc8a3a46', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S25', 'Le four à pain du village',
   'La commune vous écrit : « Le four à pain communal a été remis en service. Merci de nous donner votre avis. »',
   'Donnez votre avis sur cet équipement en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'HARD', 10,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'La remise en service du four est une réussite…', 'une réussite se démontre par une chaîne de faits',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S26 — MEDIUM — Le vendeur du magasin de sport
  ('97cb8e65-d231-59f5-a53a-628a1813786d', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S26', 'Le vendeur du magasin de sport',
   'Un site d''avis vous écrit : « Vous avez été conseillé par ce vendeur. Merci de nous donner votre avis. »',
   'Donnez votre avis sur cette personne en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'MEDIUM', 11,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Ce vendeur a été très bon…', 'le déroulé d''un échange donne l''ordre tout seul',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S27 — HARD — L'équipe du laboratoire d'analyses
  ('fb0b5e53-2c73-594f-bf66-e7f9dd1973e3', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S27', 'L''équipe du laboratoire d''analyses',
   'Le laboratoire vous écrit : « Merci de nous donner votre avis sur l''équipe qui vous a reçue. »',
   'Donnez votre avis sur cette équipe en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'HARD', 12,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Groupe décrit", "icon": "PERSON"}]',
   'Cette équipe est efficace…', 'le parcours du patient donne l''ordre des idées',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S28 — MEDIUM — La cour intérieure de l'immeuble
  ('41e83856-7107-528d-b4cf-b3a20840d65b', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S28', 'La cour intérieure de l''immeuble',
   'Le syndic vous écrit : « La cour a été réaménagée cet été. Merci de nous donner votre avis. »',
   'Donnez votre avis sur ce lieu en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'MEDIUM', 13,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Lieu décrit", "icon": "PLACE"}]',
   'Cette cour est transformée…', 'avant et après se relient tout seuls, si on les relie',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S29 — HARD — La machine à coudre d'occasion
  ('624006d7-448a-595e-9778-cc562a82ac6b', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S29', 'La machine à coudre d''occasion',
   'Une amie vous écrit : « Tu as acheté cette machine à coudre d''occasion. Qu''est-ce que tu en penses maintenant ? »',
   'Donnez votre avis sur cet objet en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'HARD', 14,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Objet décrit", "icon": "NUMBER"}]',
   'Je suis très contente de cet achat…', 'raconter dans l''ordre suffit souvent à enchaîner',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S30 — HARD — Le conducteur du bus scolaire
  ('c25252b9-dab6-5f7f-8714-37def5303b66', '8c9134c2-ccba-59f4-903f-40067a3737ee', 'EE', 'EE3-C8-S30', 'Le conducteur du bus scolaire',
   'Le transporteur vous écrit : « Merci de nous donner votre avis sur le conducteur de la ligne scolaire de votre enfant. »',
   'Donnez votre avis sur cette personne en enchaînant vos idées de façon que le lecteur suive.',
   'Vos idées s''enchaînent, sans juxtaposition ni conclusion plaquée.',
   40, 90, NULL, 'HARD', 15,
   '["Donnez votre avis", "Reliez vos idées", "Pas de conclusion forcée"]',
   '[{"label": "Idées reliées", "icon": "STRUCTURE"}, {"label": "Personne décrite", "icon": "PERSON"}]',
   'Ce conducteur est très bien…', 'ce qu''il fait explique ce qui se passe dans le bus',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S1 — EASY — Plus rien avant six semaines
  ('1a9b5fd7-0094-5c39-a157-caa945e9a71e', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S1', 'Plus rien avant six semaines',
   'Vous appelez un cabinet médical pour votre fils. La secrétaire vous répond : « Je n''ai plus rien avant six semaines. »',
   'Ne raccrochez pas : poursuivez l''échange en relançant poliment.',
   'L''échange continue après le refus : une relance polie est formulée.',
   NULL, NULL, 30, 'EASY', 1,
   '["Restez poli", "Relancez après le refus", "Ne raccrochez pas"]',
   '[{"label": "Réponse imprévue", "icon": "TONE"}, {"label": "Échange poursuivi", "icon": "STRUCTURE"}]',
   'Je comprends, mais est-ce que…', 'Un « non » n''est pas la fin de l''échange : il en ouvre la deuxième partie.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S2 — EASY — La liste est complète
  ('f8572ebc-0c53-526a-97c6-b79432c9dd38', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S2', 'La liste est complète',
   'À la piscine municipale, vous voulez inscrire votre fille au cours du samedi. L''agent vous répond : « La liste est complète pour toute l''année. »',
   'Poursuivez l''échange au lieu de repartir : relancez poliment.',
   'L''échange continue après le refus : une relance polie est formulée.',
   NULL, NULL, 30, 'EASY', 2,
   '["Accusez réception du refus", "Relancez poliment", "Ne repartez pas"]',
   '[{"label": "Réponse imprévue", "icon": "TONE"}, {"label": "Relance polie", "icon": "TONE"}]',
   'D''accord, et est-ce qu''il y a…', 'Demander une liste d''attente coûte une phrase et change souvent tout.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S3 — EASY — Le modèle n'est plus fabriqué
  ('3b7dbcca-501b-51cc-a59c-e330aee12d3c', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S3', 'Le modèle n''est plus fabriqué',
   'Vous cherchez une pièce pour votre aspirateur. Le vendeur vous dit : « Ce modèle n''est plus fabriqué, nous n''avons plus la pièce. »',
   'Poursuivez l''échange au lieu de repartir : relancez poliment.',
   'L''échange continue après le refus : une relance polie est formulée.',
   NULL, NULL, 30, 'EASY', 3,
   '["Restez dans l''échange", "Relancez poliment", "Ne repartez pas"]',
   '[{"label": "Réponse imprévue", "icon": "TONE"}, {"label": "Échange poursuivi", "icon": "STRUCTURE"}]',
   'Je vois. Et est-ce que…', 'Même sans la pièce, le vendeur sait souvent où la trouver : demandez-lui.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S4 — EASY — Le guichet ferme dans cinq minutes
  ('688a2862-7b89-5d45-ab7c-7b9034b75b10', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S4', 'Le guichet ferme dans cinq minutes',
   'Vous arrivez à la mairie à seize heures cinquante-cinq. L''agent vous dit : « Nous fermons dans cinq minutes, revenez demain. »',
   'Poursuivez l''échange : relancez poliment, sans insister lourdement.',
   'L''échange continue après le refus : une relance polie est formulée.',
   NULL, NULL, 30, 'EASY', 4,
   '["Reconnaissez l''heure", "Relancez poliment", "N''insistez pas lourdement"]',
   '[{"label": "Réponse imprévue", "icon": "TONE"}, {"label": "Relance polie", "icon": "TONE"}]',
   'Je sais qu''il est tard, mais…', 'Dire que votre demande est courte rend la relance beaucoup plus acceptable.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S5 — EASY — Nous ne prenons que la carte
  ('8ebc8b95-8bb5-5089-b665-a8ad58d750bf', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S5', 'Nous ne prenons que la carte',
   'Dans une boutique, vous voulez payer vos achats en espèces. Le vendeur vous dit : « Nous ne prenons que la carte. »',
   'Poursuivez l''échange au lieu de renoncer : relancez poliment.',
   'L''échange continue après la contrainte : une relance polie est formulée.',
   NULL, NULL, 30, 'EASY', 5,
   '["Restez dans l''échange", "Relancez poliment", "Ne renoncez pas"]',
   '[{"label": "Contrainte imprévue", "icon": "TONE"}, {"label": "Échange poursuivi", "icon": "STRUCTURE"}]',
   'Ah, je n''ai que des espèces. Est-ce que…', 'Une contrainte se contourne souvent : demandez ce qui reste possible.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S6 — MEDIUM — Il manque une pièce au dossier
  ('0f3596e3-cf44-5798-82c6-6a35f92ab335', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S6', 'Il manque une pièce au dossier',
   'Au guichet de la CAF, l''agente vous dit : « Votre dossier est incomplet, il manque votre avis d''imposition. Nous ne pouvons rien traiter sans. » Vous ne l''avez pas sur vous.',
   'Poursuivez l''échange en proposant vous-même une autre façon de faire.',
   'Une autre solution est proposée, et elle tient compte de la contrainte annoncée.',
   NULL, NULL, 40, 'MEDIUM', 6,
   '["Reconnaissez la contrainte", "Proposez une autre solution", "Vérifiez qu''elle convient"]',
   '[{"label": "Contrainte imprévue", "icon": "TONE"}, {"label": "Autre solution", "icon": "EXAMPLE"}]',
   'Je ne l''ai pas sur moi. Est-ce que je peux…', 'Proposez quelque chose de précis : « je peux l''envoyer ce soir » vaut mieux qu''un soupir.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S7 — MEDIUM — Livraison en semaine seulement
  ('c1c520ea-4960-575f-a58a-31458bf3d0cf', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S7', 'Livraison en semaine seulement',
   'Vous achetez une machine à laver. Le vendeur vous annonce : « Nous livrons du lundi au vendredi, entre neuf heures et dix-sept heures. » Vous travaillez à ces heures-là.',
   'Poursuivez l''échange en proposant vous-même une autre façon de faire.',
   'Une autre solution est proposée, et elle tient compte de la contrainte annoncée.',
   NULL, NULL, 40, 'MEDIUM', 7,
   '["Nommez votre contrainte", "Proposez une autre solution", "Vérifiez qu''elle convient"]',
   '[{"label": "Contrainte imprévue", "icon": "TONE"}, {"label": "Autre solution", "icon": "EXAMPLE"}]',
   'Je travaille à ces heures-là. Est-ce que…', 'Nommez votre contrainte avant de proposer : la solution paraît alors évidente.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S8 — MEDIUM — Pas avant trois semaines
  ('c239daa0-0703-536e-83bc-64520095b098', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S8', 'Pas avant trois semaines',
   'Une fuite coule sous votre évier. Le plombier vous répond au téléphone : « Je ne peux pas passer avant trois semaines. »',
   'Poursuivez l''échange en proposant vous-même une autre façon de faire.',
   'Une autre solution est proposée, et elle tient compte du délai annoncé.',
   NULL, NULL, 40, 'MEDIUM', 8,
   '["Reconnaissez le délai", "Proposez une autre solution", "Vérifiez qu''elle convient"]',
   '[{"label": "Contrainte imprévue", "icon": "TONE"}, {"label": "Autre solution", "icon": "EXAMPLE"}]',
   'Trois semaines, c''est long. Est-ce que…', 'Demandez ce que vous pouvez faire vous-même en attendant : c''est aussi une solution.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S9 — MEDIUM — Le cours n'a lieu que le mardi soir
  ('74420700-58b6-5edb-aeef-adb103c330ec', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S9', 'Le cours n''a lieu que le mardi soir',
   'Dans une association, la responsable vous dit : « Le cours de français a lieu le mardi soir, c''est le seul créneau. » Vous travaillez le mardi soir.',
   'Poursuivez l''échange en proposant vous-même une autre façon de faire.',
   'Une autre solution est proposée, et elle tient compte de la contrainte annoncée.',
   NULL, NULL, 40, 'MEDIUM', 9,
   '["Nommez votre contrainte", "Proposez une autre solution", "Vérifiez qu''elle convient"]',
   '[{"label": "Contrainte imprévue", "icon": "TONE"}, {"label": "Autre solution", "icon": "EXAMPLE"}]',
   'Je travaille le mardi soir. Est-ce que…', 'Proposez plutôt que de demander : « est-ce que je peux… » ouvre la porte.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S10 — MEDIUM — Trois mois de caution
  ('02e541d6-4221-5dc9-8dd8-ed3b27b9f3f0', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S10', 'Trois mois de caution',
   'Dans une agence immobilière, l''agent vous annonce : « Le propriétaire demande trois mois de loyer de caution. » Vous ne pouvez pas avancer cette somme.',
   'Poursuivez l''échange en proposant vous-même une autre façon de faire.',
   'Une autre solution est proposée, et elle tient compte de la contrainte annoncée.',
   NULL, NULL, 40, 'MEDIUM', 10,
   '["Nommez votre contrainte", "Proposez une autre solution", "Vérifiez qu''elle convient"]',
   '[{"label": "Contrainte imprévue", "icon": "TONE"}, {"label": "Autre solution", "icon": "EXAMPLE"}]',
   'Trois mois, je ne peux pas. Est-ce que…', 'Une garantie, un garant, un paiement en deux fois : plusieurs solutions existent.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S11 — HARD — Passé trente jours, c'est non
  ('5560a686-085d-5d3b-834c-7135af4f03b2', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S11', 'Passé trente jours, c''est non',
   'Vous rapportez un appareil deux jours après la fin du délai de retour. Le responsable vous répond : « Passé trente jours, c''est non. C''est le règlement, je ne peux rien faire. »',
   'Poursuivez l''échange : adaptez votre demande au lieu d''insister sur la même.',
   'La demande est adaptée à la règle annoncée, sans être répétée à l''identique.',
   NULL, NULL, 45, 'HARD', 11,
   '["Acceptez la règle", "Changez de demande", "Restez dans l''échange"]',
   '[{"label": "Refus ferme", "icon": "TONE"}, {"label": "Demande adaptée", "icon": "STRUCTURE"}]',
   'D''accord, le remboursement n''est pas possible. Alors…', 'Quand une porte est fermée, cherchez-en une autre au lieu de pousser.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S12 — HARD — Plus de nouveaux patients
  ('41806f0f-f2fa-57a8-84be-5c157422d84e', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S12', 'Plus de nouveaux patients',
   'Vous cherchez un médecin traitant. La secrétaire vous dit : « Le docteur ne prend plus de nouveaux patients, sans exception. »',
   'Poursuivez l''échange : adaptez votre demande au lieu d''insister sur la même.',
   'La demande est adaptée au refus annoncé, sans être répétée à l''identique.',
   NULL, NULL, 45, 'HARD', 12,
   '["Acceptez le refus", "Changez de demande", "Restez dans l''échange"]',
   '[{"label": "Refus ferme", "icon": "TONE"}, {"label": "Demande adaptée", "icon": "STRUCTURE"}]',
   'Je comprends. Dans ce cas, est-ce que…', 'La personne au téléphone sait souvent autre chose : demandez-lui ce qu''elle sait.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S13 — HARD — Cette attestation n'est pas acceptée
  ('89968340-313a-5c05-a7bf-6f5061dde55a', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S13', 'Cette attestation n''est pas acceptée',
   'Au guichet, l''agent refuse votre justificatif de domicile : « Une attestation d''hébergement manuscrite, nous ne l''acceptons pas. C''est la règle. »',
   'Poursuivez l''échange : adaptez votre demande au lieu d''insister sur la même.',
   'La demande est adaptée à la règle annoncée, sans être répétée à l''identique.',
   NULL, NULL, 45, 'HARD', 13,
   '["Acceptez la règle", "Changez de demande", "Restez dans l''échange"]',
   '[{"label": "Refus ferme", "icon": "TONE"}, {"label": "Demande adaptée", "icon": "STRUCTURE"}]',
   'D''accord. Alors dites-moi plutôt…', 'Demander ce qui est accepté fait avancer plus vite que défendre ce qui ne l''est pas.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S14 — HARD — Le poste est déjà pourvu
  ('34a901f5-07e3-52d9-b38e-a35cc3c6c310', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S14', 'Le poste est déjà pourvu',
   'Vous rappelez après un entretien d''embauche. Le recruteur vous annonce : « Nous avons retenu un autre candidat. »',
   'Poursuivez l''échange : adaptez votre demande au lieu d''insister sur la même.',
   'La demande est adaptée au refus annoncé, sans être répétée à l''identique.',
   NULL, NULL, 45, 'HARD', 14,
   '["Acceptez la décision", "Changez de demande", "Restez dans l''échange"]',
   '[{"label": "Refus ferme", "icon": "TONE"}, {"label": "Demande adaptée", "icon": "STRUCTURE"}]',
   'Je vous remercie de me le dire. Est-ce que…', 'Un poste perdu peut ouvrir sur le suivant : demandez ce qui reste possible.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S15 — HARD — Rien ne se fait par téléphone
  ('3139e107-5df7-53d3-801a-89a489fb22bd', '18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2-C9-S15', 'Rien ne se fait par téléphone',
   'Vous appelez un service client pour corriger une erreur sur votre contrat. La conseillère vous dit : « Nous ne pouvons rien modifier par téléphone, il faut passer en agence. » L''agence est à quarante kilomètres.',
   'Poursuivez l''échange : adaptez votre demande au lieu d''insister sur la même.',
   'La demande est adaptée à la contrainte annoncée, sans être répétée à l''identique.',
   NULL, NULL, 45, 'HARD', 15,
   '["Acceptez la contrainte", "Changez de demande", "Restez dans l''échange"]',
   '[{"label": "Refus ferme", "icon": "TONE"}, {"label": "Demande adaptée", "icon": "STRUCTURE"}]',
   'D''accord, pas par téléphone. Alors est-ce que…', 'Si l''action est impossible, demandez ce qui la prépare : c''est déjà avancer.',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S1 — EASY — « C'est mieux pour tout le monde »
  ('79689aa4-a626-54a9-b05b-cac0e0c3dacb', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S1', '« C''est mieux pour tout le monde »',
   'Vous défendez les horaires souples au travail et vous venez de dire : « C''est mieux pour tout le monde. » Votre interlocuteur attend, l''air peu convaincu.',
   'Reprenez cette phrase autrement pour la préciser, sans la répéter telle quelle.',
   'La même idée est redite en d''autres mots, et la reprise la précise.',
   NULL, NULL, 35, 'EASY', 1,
   '["Redites-le autrement", "Précisez qui et comment", "Ne répétez pas la phrase"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Précision ajoutée", "icon": "STRUCTURE"}]',
   'Je veux dire par là que…', 'reformuler, ce n''est pas répéter : c''est dire la même chose plus précisément',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S2 — EASY — « Ça coûte cher »
  ('7984462c-3a76-518c-9ea7-1e5722cd9b4b', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S2', '« Ça coûte cher »',
   'Vous parlez du prix des transports et vous venez de dire : « Ça coûte cher. » Votre interlocuteur hausse les épaules.',
   'Reprenez cette phrase autrement pour la préciser, sans la répéter telle quelle.',
   'La même idée est redite en d''autres mots, et la reprise la précise.',
   NULL, NULL, 35, 'EASY', 2,
   '["Redites-le autrement", "Donnez une mesure concrète", "Ne répétez pas la phrase"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Précision ajoutée", "icon": "STRUCTURE"}]',
   'Plus précisément…', '« cher » ne dit rien tant qu''on ne dit pas cher par rapport à quoi',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S3 — EASY — « C'est plus pratique »
  ('f2164eaa-3143-5b2d-8765-d4751f61d207', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S3', '« C''est plus pratique »',
   'Vous défendez les commerces de quartier et vous venez de dire : « C''est plus pratique. » Votre interlocuteur attend la suite.',
   'Reprenez cette phrase autrement pour la préciser, sans la répéter telle quelle.',
   'La même idée est redite en d''autres mots, et la reprise la précise.',
   NULL, NULL, 35, 'EASY', 3,
   '["Redites-le autrement", "Dites pratique pour quoi", "Ne répétez pas la phrase"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Précision ajoutée", "icon": "STRUCTURE"}]',
   'Pratique, c''est-à-dire que…', '« pratique » se précise toujours : pratique pour qui, pour quel geste',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S4 — EASY — « C'est important pour les enfants »
  ('9f0960f1-a1df-5b80-8784-56c5287e762b', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S4', '« C''est important pour les enfants »',
   'Vous parlez de la lecture le soir et vous venez de dire : « C''est important pour les enfants. » On vous demande d''aller plus loin.',
   'Reprenez cette phrase autrement pour la préciser, sans la répéter telle quelle.',
   'La même idée est redite en d''autres mots, et la reprise la précise.',
   NULL, NULL, 35, 'EASY', 4,
   '["Redites-le autrement", "Dites important en quoi", "Ne répétez pas la phrase"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Précision ajoutée", "icon": "STRUCTURE"}]',
   'Important, je veux dire que…', '« important » se précise en disant ce que cela change vraiment',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S5 — EASY — « Ça ne marche pas »
  ('1e06cff1-77f3-5986-901b-513a7d26dbda', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S5', '« Ça ne marche pas »',
   'Vous parlez du tri des déchets dans votre immeuble et vous venez de dire : « Ça ne marche pas. » Un voisin vous demande ce que vous voulez dire.',
   'Reprenez cette phrase autrement pour la préciser, sans la répéter telle quelle.',
   'La même idée est redite en d''autres mots, et la reprise la précise.',
   NULL, NULL, 35, 'EASY', 5,
   '["Redites-le autrement", "Décrivez ce qu''on voit", "Ne répétez pas la phrase"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Précision ajoutée", "icon": "STRUCTURE"}]',
   'Concrètement…', '« ça ne marche pas » ne dit rien : décrivez ce qu''on voit',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S6 — MEDIUM — « Les jeunes ne lisent plus »
  ('513b15ca-165c-5f02-9871-336f4c8816f7', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S6', '« Les jeunes ne lisent plus »',
   'Vous venez de dire : « Les jeunes ne lisent plus. » Votre interlocuteur répond : « Vous êtes dur avec eux. » Ce n''est pas ce que vous vouliez dire.',
   'Reprenez votre idée autrement pour lever le malentendu, sans la répéter ni vous excuser.',
   'La même idée est redite en d''autres mots, et la reprise lève le malentendu.',
   NULL, NULL, 42, 'MEDIUM', 6,
   '["Écartez le malentendu", "Redites l''idée autrement", "Ne vous excusez pas"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Malentendu levé", "icon": "TONE"}]',
   'Ce n''est pas ce que je voulais dire…', 'reformuler vaut mieux que se défendre : redites l''idée, autrement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S7 — MEDIUM — « Limiter les voitures en centre-ville »
  ('d06a752c-a778-58ea-a99b-932f52fb7300', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S7', '« Limiter les voitures en centre-ville »',
   'Vous venez de dire : « Il faut limiter les voitures en centre-ville. » Votre interlocuteur répond : « Donc vous voulez les interdire. » Ce n''est pas votre position.',
   'Reprenez votre idée autrement pour lever le malentendu, sans la répéter ni vous excuser.',
   'La même idée est redite en d''autres mots, et la reprise lève le malentendu.',
   NULL, NULL, 42, 'MEDIUM', 7,
   '["Écartez le malentendu", "Redites l''idée autrement", "Ne vous excusez pas"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Malentendu levé", "icon": "TONE"}]',
   'Je ne dis pas cela. Je dis que…', 'quand on vous prête un excès, redonnez la mesure exacte de votre idée',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S8 — MEDIUM — « Le télétravail isole »
  ('111a1762-73e1-53fb-9c70-8192f1ab9e00', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S8', '« Le télétravail isole »',
   'Vous venez de dire : « Le télétravail isole. » Votre interlocuteur répond : « Vous êtes donc contre. » Ce n''est pas votre position.',
   'Reprenez votre idée autrement pour lever le malentendu, sans la répéter ni vous excuser.',
   'La même idée est redite en d''autres mots, et la reprise lève le malentendu.',
   NULL, NULL, 42, 'MEDIUM', 8,
   '["Écartez le malentendu", "Redites l''idée autrement", "Ne vous excusez pas"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Malentendu levé", "icon": "TONE"}]',
   'Non, je ne suis pas contre. Ce que je dis, c''est que…', 'signaler un risque n''est pas s''opposer : dites-le autrement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S9 — MEDIUM — « L'école demande trop aux parents »
  ('89cabd64-b692-5c2a-a711-90dc1c83511f', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S9', '« L''école demande trop aux parents »',
   'Vous venez de dire : « L''école demande trop aux parents. » Votre interlocutrice, enseignante, répond : « Vous nous reprochez quelque chose ? » Ce n''est pas ce que vous vouliez dire.',
   'Reprenez votre idée autrement pour lever le malentendu, sans la répéter ni vous excuser.',
   'La même idée est redite en d''autres mots, et la reprise lève le malentendu.',
   NULL, NULL, 42, 'MEDIUM', 9,
   '["Écartez le malentendu", "Redites l''idée autrement", "Ne vous excusez pas"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Malentendu levé", "icon": "TONE"}]',
   'Ce n''est pas à vous que je pense. Je pense à…', 'désignez ce que vous visez vraiment : le malentendu tombe tout seul',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S10 — MEDIUM — « Les réseaux font perdre du temps »
  ('9e8e637a-b3da-570a-81c5-bf094aa85016', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S10', '« Les réseaux font perdre du temps »',
   'Vous venez de dire : « Les réseaux sociaux font perdre du temps. » Votre interlocuteur répond : « Il faudrait donc les supprimer ? » Ce n''est pas votre position.',
   'Reprenez votre idée autrement pour lever le malentendu, sans la répéter ni vous excuser.',
   'La même idée est redite en d''autres mots, et la reprise lève le malentendu.',
   NULL, NULL, 42, 'MEDIUM', 10,
   '["Écartez le malentendu", "Redites l''idée autrement", "Ne vous excusez pas"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Malentendu levé", "icon": "TONE"}]',
   'Ce n''est pas la question. Ce que je dis, c''est que…', 'on vous pousse à l''extrême : ramenez votre idée à sa taille réelle',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S11 — HARD — « Une question de moyens »
  ('aeef2f61-2821-5433-868c-44ee8255dce4', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S11', '« Une question de moyens »',
   'Vous parlez du manque de places en crèche. Vous venez de dire deux fois « c''est une question de moyens » et vous sentez que vous tournez en rond.',
   'Reprenez votre idée autrement pour repartir, au lieu de la redire une troisième fois.',
   'L''idée est reprise en d''autres mots et la reprise relance le propos ailleurs.',
   NULL, NULL, 48, 'HARD', 11,
   '["Redites l''idée autrement", "Repartez sur autre chose", "Ne redites pas la formule"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Propos relancé", "icon": "STRUCTURE"}]',
   'Plutôt que de parler de moyens, disons que…', 'quand une formule revient, changez de mots : les idées suivent',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S12 — HARD — « C'est important »
  ('79a0536c-c787-5098-8f8d-8d526e0eab1e', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S12', '« C''est important »',
   'Vous parlez de l''apprentissage du français à l''arrivée en France. Vous avez déjà dit trois fois « c''est important » et vous n''avancez plus.',
   'Reprenez votre idée autrement pour repartir, au lieu de la redire une fois de plus.',
   'L''idée est reprise en d''autres mots et la reprise relance le propos ailleurs.',
   NULL, NULL, 48, 'HARD', 12,
   '["Redites l''idée autrement", "Repartez sur autre chose", "Ne redites pas la formule"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Propos relancé", "icon": "STRUCTURE"}]',
   'Disons-le autrement…', 'changer de mot est souvent le seul moyen de sortir d''une boucle',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S13 — HARD — « Ça dépend des gens »
  ('8097e787-04ab-50e2-b681-38a31144e610', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S13', '« Ça dépend des gens »',
   'On vous demande si le bénévolat devrait être davantage encouragé. Vous tournez autour de « ça dépend des gens » depuis un moment.',
   'Reprenez votre idée autrement pour repartir, au lieu de rester sur cette formule.',
   'L''idée est reprise en d''autres mots et la reprise relance le propos ailleurs.',
   NULL, NULL, 48, 'HARD', 13,
   '["Redites l''idée autrement", "Repartez sur autre chose", "Ne redites pas la formule"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Propos relancé", "icon": "STRUCTURE"}]',
   'Au fond, ce que je veux dire, c''est que…', '« ça dépend » se transforme facilement : dites de quoi, exactement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S14 — HARD — « Il faut du temps »
  ('814f0baa-ff8c-55fe-b402-a799df445fb6', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S14', '« Il faut du temps »',
   'Vous parlez de l''installation dans un nouveau pays. Vous avez dit trois fois « il faut du temps » et vous sentez que vous piétinez.',
   'Reprenez votre idée autrement pour repartir, au lieu de la redire une fois de plus.',
   'L''idée est reprise en d''autres mots et la reprise relance le propos ailleurs.',
   NULL, NULL, 48, 'HARD', 14,
   '["Redites l''idée autrement", "Repartez sur autre chose", "Ne redites pas la formule"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Propos relancé", "icon": "STRUCTURE"}]',
   'Plutôt que « du temps », disons…', 'remplacez le mot vague par ce qu''il contient : le propos redémarre',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S15 — HARD — Le mot ne vient pas
  ('51051411-3c01-5c55-977d-2efe65cd5902', '56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3-C9-S15', 'Le mot ne vient pas',
   'Vous défendez les jardins partagés de votre ville. Vous cherchez un mot depuis quelques secondes et il ne vient pas.',
   'Reprenez votre idée avec d''autres mots pour repartir, sans attendre que le mot exact revienne.',
   'L''idée est redite avec d''autres mots et le propos repart, sans blocage sur le mot manquant.',
   NULL, NULL, 48, 'HARD', 15,
   '["Renoncez au mot exact", "Redites l''idée autrement", "Repartez sans vous arrêter"]',
   '[{"label": "Reprise autrement", "icon": "STRUCTURE"}, {"label": "Propos relancé", "icon": "STRUCTURE"}]',
   'Je ne trouve pas le mot, mais l''idée, c''est que…', 'le mot exact n''est pas nécessaire : l''idée passe très bien autrement',
   true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02');

-- 3d. Leurs references.
INSERT INTO skill_references (id, skill_prompt_id, level, text, pedagogical_note,
                              created_at, updated_at)
VALUES
  -- EE1-C2-S16 / INSUFFICIENT
  ('7790eb78-64fc-546b-a7d0-b02c2d1bb6b9', '5c3812b3-7b41-57ff-9359-e09a75487425', 'INSUFFICIENT',
   'Bonjour, oui pardon, je lui avais demandé de passer récupérer mon échelle parce que je n''étais pas là ce matin. J''aurais dû vous prévenir avant, je suis désolée du dérangement.',
   'Vous expliquez pourquoi vous l''aviez envoyée. La voisine demandait à quoi elle ressemblait : sa question reste sans réponse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S16 / EXPECTED
  ('413810cf-5a63-5dda-8064-b87c426350bd', '5c3812b3-7b41-57ff-9359-e09a75487425', 'EXPECTED',
   'Bonjour, oui, c''était mon beau-frère. C''est un homme d''une trentaine d''années, grand et mince, avec une barbe courte. Il portait une veste bleue et une casquette grise. Il est plutôt timide.',
   'Âge, taille, barbe, vêtements, caractère : chaque phrase répond à la question posée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S16 / EXCELLENT
  ('8206e628-ec74-5fce-8366-a448eee797ec', '5c3812b3-7b41-57ff-9359-e09a75487425', 'EXCELLENT',
   'Bonjour, oui, c''était mon beau-frère Idriss. Un homme d''une trentaine d''années, grand et mince, la barbe courte et les cheveux très courts. Il portait une veste bleue un peu usée et une casquette grise. Il parle bas et n''insiste jamais.',
   'Le prénom, l''usure de la veste et la manière de parler rendent la personne réellement reconnaissable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S17 / INSUFFICIENT
  ('e64fe770-5038-5e02-b2f8-9556e69bb129', '879929d0-7cd9-5f38-99b8-0dc4c8bd9320', 'INSUFFICIENT',
   'Bonjour, oui j''attends un colis depuis mardi dernier, le vendeur m''avait dit trois jours. C''est vraiment long. Est-ce que vous pouvez me le monter s''il vous plaît ? J''habite au quatrième.',
   'Vous racontez le retard et vous demandez un service. Le gardien voulait une description pour identifier le colis.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S17 / EXPECTED
  ('1e8b95df-a463-596f-864c-da2281caebb9', '879929d0-7cd9-5f38-99b8-0dc4c8bd9320', 'EXPECTED',
   'Bonjour, j''attends un colis. C''est une boîte en carton marron, assez plate, d''environ quarante centimètres de côté. Elle n''est pas lourde. Il y a du ruban adhésif bleu sur le dessus.',
   'Forme, matière, taille, poids, détail visible : tout sert à reconnaître le colis.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S17 / EXCELLENT
  ('9455ffc2-d087-5b64-be7a-4352d30ec763', '879929d0-7cd9-5f38-99b8-0dc4c8bd9320', 'EXCELLENT',
   'Bonjour, j''attends un colis. C''est une boîte en carton marron, plate, d''environ quarante centimètres de côté et très légère. Le dessus est fermé par du ruban adhésif bleu, et un coin est un peu enfoncé.',
   'Les mêmes traits, plus un détail distinctif — le coin enfoncé — qui rend l''identification certaine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S18 / INSUFFICIENT
  ('c74b068d-7fd7-58a7-a716-7a8ef7f50d6f', 'a7766ef3-764b-5d56-878a-b22b2f670cc3', 'INSUFFICIENT',
   'La réunion commence à quatorze heures, n''oublie pas. On doit parler du budget et du planning de septembre, donc prévois large. La salle Mistral est au deuxième étage, tu verras, c''est indiqué dans le couloir.',
   'Vous redonnez l''horaire et l''ordre du jour, qu''elle connaît déjà. Sa question sur la salle reste sans réponse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S18 / EXPECTED
  ('a79777aa-79a2-5b74-af1c-9cdc44dd4fce', 'a7766ef3-764b-5d56-878a-b22b2f670cc3', 'EXPECTED',
   'La salle Mistral est assez grande, avec une longue table centrale et une douzaine de chaises. Il y a un écran au mur et plusieurs prises le long de la cloison. La lumière du jour entre bien.',
   'Taille, mobilier, équipement, lumière : tout ce qu''il faut pour savoir si le matériel tiendra.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S18 / EXCELLENT
  ('5fa2302e-41b6-5c44-9b97-d08b051069d8', 'a7766ef3-764b-5d56-878a-b22b2f670cc3', 'EXCELLENT',
   'La salle Mistral est spacieuse : une longue table centrale, une douzaine de chaises, et un écran fixé au mur du fond. Des prises courent le long de la cloison de droite, juste au niveau de la table. Deux grandes fenêtres l''éclairent.',
   'Les prises sont situées « au niveau de la table » : le détail répond exactement à son inquiétude.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S19 / INSUFFICIENT
  ('49e7244e-8767-55ce-b8e2-dff1830b0882', 'c9048d4e-7f30-5796-84e5-3a67f4ce2c31', 'INSUFFICIENT',
   'Le cours est très bien, on travaille la grammaire le lundi et l''oral le jeudi. La prof donne des exercices à faire à la maison. Ça dure deux heures, de dix-huit à vingt heures.',
   'Vous décrivez le cours, pas le groupe. Son inquiétude — être le seul débutant — n''est pas levée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S19 / EXPECTED
  ('ada5198e-5908-50c9-ac76-d4ecf87acee8', 'c9048d4e-7f30-5796-84e5-3a67f4ce2c31', 'EXPECTED',
   'Nous sommes huit, de tous les âges. Il y a deux autres débutants comme toi, et les autres parlent un peu mieux mais restent simples. L''ambiance est détendue, tout le monde s''aide.',
   'Nombre, âges, niveaux, ambiance : le groupe est décrit, et la crainte trouve sa réponse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S19 / EXCELLENT
  ('5d1039de-f3d3-5f38-8faf-8d3071321080', 'c9048d4e-7f30-5796-84e5-3a67f4ce2c31', 'EXCELLENT',
   'Nous sommes huit, entre vingt et soixante ans. Deux personnes débutent comme toi, et même les plus avancés font des fautes sans que cela gêne personne. L''ambiance est très détendue : on rit beaucoup et chacun aide son voisin.',
   'Les âges sont chiffrés et l''ambiance montrée par des faits — « on rit », « chacun aide » — plutôt que nommée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S20 / INSUFFICIENT
  ('6f211fa4-ee2a-57df-be5e-a6defa09131b', 'ed377ab0-6726-57b6-adce-1c70e7514ecb', 'INSUFFICIENT',
   'Bonjour, je le vends cent vingt euros et je ne descendrai pas plus bas. Je suis disponible samedi matin si vous voulez le voir. Prévenez-moi la veille pour que je le sorte de la cave.',
   'Vous parlez prix et rendez-vous. L''acheteur demandait une description : il ne sait toujours pas à quoi ressemble le vélo.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S20 / EXPECTED
  ('6438ae78-fa04-52db-b446-1fa3deab7d81', 'ed377ab0-6726-57b6-adce-1c70e7514ecb', 'EXPECTED',
   'Bonjour, bien sûr. C''est un vélo de ville bleu, avec un guidon droit et un panier à l''avant. Il a six vitesses et des pneus larges. Le cadre a quelques rayures mais tout fonctionne bien.',
   'Type, couleur, équipement, état : la description remplace utilement la photo.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S20 / EXCELLENT
  ('c83a2e1e-5b4b-5c19-8e04-a4cabfa0b4cb', 'ed377ab0-6726-57b6-adce-1c70e7514ecb', 'EXCELLENT',
   'Bonjour, bien sûr. C''est un vélo de ville bleu foncé, guidon droit et panier en osier à l''avant. Six vitesses, des pneus larges et confortables. Le cadre porte quelques rayures près de la selle, mais les freins et les vitesses répondent parfaitement.',
   'Chaque trait est localisé — « en osier », « près de la selle » — et l''état est dit fonction par fonction.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S21 / INSUFFICIENT
  ('f6102d36-cd37-5b82-a41a-65bc697e144f', '4145a3b7-be71-547d-b83f-1501ac99505b', 'INSUFFICIENT',
   'Je m''occupe de tout. Je lui montrerai son bureau, je lui présenterai l''équipe et je lui expliquerai le logiciel. Elle remplace Sonia sur les dossiers clients, donc il faudra qu''on reprenne les trois dossiers en cours.',
   'Vous décrivez la journée d''accueil. Le responsable demandait comment vous la reconnaîtrez.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S21 / EXPECTED
  ('20ad4d26-c023-588b-97eb-3165f7aae511', '4145a3b7-be71-547d-b83f-1501ac99505b', 'EXPECTED',
   'Je la reconnaîtrai sans difficulté. C''est une femme d''une quarantaine d''années, grande, avec des cheveux courts et bruns. Elle portera un manteau vert et un grand sac noir. Elle arrivera vers neuf heures.',
   'Âge, taille, cheveux, vêtements : tous les traits servent à l''identifier à son arrivée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S21 / EXCELLENT
  ('5eddf3fc-822a-56b6-a0ad-afd4caabe182', '4145a3b7-be71-547d-b83f-1501ac99505b', 'EXCELLENT',
   'Je la reconnaîtrai sans difficulté. C''est une femme d''une quarantaine d''années, assez grande, les cheveux bruns coupés court. Elle m''a dit qu''elle porterait un manteau vert et un grand sac noir en bandoulière. Elle arrive vers neuf heures par le tramway.',
   'La source de l''information est rappelée (« elle m''a dit »), et « en bandoulière » ajoute un repère visuel utile.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S22 / INSUFFICIENT
  ('80d09c79-d987-5861-9086-8ab47a5e2a23', '880e5693-087d-5482-a157-52d4769e29b2', 'INSUFFICIENT',
   'Oui je l''ai vu. Le loyer est de cinq cent quatre-vingts euros charges comprises, il faut un garant et deux mois de caution. Appelle l''agence Dumas, c''est eux qui gèrent, demande Madame Roy.',
   'Vous donnez le loyer et la marche à suivre. Elle voulait savoir à quoi ressemble le studio.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S22 / EXPECTED
  ('28686776-8935-5468-a1b0-166d1855704d', '880e5693-087d-5482-a157-52d4769e29b2', 'EXPECTED',
   'Oui, je l''ai visité l''an dernier. C''est une pièce d''environ vingt-cinq mètres carrés, avec un coin cuisine et une petite salle d''eau. La fenêtre donne sur la cour, donc c''est calme. Les murs sont blancs et le sol est en parquet.',
   'Surface, agencement, exposition, matériaux : elle peut se représenter le lieu.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S22 / EXCELLENT
  ('158b9835-59e4-50e8-b846-a80510e87fe0', '880e5693-087d-5482-a157-52d4769e29b2', 'EXCELLENT',
   'Oui, je l''ai visité l''an dernier. Une pièce d''environ vingt-cinq mètres carrés, avec un coin cuisine le long du mur et une petite salle d''eau derrière une cloison. L''unique fenêtre donne sur la cour : c''est très calme, mais un peu sombre le matin. Parquet clair, murs blancs.',
   'La nuance « calme, mais un peu sombre » est exactement ce qu''on attend d''une description honnête.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S23 / INSUFFICIENT
  ('72358908-ff14-5da1-a7df-e10fdefb4908', 'f52242f7-bd9b-5a34-9a20-f1feb935e160', 'INSUFFICIENT',
   'Il faut remplir un formulaire à la mairie et attendre la commission de mars. La cotisation est de quinze euros par an. Après, on te donne une parcelle et une clé du portail. C''est assez simple.',
   'Vous expliquez la démarche d''inscription. Sa question portait sur les personnes.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S23 / EXPECTED
  ('f7e7f8ba-f579-509a-9baa-7677f7e6d619', 'f52242f7-bd9b-5a34-9a20-f1feb935e160', 'EXPECTED',
   'Ce sont surtout des habitants du quartier, une quinzaine. Il y a plusieurs retraités qui viennent en semaine, deux familles avec enfants le week-end, et un jeune couple très actif. Tout le monde est plutôt accueillant.',
   'Nombre, profils, rythmes, ambiance : le groupe prend forme.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S23 / EXCELLENT
  ('87584d93-4967-5fac-b1c9-41b8513817f5', 'f52242f7-bd9b-5a34-9a20-f1feb935e160', 'EXCELLENT',
   'Ce sont surtout des habitants du quartier, une quinzaine. Plusieurs retraités viennent en semaine et connaissent tout du potager ; deux familles avec enfants passent le samedi, et un jeune couple s''occupe du compost. On se prête les outils sans compter.',
   'Chaque sous-groupe est caractérisé par ce qu''il fait, et le dernier détail montre l''ambiance au lieu de la déclarer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S24 / INSUFFICIENT
  ('4dd19d89-519b-55c8-ad47-33d40d6eefb6', 'b7e7d949-8888-551f-9903-eae625d4a497', 'INSUFFICIENT',
   'Bonjour, j''étais là hier soir vers vingt heures avec deux amies, on était installées près de la fenêtre. On est parties un peu vite parce qu''on avait un train. Pouvez-vous me le garder jusqu''à samedi ?',
   'Vous racontez la soirée et vous demandez un service. Avec trois manteaux au comptoir, le gérant ne peut toujours pas trouver le vôtre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S24 / EXPECTED
  ('0a0edca8-3f08-5cff-b3d8-46a14ac2c081', 'b7e7d949-8888-551f-9903-eae625d4a497', 'EXPECTED',
   'Bonjour, c''est un manteau de laine bleu marine, assez long, avec des boutons dorés. Il y a une écharpe grise dans la manche gauche et un ticket de bus dans la poche.',
   'Matière, couleur, longueur, boutons, et deux détails intérieurs qui prouvent que le manteau est bien le vôtre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S24 / EXCELLENT
  ('1e183df5-1787-55cb-826e-15904b071061', 'b7e7d949-8888-551f-9903-eae625d4a497', 'EXCELLENT',
   'Bonjour, c''est un manteau de laine bleu marine, assez long, fermé par de gros boutons dorés. La doublure est à carreaux. Vous trouverez une écharpe grise roulée dans la manche gauche et un ticket de bus au fond de la poche droite.',
   'La doublure et la localisation précise des objets rendent l''identification indiscutable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S25 / INSUFFICIENT
  ('e20be143-caa3-59dc-855c-e772eb3857fa', 'f496c277-4980-5134-bc3f-3d4391b7d982', 'INSUFFICIENT',
   'Le marché ouvre à huit heures et ferme vers treize heures. Vas-y tôt, après il y a trop de monde. Prends le comté de douze mois, c''est le meilleur, et demande à goûter, ils acceptent toujours.',
   'Horaires et conseils d''achat. Elle demandait comment repérer le stand.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S25 / EXPECTED
  ('088a6f88-3c4b-5e18-a80c-ed88f2c33350', 'f496c277-4980-5134-bc3f-3d4391b7d982', 'EXPECTED',
   'Tu le verras tout de suite : c''est un grand stand sous une bâche verte, au milieu de l''allée centrale. Il y a une vitrine réfrigérée pleine de meules et une ardoise avec les prix écrits à la craie.',
   'Taille, couleur, emplacement, mobilier : le stand est identifiable de loin.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S25 / EXCELLENT
  ('97e07139-6f2d-5968-a602-8c50ce94e1c7', 'f496c277-4980-5134-bc3f-3d4391b7d982', 'EXCELLENT',
   'Tu le verras tout de suite : un grand stand sous une bâche vert foncé, au milieu de l''allée centrale, juste en face du marchand de fleurs. Une vitrine réfrigérée déborde de meules, et une ardoise annonce les prix à la craie. Il y a presque toujours la queue.',
   'Le repère voisin et la file d''attente sont deux indices très efficaces pour retrouver un stand.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S26 / INSUFFICIENT
  ('0adbdc02-3a5b-5d1b-a2b7-4a15d24ca04f', 'ebf8f92f-9a6f-59f2-999b-e859a74f52a5', 'INSUFFICIENT',
   'L''inscription est de cent dix euros à l''année, licence comprise. Les entraînements ont lieu le mardi et le jeudi de dix-sept à dix-huit heures trente, et il y a un match un samedi sur deux.',
   'Tarifs et horaires. La question portait sur l''entraîneur et sa manière d''être.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S26 / EXPECTED
  ('3fce8cd1-4693-57b6-9b67-a7042fecfea8', 'ebf8f92f-9a6f-59f2-999b-e859a74f52a5', 'EXPECTED',
   'L''entraîneur s''appelle Marc. C''est un homme d''une cinquantaine d''années, calme et très patient. Il parle doucement et ne crie jamais. Il prend le temps d''expliquer deux fois aux plus jeunes.',
   'Âge, caractère, manière de parler, comportement avec les enfants : la question trouve sa réponse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S26 / EXCELLENT
  ('85faf5a0-6695-5694-a1da-d9016d7d9d2b', 'ebf8f92f-9a6f-59f2-999b-e859a74f52a5', 'EXCELLENT',
   'L''entraîneur s''appelle Marc, une cinquantaine d''années, très calme. Il ne crie jamais : quand un enfant se trompe, il s''accroupit à sa hauteur et réexplique. Mon fils, qui est timide, a osé lui poser des questions dès la deuxième séance.',
   'Le caractère est montré par des faits observables, et l''exemple final vaut mieux que n''importe quel adjectif.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S27 / INSUFFICIENT
  ('6642e860-7d43-5dc4-b226-4bad0e6a3f11', 'd0132b09-c9e9-5f33-8c9e-b16c52a58109', 'INSUFFICIENT',
   'Prends bien la carte Vitale et le carnet de santé, sinon ils te renvoient. Arrive dix minutes avant, il faut s''enregistrer à l''accueil. Et surtout ne sois pas en retard, ils sautent le rendez-vous après un quart d''heure.',
   'Vous conseillez sur le rendez-vous. Il demandait à quoi ressemble la salle d''attente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S27 / EXPECTED
  ('e410f347-bc21-595d-812a-a4bd08d81263', 'd0132b09-c9e9-5f33-8c9e-b16c52a58109', 'EXPECTED',
   'La salle d''attente est grande et claire, avec une vingtaine de chaises le long des murs. Il y a un coin avec un tapis, des cubes et quelques livres pour les enfants. C''est assez calme en général.',
   'Taille, lumière, mobilier, coin enfants, ambiance sonore : tout répond à ce qui l''inquiète.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S27 / EXCELLENT
  ('b53a86c9-b27b-5b11-bac4-6f1b8c262bc0', 'd0132b09-c9e9-5f33-8c9e-b16c52a58109', 'EXCELLENT',
   'La salle d''attente est grande et très claire, une vingtaine de chaises le long des murs. Dans l''angle du fond, un tapis avec des cubes et une caisse de livres cartonnés occupe bien les petits. Il y fait plutôt calme, sauf le mercredi.',
   'Le coin enfants est situé et détaillé, et la réserve sur le mercredi rend la description crédible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S28 / INSUFFICIENT
  ('ed61b7d8-ffd0-5c48-84f7-de5b2db99ce3', '11f25597-44fe-5070-a7bb-fbe4d84fb47e', 'INSUFFICIENT',
   'Non, rien ne m''inquiète, ça ira très bien. Ça va surtout me changer mes horaires : je commençais à quatorze heures et maintenant ce sera six heures, donc je vais devoir revoir la garde de ma fille et prendre le premier bus.',
   'Vous rassurez en une phrase, puis vous parlez de vos horaires. Le responsable voulait vous entendre décrire l''équipe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S28 / EXPECTED
  ('17687bac-c578-5bc8-8199-a4d7390591eb', '11f25597-44fe-5070-a7bb-fbe4d84fb47e', 'EXPECTED',
   'Je les croise chaque soir à la relève. Ils sont cinq, plutôt jeunes, sauf le chef d''équipe qui a de l''ancienneté. Ils travaillent vite et parlent peu pendant le service, mais ils prennent toujours leur pause ensemble. Rien ne m''inquiète.',
   'La question implicite est comprise : c''est bien l''équipe qui est décrite, et la réserve du responsable trouve sa réponse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S28 / EXCELLENT
  ('e4b82a28-3dc8-56f0-832d-6cdcf643a299', '11f25597-44fe-5070-a7bb-fbe4d84fb47e', 'EXCELLENT',
   'Je les croise chaque soir à la relève. Ils sont cinq, plutôt jeunes, sauf le chef d''équipe qui est là depuis quinze ans. Ils échangent peu pendant le service et vont vite, mais ils prennent toujours leur pause ensemble dehors, même l''hiver. Ce silence-là ne m''inquiète pas.',
   'Le candidat nomme précisément ce que le responsable sous-entendait — le silence au travail — et le décrit au lieu de le nier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S29 / INSUFFICIENT
  ('8762e324-7548-5cac-9a25-b761083557e0', 'd4a61f4e-c65b-5df5-96e2-377baf45657e', 'INSUFFICIENT',
   'Bonjour ! Super, il est pour vous. Je suis là samedi toute la journée et dimanche matin. J''habite au 12 rue Pasteur, deuxième étage, il n''y a pas d''ascenseur, prévoyez d''être deux. Sonnez à Berthier.',
   'Vous organisez l''enlèvement. Les deux questions — la taille et l''état — restent sans réponse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S29 / EXPECTED
  ('4241b991-be25-54eb-9806-ee6a2136f35c', 'd4a61f4e-c65b-5df5-96e2-377baf45657e', 'EXPECTED',
   'Bonjour ! C''est un fauteuil assez large, environ quatre-vingts centimètres, en tissu beige. Le dossier est haut. Il est en bon état général, mais l''accoudoir droit est un peu taché et l''assise s''est creusée.',
   'La taille est chiffrée et l''état détaillé sans le cacher : les deux questions sont traitées.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S29 / EXCELLENT
  ('74c5328b-9ef8-5a7e-8a19-a6a250dd51e0', 'd4a61f4e-c65b-5df5-96e2-377baf45657e', 'EXCELLENT',
   'Bonjour ! C''est un fauteuil large d''environ quatre-vingts centimètres pour un mètre de haut, en tissu beige, avec un dossier haut. Il est solide et propre, mais l''accoudoir droit porte une tache sombre et l''assise s''est un peu creusée au milieu.',
   'Deux dimensions au lieu d''une — décisives pour un couloir étroit — et les défauts sont localisés.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S30 / INSUFFICIENT
  ('b504d4b2-0d33-5310-841c-0e93aaa5cdc2', '1bbb4b5a-d438-596d-a5c6-008cec876b3c', 'INSUFFICIENT',
   'C''est un village de trois cents habitants accroché au flanc de la montagne, avec des maisons en pierre grise et des volets de bois. J''y ai passé tous mes étés petite, on partait à vélo jusqu''au lac et on rentrait à la nuit.',
   'Le premier point est traité, puis les souvenirs prennent la place du second : on ne sait toujours pas ce qu''on trouve sur place.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S30 / EXPECTED
  ('34521555-bb3a-5049-8fd8-3edccf46ed3f', '1bbb4b5a-d438-596d-a5c6-008cec876b3c', 'EXPECTED',
   'C''est un village de trois cents habitants, accroché au flanc de la montagne, avec des maisons en pierre grise. Sur la place, il y a une fontaine, une épicerie et un café. Le médecin passe le mardi. Tout est à moins de cinq minutes à pied.',
   'Les deux points sont traités, et la dernière phrase répond même à la difficulté de marche, sans s''écarter.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C2-S30 / EXCELLENT
  ('dc542e30-a7ae-5d68-87a4-8b20e42e9746', '1bbb4b5a-d438-596d-a5c6-008cec876b3c', 'EXCELLENT',
   'C''est un village de trois cents habitants accroché au flanc de la montagne, maisons en pierre grise aux volets délavés. Autour de la place : une fontaine, une épicerie, un café qui ferme à vingt heures. Le médecin passe le mardi. Tout tient dans un rayon de deux cents mètres, et la place est plate.',
   'Les deux points sont traités et la contrainte de marche est prise au sérieux — « un rayon de deux cents mètres », « la place est plate ».', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S16 / INSUFFICIENT
  ('a9a10b50-c924-5ecd-8e2a-c27e2bae8778', '6d2fed68-65ef-5ade-afb0-595889e186c3', 'INSUFFICIENT',
   'Salut ! Alors c''est ma sœur Awa qui vient, elle a vingt-cinq ans, cheveux longs noirs, plutôt petite. Elle est souvent en jean et baskets. Tu la reconnaîtras facile, elle sourit tout le temps. À plus !',
   'La description est juste, mais « salut », le tutoiement et « à plus » ne conviennent pas à une directrice d''établissement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S16 / EXPECTED
  ('e8af2749-db63-5df0-b6ef-549d5f093f8f', '6d2fed68-65ef-5ade-afb0-595889e186c3', 'EXPECTED',
   'Madame, je vous remercie de votre message. Il s''agit de ma sœur Awa, vingt-cinq ans, de petite taille, avec de longs cheveux noirs. Elle porte souvent un jean et des baskets. Bien cordialement.',
   'Vouvoiement, formule d''appel et formule finale : le registre convient, et la description est là.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S16 / EXCELLENT
  ('005960a6-fc16-51ef-bb7b-088b05d643c2', '6d2fed68-65ef-5ade-afb0-595889e186c3', 'EXCELLENT',
   'Madame, je vous remercie de votre message. La personne autorisée est ma sœur Awa, vingt-cinq ans, de petite taille, les cheveux noirs et longs, souvent attachés. Elle porte des lunettes rondes et vient généralement en jean et baskets. Bien cordialement.',
   'Le registre est identique à celui de la réponse attendue : ce qui change, c''est la précision — cheveux attachés, lunettes rondes — qui rend la personne réellement reconnaissable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S17 / INSUFFICIENT
  ('ba33dafe-6c07-500c-b034-84e05ebd7e06', '59939b3d-478c-50e6-bb00-45be9eaba933', 'INSUFFICIENT',
   'Monsieur, je me permets de vous informer que j''ai effectué la visite du logement situé rue Verte. Il comporte deux pièces lumineuses ainsi qu''une cuisine séparée. Je vous prie d''agréer mes salutations distinguées.',
   'Le registre administratif est absurde entre frère et sœur : le vouvoiement et « je vous prie d''agréer » sonnent faux.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S17 / EXPECTED
  ('7a34120d-d3d4-57c7-817d-e13ba096fc68', '59939b3d-478c-50e6-bb00-45be9eaba933', 'EXPECTED',
   'Oui, j''y suis allée hier ! C''est deux pièces, plutôt lumineuses, avec une cuisine séparée. Le salon donne sur une petite cour tranquille. Les murs sont blancs et le sol en parquet. Ça m''a plu.',
   'Tutoiement, ton naturel, exclamation : le registre convient à un frère, et l''appartement est décrit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S17 / EXCELLENT
  ('25c9ffc7-0823-5ca4-b8cf-ee87e2cad52c', '59939b3d-478c-50e6-bb00-45be9eaba933', 'EXCELLENT',
   'Oui, j''y suis allée hier ! Deux pièces bien lumineuses, une cuisine séparée, et le salon donne sur une petite cour très tranquille. Parquet partout, murs blancs, une grande fenêtre côté sud. Franchement, ça m''a plu, je crois que je vais le prendre.',
   'Le ton reste familier sans devenir relâché, et « franchement » place la confidence exactement là où un frère l''attend.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S18 / INSUFFICIENT
  ('901dbcf9-e7d6-5bbf-8122-e504a30bd0e8', 'daac1fc8-243f-5046-8270-3e4c11108c2b', 'INSUFFICIENT',
   'Salut ! Ouais c''est celui du fond, tu vois le grand portail vert ? Il est carrément grand, y a la place pour une voiture et des vélos. Le sol est en béton. Passe le voir quand tu veux, c''est ouvert !',
   'Le tutoiement et « ouais », « carrément » sont trop familiers pour un voisin qu''on croise seulement dans l''escalier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S18 / EXPECTED
  ('1152384e-7234-55be-997a-4ac0396f98cc', 'daac1fc8-243f-5046-8270-3e4c11108c2b', 'EXPECTED',
   'Bonjour, oui, celui du fond de la cour. C''est un garage assez grand, avec un portail vert en métal. Il y a la place pour une voiture et quelques vélos. Le sol est en béton et il y a une prise électrique.',
   'Le vouvoiement et le « bonjour » simple conviennent à un voisin : ni familier, ni administratif.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S18 / EXCELLENT
  ('d2262661-8fc6-58f9-aa84-81dc99e8dd9b', 'daac1fc8-243f-5046-8270-3e4c11108c2b', 'EXCELLENT',
   'Bonjour, oui, celui du fond de la cour. Un garage assez grand, fermé par un portail vert en métal. On y met une voiture et encore deux ou trois vélos le long du mur. Sol en béton, une prise électrique au fond. Il est sec, ce qui n''est pas le cas de tous.',
   'Le registre de voisinage est parfaitement tenu, et la dernière remarque rend service sans familiarité déplacée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S19 / INSUFFICIENT
  ('1eb144a4-8104-5b4d-a245-0ea719bbd386', '69fe32ec-8cdf-5f13-95d4-7ab5c9c13d61', 'INSUFFICIENT',
   'Bonjour, comme suite à votre demande, je vous informe que la personne concernée est âgée d''environ trente ans. Elle est de taille moyenne et porte des lunettes. Je reste à votre disposition pour tout complément.',
   'Entre amies proches, ce registre administratif est incompréhensible : il éteint complètement la confidence demandée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S19 / EXPECTED
  ('bbf123af-44e2-5ebe-815c-8def24622631', '69fe32ec-8cdf-5f13-95d4-7ab5c9c13d61', 'EXPECTED',
   'Alors : il a une trentaine d''années, il est grand, brun, avec des lunettes rondes. Il parle doucement et il rit beaucoup. Il porte toujours des chemises à carreaux. Voilà, tu sais tout !',
   'Tutoiement, absence de formule d''ouverture, exclamation : le ton est celui d''une amie, et la description y tient.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S19 / EXCELLENT
  ('afb68a3c-a7f2-56a6-95e4-1e863fdd6d9d', '69fe32ec-8cdf-5f13-95d4-7ab5c9c13d61', 'EXCELLENT',
   'Alors : une trentaine d''années, grand, brun, lunettes rondes, toujours en chemise à carreaux. Il parle très doucement, tellement que je lui fais répéter, et il rit pour un rien. Voilà, tu sais tout. Tu es contente ?',
   'Les phrases nominales et la relance finale sonnent exactement comme un message entre amies, sans jamais quitter la description.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S20 / INSUFFICIENT
  ('eaec16f3-368b-52e4-8270-e401a570f2bf', 'a9f94a27-0c28-54a8-8998-a84af1fa331b', 'INSUFFICIENT',
   'Coucou, alors c''est une valise rigide gris foncé, taille cabine, avec quatre roulettes. Y a un ruban jaune sur la poignée et un autocollant de Lisbonne dessus. Merci de checker vite, j''en ai besoin !',
   '« Coucou », « y a » et « checker » n''ont pas leur place dans une réponse à un service administratif.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S20 / EXPECTED
  ('3ff83c94-1d19-5723-a8df-641e8b2b9958', 'a9f94a27-0c28-54a8-8998-a84af1fa331b', 'EXPECTED',
   'Madame, Monsieur, il s''agit d''une valise rigide gris foncé, de taille cabine, munie de quatre roulettes. Un ruban jaune est noué à la poignée et un autocollant de Lisbonne figure sur le dessus. Je vous en remercie par avance.',
   'La formule d''appel reprend la leur, le vouvoiement est tenu, et la valise est décrite avec précision.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S20 / EXCELLENT
  ('5e32dc18-8ff9-55b4-a3a8-107e58c53495', 'a9f94a27-0c28-54a8-8998-a84af1fa331b', 'EXCELLENT',
   'Madame, Monsieur, il s''agit d''une valise rigide gris foncé, de taille cabine, munie de quatre roulettes dont une légèrement abîmée. Un ruban jaune est noué à la poignée et un autocollant de Lisbonne figure sur la face avant, près de la serrure.',
   'Le registre ne change pas d''un mot : ce qui distingue cette réponse, c''est la roulette abîmée et la position de l''autocollant, deux détails qui permettent d''identifier la valise à coup sûr.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S21 / INSUFFICIENT
  ('0ecfd6a4-fffb-550a-b290-61177ae481ae', '2c3c90ad-182e-5bf3-b203-cba873c25202', 'INSUFFICIENT',
   'Bonjour Monsieur, je confirme ma résidence à Nantes. Le quartier où je réside comporte plusieurs commerces de proximité ainsi qu''un parc public. Veuillez agréer l''expression de mes sentiments les meilleurs.',
   'Un camarade de classe qui reprend contact ne se vouvoie pas : ce registre le tient à distance et ferme l''échange.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S21 / EXPECTED
  ('0130e8c6-e241-5e10-be57-c198fcc841d6', '2c3c90ad-182e-5bf3-b203-cba873c25202', 'EXPECTED',
   'Salut ! Oui, toujours à Nantes. Mon quartier a beaucoup changé : il y a un grand parc où j''emmène les enfants, deux nouvelles boulangeries et un marché le dimanche. Les immeubles ont été repeints en clair.',
   'Le tutoiement et « salut » conviennent à un camarade, sans intimité excessive, et le quartier est décrit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S21 / EXCELLENT
  ('e3b60221-64df-5bc8-abbd-a4aa267715af', '2c3c90ad-182e-5bf3-b203-cba873c25202', 'EXCELLENT',
   'Salut ! Oui, toujours à Nantes. Le quartier a bien changé depuis l''époque : un grand parc a remplacé le parking, deux boulangeries ont ouvert, et il y a un marché le dimanche matin. Les immeubles ont été repeints en beige clair. Tu ne reconnaîtrais pas.',
   '« depuis l''époque » et la relance finale installent la complicité d''anciens camarades sans la familiarité d''amis quotidiens.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S22 / INSUFFICIENT
  ('71c0f157-bede-5680-82eb-c97348e1c2c2', 'a66af20f-84ab-5cc3-b5a8-429412a5a578', 'INSUFFICIENT',
   'Franchement ça fait deux ans que je vous le signale et rien ne bouge ! Le mur est noir de moisissure, le joint de la douche part en morceaux et il y a de l''eau au sol. C''est inadmissible, faites quelque chose.',
   'La description est exacte, mais le ton de reproche et l''exclamation quittent le registre attendu d''une réponse à un bailleur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S22 / EXPECTED
  ('52aac365-a0f7-5e1b-ab30-3db19059c6e6', 'a66af20f-84ab-5cc3-b5a8-429412a5a578', 'EXPECTED',
   'Madame, Monsieur, voici l''état de la pièce : le mur du fond présente des traces noires de moisissure sur environ un mètre. Le joint de la douche est fendu et de l''eau stagne au sol après chaque usage. Bien cordialement.',
   'Le registre reste formel et mesuré, et les faits décrits sont d''autant plus convaincants qu''ils ne sont pas criés.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S22 / EXCELLENT
  ('59f6a879-a803-548a-90a6-481e16fc855a', 'a66af20f-84ab-5cc3-b5a8-429412a5a578', 'EXCELLENT',
   'Madame, Monsieur, voici l''état de la pièce : le mur du fond présente des traces noires de moisissure sur environ un mètre de haut, à partir de la plinthe. Le joint de la douche est fendu sur toute sa longueur et de l''eau stagne au sol après chaque usage. Bien cordialement.',
   'Mêmes formules que la réponse attendue : la différence tient à la mesure et à la localisation des dégâts, pas à un surcroît de politesse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S23 / INSUFFICIENT
  ('7a2fd1e6-0b10-5725-972e-e52be5ea4b21', '9e2e4c30-b92a-53b4-be41-eda022e0a563', 'INSUFFICIENT',
   'Coucou les filles ! Alors j''les ai vus hier, ils sont trois, super jeunes, genre vingt ans max. Ils ont l''air complètement débordés mdr. Bon après ils sont gentils hein, faut pas non plus exagérer.',
   '« Coucou les filles », « mdr » et « genre » sont trop familiers pour un groupe de parents qu''on connaît peu — et exclut les pères.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S23 / EXPECTED
  ('2c0b4a67-1014-5162-8ff6-6af8e1d0c81c', '9e2e4c30-b92a-53b4-be41-eda022e0a563', 'EXPECTED',
   'Bonjour à tous, je les ai croisés hier. Ils sont trois, plutôt jeunes, autour de vingt-cinq ans. Une jeune femme brune semble diriger le groupe. Ils parlent calmement aux enfants et connaissent déjà les prénoms.',
   'Le ton cordial convient à un groupe, et l''équipe est décrite par des faits observés.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S23 / EXCELLENT
  ('2f77615f-5784-582c-9e9d-2d6682b20bd8', '9e2e4c30-b92a-53b4-be41-eda022e0a563', 'EXCELLENT',
   'Bonjour à tous, je les ai croisés hier à la sortie. Ils sont trois, autour de vingt-cinq ans. Une jeune femme brune semble mener le groupe : c''est elle qui fait l''appel. Ils parlent calmement et connaissaient déjà plusieurs prénoms dès le premier jour.',
   'Le registre de groupe est tenu, et chaque trait s''appuie sur une observation vérifiable plutôt que sur une impression.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S24 / INSUFFICIENT
  ('b6f91665-3356-5a00-8941-ac58781980c9', 'cd7bd720-ec22-5b36-a867-a04d4e3da723', 'INSUFFICIENT',
   'Salut ! Trop content de te lire. Alors je bosse dans un grand atelier avec plein de machines, c''est bruyant mais on est une bonne équipe. Viens voir quand tu veux, je te ferai visiter !',
   'Le tutoiement rompt l''usage installé entre vous, et « bosse » détonne dans un échange qui est resté au vouvoiement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S24 / EXPECTED
  ('945cac8a-9b2c-5785-82e8-27a27ad408ef', 'cd7bd720-ec22-5b36-a867-a04d4e3da723', 'EXPECTED',
   'Bonjour Monsieur, quel plaisir d''avoir de vos nouvelles. Je travaille dans un atelier de menuiserie d''environ deux cents mètres carrés. Il y a six établis, de grandes machines au fond et une odeur de bois partout. La lumière vient de verrières.',
   'Le vouvoiement est chaleureux sans raideur, et le lieu est décrit avec des détails sensibles.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S24 / EXCELLENT
  ('2202df87-52a8-50fb-a9c1-07225d27f3ce', 'cd7bd720-ec22-5b36-a867-a04d4e3da723', 'EXCELLENT',
   'Bonjour Monsieur, quel plaisir d''avoir de vos nouvelles. Je travaille dans un atelier de menuiserie d''environ deux cents mètres carrés : six établis alignés, les grandes machines au fond, et des verrières qui éclairent tout du matin au soir. Il y flotte en permanence une odeur de bois coupé.',
   'La déférence et la chaleur cohabitent, et la description sollicite la vue comme l''odorat sans jamais quitter le registre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S25 / INSUFFICIENT
  ('25ef4c13-dbb3-5757-8e98-e1b2105d8eee', '618925a0-2fd3-5d4b-8a1d-4cbc8b059143', 'INSUFFICIENT',
   'Hé oui je les connais par cœur ! Franchement ils sont nickel, super accueillants, tu vas voir. Par contre y en a un qui râle tout le temps, tu verras vite lequel, mais t''inquiète pas mon vieux, ça se gère.',
   '« Hé », « nickel » et « mon vieux » installent une familiarité que la relation professionnelle ne justifie pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S25 / EXPECTED
  ('5548ab75-0111-599a-9b76-67785f8c29bf', '618925a0-2fd3-5d4b-8a1d-4cbc8b059143', 'EXPECTED',
   'Bonjour, oui, je travaille souvent avec eux. Ils sont quatre, tous très expérimentés, avec une dizaine d''années de maison chacun. Ils répondent vite aux demandes et documentent beaucoup. Ils préfèrent les échanges écrits aux réunions.',
   'Le vouvoiement professionnel est exactement à sa place : ni distant, ni familier, et l''équipe est décrite utilement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S25 / EXCELLENT
  ('1f289e55-a445-59d8-a36c-4a420dda37e3', '618925a0-2fd3-5d4b-8a1d-4cbc8b059143', 'EXCELLENT',
   'Bonjour, oui, je travaille souvent avec eux. Ils sont quatre, très expérimentés, avec une dizaine d''années de maison chacun. Ils répondent vite et documentent tout. Un conseil : ils préfèrent nettement un message écrit à une réunion improvisée.',
   'Le registre professionnel est tenu et le conseil final rend service sans jamais glisser vers la connivence.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S26 / INSUFFICIENT
  ('cfc4754f-c360-5415-b5c9-c139f9392bda', '523d0eb0-12b5-58fa-ae48-8024f9fb92f5', 'INSUFFICIENT',
   'Bonjour, alors notre local c''est une grande pièce au rez-de-chaussée avec une cuisine à côté. On y range le matériel et on fait les réunions. Y a des toilettes aussi. Voilà, dites-nous si vous voulez autre chose.',
   'Le ton est trop relâché pour une administration : « alors », « y a », et aucune formule d''ouverture ni de clôture.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S26 / EXPECTED
  ('352c76a8-a829-50a6-af54-006c09d100f5', '523d0eb0-12b5-58fa-ae48-8024f9fb92f5', 'EXPECTED',
   'Madame, Monsieur, le local se compose d''une salle principale d''environ soixante mètres carrés au rez-de-chaussée, d''une cuisine attenante et de sanitaires. Une réserve accueille le matériel. Nous restons à votre disposition. Bien cordialement.',
   'La formule reprend la leur, le vouvoiement est tenu et le local est décrit pièce par pièce.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S26 / EXCELLENT
  ('b627920b-810c-53cc-9bc9-36164d47c6f2', '523d0eb0-12b5-58fa-ae48-8024f9fb92f5', 'EXCELLENT',
   'Madame, Monsieur, le local se compose d''une salle principale d''environ soixante mètres carrés au rez-de-chaussée, éclairée par trois fenêtres sur rue, d''une cuisine attenante et de sanitaires. Une réserve d''une dizaine de mètres carrés accueille le matériel. Bien cordialement.',
   'Le registre administratif est impeccable et chaque surface est chiffrée, ce qu''un recensement attend précisément.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S27 / INSUFFICIENT
  ('cceddb5a-169c-5edf-9d39-ac00105cb6dc', '87d1a014-562d-58a2-8d8e-8a0dc01ab04b', 'INSUFFICIENT',
   'Madame, votre petite-fille est âgée de sept ans. Elle manifeste un intérêt pour les activités manuelles et la lecture. Je vous prie de bien vouloir agréer l''expression de mes salutations respectueuses.',
   'Le registre administratif glace une relation familiale : « je vous prie d''agréer » ne correspond pas au vouvoiement chaleureux installé entre vous.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S27 / EXPECTED
  ('ef74be6c-a3ee-5076-9761-40bb71137e08', '87d1a014-562d-58a2-8d8e-8a0dc01ab04b', 'EXPECTED',
   'Bonjour, c''est très gentil d''y penser. Elle a sept ans et elle est très curieuse en ce moment. Elle adore dessiner et elle commence à lire seule. Elle est plutôt calme et elle aime les choses qu''on fait avec les mains.',
   'Le vouvoiement chaleureux convient exactement, et l''enfant est décrite en pensant à celle qui offre le cadeau.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S27 / EXCELLENT
  ('abf25b4c-5a2b-5716-96a2-65d14751d5d0', '87d1a014-562d-58a2-8d8e-8a0dc01ab04b', 'EXCELLENT',
   'Bonjour, c''est très gentil d''y penser. Elle a sept ans et elle est d''une curiosité inépuisable en ce moment. Elle dessine des heures entières, commence à lire seule le soir, et tout ce qui se fabrique avec les mains la passionne. Elle sera très touchée.',
   'La chaleur et le vouvoiement cohabitent naturellement, et la dernière phrase referme le message comme une belle-fille le ferait.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S28 / INSUFFICIENT
  ('8206825c-5160-5dfe-b909-108724d020f5', '69c39627-a193-5853-bc72-7123e451474b', 'INSUFFICIENT',
   'Bonjour ! Alors on était six au pôle ADV, avec deux alternants qui tournaient sur le CRM et un chef de projet côté SI. Super ambiance, on se marrait bien même quand ça chauffait en fin de mois.',
   'Les sigles internes sont incompréhensibles pour une recruteuse, et « on se marrait » quitte le registre professionnel.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S28 / EXPECTED
  ('80cbc3cc-1504-5fca-b17c-b0aae059f6cf', '69c39627-a193-5853-bc72-7123e451474b', 'EXPECTED',
   'Bonjour, bien sûr. Nous étions six personnes, dont deux en alternance. L''équipe réunissait des profils commerciaux et techniques, avec des âges très variés. Nous travaillions en lien direct avec les clients, dans une ambiance coopérative.',
   'Le registre professionnel est soigné, aucun sigle interne ne subsiste, et l''équipe est décrite de façon compréhensible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S28 / EXCELLENT
  ('8816d0de-d04a-5b80-92a5-93a710e20328', '69c39627-a193-5853-bc72-7123e451474b', 'EXCELLENT',
   'Bonjour, bien sûr. Nous étions six, dont deux en alternance, avec des profils à la fois commerciaux et techniques et des âges allant de vingt à cinquante-cinq ans. Le contact client était quotidien, ce qui nous obligeait à nous coordonner très souvent.',
   'Le registre est tenu, les âges chiffrés, et la dernière proposition décrit le fonctionnement du groupe sans employer un seul mot de jargon.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S29 / INSUFFICIENT
  ('0e1cb678-ae8b-5bcb-9bc6-948a893d6df7', 'e56c550d-ab9d-5cf2-b268-996096d8a351', 'INSUFFICIENT',
   'Bonjour, c''est vraiment une catastrophe, ce buffet venait de ma grand-mère et il est fichu. L''eau a tout gonflé, les portes ne ferment plus. J''espère que vous allez me rembourser rapidement parce que là c''est dur.',
   'L''émotion prend la place des faits : l''assureur ne peut rien instruire avec « c''est fichu » et « c''est dur ».', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S29 / EXPECTED
  ('e7a52578-8772-5c29-a60f-b9b5b3395075', 'e56c550d-ab9d-5cf2-b268-996096d8a351', 'EXPECTED',
   'Madame, Monsieur, le meuble endommagé est un buffet en chêne massif d''environ un mètre quatre-vingts de large et un mètre de haut. Le bas a gonflé sous l''effet de l''eau et les deux portes ne ferment plus. Bien cordialement.',
   'Le registre est formel, les faits sont donnés avec leurs mesures : le dossier peut être instruit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S29 / EXCELLENT
  ('1db00c5c-f20c-5aba-875f-9a867b4686f6', 'e56c550d-ab9d-5cf2-b268-996096d8a351', 'EXCELLENT',
   'Madame, Monsieur, le meuble endommagé est un buffet ancien en chêne massif, d''environ un mètre quatre-vingts de large sur un mètre de haut. La partie basse a gonflé sur toute sa longueur et les deux portes ne ferment plus. Le plateau supérieur est intact. Bien cordialement.',
   'Le registre factuel est tenu, et préciser ce qui est intact est exactement ce qu''un assureur attend d''une déclaration honnête.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S30 / INSUFFICIENT
  ('b66df66b-d991-5b37-9538-517f479e522c', 'ce4acb9b-c4d4-58c7-a58a-e1bbb70a6fc8', 'INSUFFICIENT',
   'Bonjour Monsieur, je me permets de vous répondre. C''est un VTT noir. Bon après franchement il gêne personne où il est, il est collé au mur ! Enfin bref, il est noir avec des autocollants. Merci d''avance à vous.',
   'Le message commence dans un registre formel puis glisse vers « bon après franchement » : la rupture de ton se remarque immédiatement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S30 / EXPECTED
  ('f3d1028c-60a6-534d-9a57-90bc283884ae', 'ce4acb9b-c4d4-58c7-a58a-e1bbb70a6fc8', 'EXPECTED',
   'Bonjour, il s''agit d''un vélo tout-terrain noir, de taille adulte, avec un cadre assez épais. Le guidon porte deux autocollants blancs et le pneu arrière est légèrement dégonflé. Je reste disponible si besoin.',
   'Un seul registre, poli et professionnel, tenu de la première à la dernière phrase.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C1-S30 / EXCELLENT
  ('4a455811-50eb-585b-996e-22f2268aefcb', 'ce4acb9b-c4d4-58c7-a58a-e1bbb70a6fc8', 'EXCELLENT',
   'Bonjour, il s''agit d''un vélo tout-terrain noir de taille adulte, au cadre épais et légèrement rayé sous la selle. Deux autocollants blancs sont collés sur le guidon et le pneu arrière est un peu dégonflé. Je reste disponible si vous avez besoin d''une précision.',
   'Le registre ne vacille jamais, et la description gagne en précision sans que le ton ne s''autorise la moindre familiarité.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S1 / INSUFFICIENT
  ('f933ff07-b723-5eda-8ffe-a2915597fd62', 'f8b9d2eb-92b9-5eea-b2b9-488409bc311e', 'INSUFFICIENT',
   'C''est le carton avec des affaires dedans, tu verras, il est assez lourd. Descends-le doucement parce qu''il y a des choses fragiles à l''intérieur. Merci beaucoup, tu me sauves la vie sur ce coup-là.',
   '« Le carton avec des affaires dedans » convient aux trois. Le colocataire ne sait toujours pas lequel descendre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S1 / EXPECTED
  ('dca7181a-33e4-5b02-b51c-e8203706b429', 'f8b9d2eb-92b9-5eea-b2b9-488409bc311e', 'EXPECTED',
   'C''est celui qui porte une croix au feutre rouge sur le dessus. Il est plus petit que les deux autres et fermé avec de la ficelle, pas du ruban adhésif. Les deux autres restent au garage.',
   'La croix rouge, la taille et la ficelle éliminent les deux autres : un seul carton correspond.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S1 / EXCELLENT
  ('c94ffaef-0f5a-53b5-ba51-bfeea6a0e359', 'f8b9d2eb-92b9-5eea-b2b9-488409bc311e', 'EXCELLENT',
   'C''est celui qui porte une croix au feutre rouge sur le dessus, le plus petit des trois, fermé avec de la ficelle et non du ruban adhésif. Il est posé contre le mur du fond. Les deux autres, plus grands et scotchés, restent au garage.',
   'Chaque trait écarte explicitement les deux autres cartons, et la position finit de lever toute hésitation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S2 / INSUFFICIENT
  ('081367c8-92b1-5246-8a58-dcee0d3b6821', 'f20f1c49-41f5-5f18-a9e9-3967e06051d4', 'INSUFFICIENT',
   'C''est ma collègue du bureau, celle qui est très sympa et qui parle beaucoup. Tu l''as forcément vue, elle était là toute la soirée. Elle viendra vers vingt heures, je crois qu''elle apporte un dessert.',
   '« Sympa » et « parle beaucoup » peuvent décrire les quatre. Aucun trait ne permet de choisir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S2 / EXPECTED
  ('98fb0d82-e424-5246-a55b-1767c5906f5a', 'f20f1c49-41f5-5f18-a9e9-3967e06051d4', 'EXPECTED',
   'C''est celle qui a les cheveux roux très courts et qui portait une veste jaune ce soir-là. Elle s''appelle Nadia. Elle est la plus grande des quatre et elle a un léger accent du Sud.',
   'Cheveux roux, veste jaune, prénom, taille, accent : chaque trait réduit le champ jusqu''à une seule personne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S2 / EXCELLENT
  ('aa327409-87d3-553d-b00c-787114d0c7e3', 'f20f1c49-41f5-5f18-a9e9-3967e06051d4', 'EXCELLENT',
   'C''est Nadia, celle qui a les cheveux roux coupés très court et qui portait une veste jaune ce soir-là. C''est la plus grande des quatre, et la seule qui ait un accent du Sud. Elle était assise à côté de ton frère.',
   '« La seule qui » et la place à table ne laissent aucune ambiguïté : trois marqueurs exclusifs plutôt que trois adjectifs.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S3 / INSUFFICIENT
  ('5295ab36-a1ce-5660-8381-a1bec040d315', '4433f886-7f3e-58c2-9492-ad2d618c72d2', 'INSUFFICIENT',
   'C''est une salle de réunion assez grande, avec une table et des chaises. Elle est claire et il y a un tableau. Tu ne peux pas la rater, elle est au deuxième comme je t''ai dit. Bon courage pour l''installation.',
   'Table, chaises, tableau : les cinq salles du deuxième ont tout cela. Le stagiaire devra les ouvrir une par une.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S3 / EXPECTED
  ('3d5456c9-dd0c-5232-84a0-02493e322ac0', '4433f886-7f3e-58c2-9492-ad2d618c72d2', 'EXPECTED',
   'C''est la salle du fond à droite, la seule qui ait deux portes. Elle s''appelle Mistral, le nom est écrit sur une plaque bleue. Elle est plus longue que les autres et donne sur le parking.',
   'Position, double porte, nom sur plaque, vue : le repère est unique et vérifiable depuis le couloir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S3 / EXCELLENT
  ('cc37e009-f244-5298-be94-0dcf8793e18c', '4433f886-7f3e-58c2-9492-ad2d618c72d2', 'EXCELLENT',
   'C''est la salle Mistral, au fond à droite en sortant de l''ascenseur : la seule du couloir à avoir deux portes. Une plaque bleue porte son nom. Elle est plus longue que les autres et ses fenêtres donnent sur le parking, pas sur la cour.',
   'Le point de départ du trajet est donné, et « pas sur la cour » écarte explicitement les autres salles.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S4 / INSUFFICIENT
  ('d269e3ed-84b1-5e84-9ca2-3009b2dfc5f8', '0b87735c-9071-57a5-bf58-234fad17ac15', 'INSUFFICIENT',
   'C''est le groupe des enfants qui partent en sortie, ils sont une dizaine avec leurs sacs à dos. Ils attendent dans la cour. Tu les verras, ils sont assez excités, c''est normal un jour de sortie.',
   'Les trois groupes partent en sortie, ont des sacs et attendent dans la cour. Rien ne permet de choisir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S4 / EXPECTED
  ('1df0a022-6871-562e-9f4a-3af6af4bccc1', '0b87735c-9071-57a5-bf58-234fad17ac15', 'EXPECTED',
   'C''est le groupe des six-huit ans, celui qui porte les gilets orange. Ils sont douze, c''est le plus nombreux des trois. Deux animateurs les accompagnent déjà et ils attendent près du portail vert.',
   'Âge, couleur de gilet, effectif, lieu d''attente : quatre traits qui n''appartiennent qu''à ce groupe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S4 / EXCELLENT
  ('49d0fd8b-6c68-54be-97b1-99c9e3f8399e', '0b87735c-9071-57a5-bf58-234fad17ac15', 'EXCELLENT',
   'C''est le groupe des six-huit ans, le seul en gilets orange. Ils sont douze, donc le plus nombreux des trois, et ils attendent déjà près du portail vert avec deux animateurs. Les deux autres groupes sont en gilets jaunes, côté gymnase.',
   'Les deux autres groupes sont nommés et écartés : l''animatrice ne peut plus se tromper de file.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S5 / INSUFFICIENT
  ('7ff2eee3-01b2-5732-9fa8-e7944a36c073', '562d65b2-163b-5bdb-b147-5695ef1817ce', 'INSUFFICIENT',
   'C''est le vélo qui fait du bruit quand on pédale, celui qui a besoin d''être révisé rapidement parce que je m''en sers tous les jours pour aller travailler. Merci de le regarder en premier si possible.',
   'Vous dites pourquoi, jamais lequel. Les deux vélos peuvent faire du bruit et servir tous les jours.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S5 / EXPECTED
  ('c6159abe-a6a8-5aef-bb37-2716b6e1f95c', '562d65b2-163b-5bdb-b147-5695ef1817ce', 'EXPECTED',
   'C''est le vélo bleu, celui qui a un porte-bagages à l''arrière. L''autre est vert et n''en a pas. Le bleu a aussi un panier avant et des pneus plus larges que le vert.',
   'La couleur et le porte-bagages suffisent, et l''autre vélo est explicitement écarté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S5 / EXCELLENT
  ('6c38579e-4ee0-51c0-a8c1-e6211c493c28', '562d65b2-163b-5bdb-b147-5695ef1817ce', 'EXCELLENT',
   'C''est le vélo bleu, le seul des deux à avoir un porte-bagages à l''arrière et un panier en osier devant. Ses pneus sont larges, ceux du vert sont fins. Le vert peut attendre la semaine prochaine.',
   'Chaque trait du bleu est opposé au vert, et la dernière phrase lève le dernier doute possible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S6 / INSUFFICIENT
  ('5ef795aa-8cc5-5d8c-8261-54ec0f7c6297', '221c9511-f7ae-5d66-aba6-f53dae8cf538', 'INSUFFICIENT',
   'C''est celui qui est bien situé, avec deux chambres et une cuisine séparée. Il est lumineux et le loyer est raisonnable pour le quartier. Vraiment, visite-le en premier, je pense qu''il te plaira beaucoup.',
   'Deux chambres, cuisine séparée, lumineux : ces traits se retrouvent dans plusieurs annonces de la même rue.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S6 / EXPECTED
  ('6379fe50-7b22-528f-9acd-cd685aaf6c4f', '221c9511-f7ae-5d66-aba6-f53dae8cf538', 'EXPECTED',
   'C''est celui qui est au dernier étage, avec une terrasse. Le bâtiment est en brique rouge, au numéro 18. Les trois autres sont dans des immeubles plus récents et n''ont pas d''extérieur.',
   'Dernier étage, terrasse, brique rouge, numéro : quatre traits, et les trois autres annonces sont écartées d''un coup.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S6 / EXCELLENT
  ('8fe19fd5-aab2-5ad2-ad01-12a1f9d8dec0', '221c9511-f7ae-5d66-aba6-f53dae8cf538', 'EXCELLENT',
   'C''est celui du 18, le seul en brique rouge de la rue. Il est au dernier étage et c''est le seul des quatre à avoir une terrasse. Les trois autres sont dans des immeubles récents et blancs, sans extérieur.',
   'Deux traits exclusifs — « le seul en brique », « le seul à avoir une terrasse » — suffisent, et le contraste avec les trois autres est explicite.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S7 / INSUFFICIENT
  ('2f711460-ef44-5522-b0db-6842a9025e71', '7c6bf611-5de8-5140-b87d-85a08722032f', 'INSUFFICIENT',
   'C''est la dame qui s''occupe des dossiers d''état civil, elle est très gentille et elle connaît bien mon cas. Explique-lui que tu viens de ma part, elle comprendra tout de suite de quoi il s''agit.',
   'Les trois personnes du comptoir peuvent s''occuper d''état civil et être gentilles. Votre fille devra demander à chacune.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S7 / EXPECTED
  ('f82598c7-2169-5bdd-bc4e-56c1c099850f', '7c6bf611-5de8-5140-b87d-85a08722032f', 'EXPECTED',
   'C''est la personne du guichet de gauche, une dame d''une cinquantaine d''années avec des lunettes rouges. Elle s''appelle Madame Fauré. Elle est la seule des trois à porter un badge bleu.',
   'Position, âge, lunettes, nom, badge : chaque élément est visible depuis la file d''attente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S7 / EXCELLENT
  ('05fec05c-2a94-5767-b8a7-31e194ce888a', '7c6bf611-5de8-5140-b87d-85a08722032f', 'EXCELLENT',
   'C''est Madame Fauré, au guichet de gauche : une dame d''une cinquantaine d''années, la seule des trois à porter des lunettes rouges et un badge bleu. Les deux autres sont beaucoup plus jeunes. Tu la verras en entrant.',
   'Deux traits exclusifs et un contraste d''âge : l''identification est immédiate, sans avoir à lire un badge de près.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S8 / INSUFFICIENT
  ('6c48b6fa-b777-5340-a0bb-0e465f69829f', '749e5212-5c40-5681-8594-aedea9097a43', 'INSUFFICIENT',
   'C''est le dossier du client de Bordeaux, celui dont on a parlé lundi avec le chiffrage à revoir. Il y a les devis dedans et le courrier de réponse. Tu verras, c''est assez épais, il y a beaucoup de pièces.',
   'Pour reconnaître ce dossier, il faudrait ouvrir chacun de la pile. Le contenu ne se voit pas de l''extérieur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S8 / EXPECTED
  ('7e8bfac7-d0f9-51b2-b5c2-563a169d64f3', '749e5212-5c40-5681-8594-aedea9097a43', 'EXPECTED',
   'C''est le dossier à couverture orange, le seul de cette couleur dans la pile. Une étiquette blanche est collée sur la tranche avec le mot « Bordeaux » écrit dessus. Il est assez épais.',
   'La couleur et l''étiquette sur la tranche se voient sans ouvrir un seul dossier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S8 / EXCELLENT
  ('044c0e25-234a-5ed1-8421-16f30cd0f610', '749e5212-5c40-5681-8594-aedea9097a43', 'EXCELLENT',
   'C''est le dossier à couverture orange, le seul de cette couleur dans la pile. Sur la tranche, une étiquette blanche porte le mot « Bordeaux ». C''est aussi le plus épais et il est deuxième en partant du haut.',
   'La position dans la pile s''ajoute aux signes visibles : la collègue n''a même pas à chercher la couleur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S9 / INSUFFICIENT
  ('f926429a-c1f7-5761-911c-2fd26f4287ee', '661232ff-4c2b-5822-b3a7-0c3e2ee936d1', 'INSUFFICIENT',
   'Descends à l''arrêt Gambetta, c''est celui qui est le plus près de chez moi. Je serai là pour t''attendre de toute façon, donc ne t''inquiète pas trop, tu me verras en descendant du bus.',
   'Si les deux arrêts s''appellent presque pareil, le nom seul ne tranche pas — et « près de chez moi » ne l''aide pas dans le bus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S9 / EXPECTED
  ('bd69d7b0-5a72-5559-b9a8-dea3114c4548', '661232ff-4c2b-5822-b3a7-0c3e2ee936d1', 'EXPECTED',
   'Descends au deuxième, « Gambetta-Église », pas à « Gambetta-Mairie ». Tu reconnaîtras l''arrêt à la grande église en pierre juste en face, et il y a une boulangerie à l''angle. L''autre arrêt donne sur un rond-point.',
   'Les deux noms sont distingués, et deux repères visuels permettent de vérifier depuis le bus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S9 / EXCELLENT
  ('4128abe2-9f3b-5202-8345-1348662c741e', '661232ff-4c2b-5822-b3a7-0c3e2ee936d1', 'EXCELLENT',
   'Descends au deuxième, « Gambetta-Église », pas à « Gambetta-Mairie ». Dès que tu vois une grande église en pierre sur ta droite et une boulangerie à l''angle, c''est là. L''autre arrêt, avant, donne sur un rond-point et une station-service.',
   'L''ordre des arrêts, le côté du bus et le contraste avec l''arrêt précédent rendent l''erreur impossible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S10 / INSUFFICIENT
  ('f02f384e-15b9-5cba-8055-0f8ff0f5aee1', '701ca849-0278-59b1-a342-4fb3e06a31c0', 'INSUFFICIENT',
   'C''est l''équipe en bleu, celle où joue mon fils. Ils sont assez jeunes et ils jouent plutôt bien. Tu devrais les reconnaître sans problème, ils sont très motivés et ils crient beaucoup pendant les matchs.',
   'Sur six équipes, plusieurs peuvent porter du bleu et être jeunes et motivées. Le repère n''est pas exclusif.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S10 / EXPECTED
  ('c7cbbd78-0258-5ae1-8b16-4825f1b1ca97', '701ca849-0278-59b1-a342-4fb3e06a31c0', 'EXPECTED',
   'C''est l''équipe en maillots bleus à bandes blanches, la seule qui ait des bandes. Ils jouent sur le terrain du fond, à gauche. Leur entraîneur porte une casquette rouge et reste debout tout le match.',
   'Les bandes blanches rendent le bleu exclusif, et le terrain et l''entraîneur ajoutent deux repères indépendants.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S10 / EXCELLENT
  ('ae8968da-d6e9-5f99-ba7c-e70766d2a1de', '701ca849-0278-59b1-a342-4fb3e06a31c0', 'EXCELLENT',
   'C''est la seule équipe en maillots bleus à bandes blanches — les deux autres équipes en bleu sont unies. Ils jouent sur le terrain du fond à gauche, et leur entraîneur, en casquette rouge, reste debout tout le match.',
   'Les équipes concurrentes sont nommées et écartées : « les deux autres équipes en bleu sont unies » lève exactement le doute qui restait.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S11 / INSUFFICIENT
  ('313a221e-7707-5995-a219-c30b4a2b1238', 'a50adaac-52e2-5dc7-8000-b3496293824a', 'INSUFFICIENT',
   'C''est le grand arbre du jardin, celui dont les branches sont devenues vraiment trop longues cette année. Il faudrait le tailler avant l''automne parce qu''il fait beaucoup d''ombre sur les fenêtres du rez-de-chaussée.',
   '« Le grand arbre » et « branches trop longues » peuvent désigner la moitié du jardin. Le jardinier ne peut pas choisir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S11 / EXPECTED
  ('182b4785-3198-53a9-9953-e3e31015c435', 'a50adaac-52e2-5dc7-8000-b3496293824a', 'EXPECTED',
   'C''est celui qui se trouve près du portail, à droite en entrant. C''est un tilleul, le seul du jardin, les autres sont des érables. Son tronc est penché vers la rue et une branche touche le lampadaire.',
   'L''essence est exclusive, la position la confirme, et la branche sur le lampadaire dit précisément ce qui gêne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S11 / EXCELLENT
  ('942f20dd-91e6-5f9f-8036-9dfc8cb73ec3', 'a50adaac-52e2-5dc7-8000-b3496293824a', 'EXCELLENT',
   'C''est celui qui se trouve près du portail, à droite en entrant : le seul tilleul du jardin, tous les autres sont des érables. Son tronc penche nettement vers la rue et sa plus grosse branche touche le lampadaire. C''est celle-là qui pose problème.',
   'L''arbre est identifié par trois voies indépendantes, et la dernière phrase désigne même la branche à couper.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S12 / INSUFFICIENT
  ('8170450d-ce0a-5db4-9a5b-d73d2f485563', '49d22f17-1b87-5de6-a8c3-9f58a5fa4166', 'INSUFFICIENT',
   'Il est comme sur la photo que je t''avais envoyée, avec ses cheveux longs et son air un peu timide. Tu le reconnaîtras facilement, il ne sort jamais dans les premiers, il traîne toujours un peu.',
   'Vous renvoyez à une photo de deux ans. À cet âge, c''est précisément ce qui ne marche plus : elle cherchera un enfant qui n''existe plus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S12 / EXPECTED
  ('22901461-adc5-55d7-8bf9-2ae45df59451', '49d22f17-1b87-5de6-a8c3-9f58a5fa4166', 'EXPECTED',
   'Il a beaucoup changé depuis : il a coupé ses cheveux très court et il a pris vingt centimètres. Il porte un blouson vert et un cartable bleu. Il est maintenant l''un des plus grands de la classe.',
   'Ce qui a changé est dit en premier, puis deux repères du jour permettent l''identification immédiate.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S12 / EXCELLENT
  ('fcd9597f-1a69-5c1e-9ba9-de5416899ddf', '49d22f17-1b87-5de6-a8c3-9f58a5fa4166', 'EXCELLENT',
   'Il a beaucoup changé depuis : cheveux coupés très court, et vingt centimètres de plus — c''est l''un des plus grands de la classe maintenant. Aujourd''hui il porte un blouson vert et un cartable bleu à roulettes. Oublie la photo, elle ne sert plus.',
   'La dernière phrase écarte franchement le repère périmé, ce qui est l''essentiel quand une information ancienne peut induire en erreur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S13 / INSUFFICIENT
  ('282ebf37-3e8e-598f-b8eb-de6cd48e5fa6', '7b6ab1d1-35d5-5c93-bbad-b483d1eaa162', 'INSUFFICIENT',
   'C''est la cave numéro 7, vous ne pouvez pas vous tromper, le numéro est marqué sur la porte. Prenez tout ce qu''il y a dedans sauf le vélo rouge, il appartient à mon voisin du dessus.',
   'Il vous dit que deux portes n''ont pas de numéro. Miser sur le seul chiffre, c''est risquer qu''il ouvre une cave voisine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S13 / EXPECTED
  ('1db4b9a9-a5da-5ec0-965c-67b5166c15a5', '7b6ab1d1-35d5-5c93-bbad-b483d1eaa162', 'EXPECTED',
   'C''est la cave 7, mais si le numéro a disparu, c''est la troisième porte à gauche en descendant l''escalier. Elle est en bois clair et fermée par un cadenas noir. Les autres ont des serrures classiques.',
   'La réponse anticipe le numéro manquant et donne deux repères de secours indépendants.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S13 / EXCELLENT
  ('03931e39-8090-537d-ae48-1553853c5129', '7b6ab1d1-35d5-5c93-bbad-b483d1eaa162', 'EXCELLENT',
   'C''est la cave 7, mais si le numéro a disparu, comptez : c''est la troisième porte à gauche en descendant l''escalier. Elle est en bois clair, plus claire que ses voisines, et fermée par un gros cadenas noir — c''est la seule à en avoir un.',
   'Le repère de secours est rendu exclusif (« la seule à en avoir un »), ce qui règle le problème même si deux portes sont sans numéro.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S14 / INSUFFICIENT
  ('23426767-c7fc-526e-b8a6-a467d8de1fd5', '5bc4044a-2b7a-54d8-b798-d24da5349a31', 'INSUFFICIENT',
   'C''est la réunion de l''école, celle dont je t''avais parlé la semaine dernière. Il y aura des parents et des enseignants, comme d''habitude. Note bien l''heure, ça commence tôt et ils ferment les portes après.',
   '« La réunion de l''école » désigne les deux, et « des parents et des enseignants » aussi. Rien ne permet de choisir la salle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S14 / EXPECTED
  ('8a663ee5-38a5-5399-82ad-d8029eefcc00', '5bc4044a-2b7a-54d8-b798-d24da5349a31', 'EXPECTED',
   'C''est celle des parents de CE2 : une vingtaine de parents et la maîtresse, dans la classe de Madame Ould. Le conseil d''école, lui, réunit les délégués et le directeur en salle polyvalente. Ne te trompe pas de porte.',
   'Les deux réunions sont distinguées par leur composition et leur salle : la confusion devient impossible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S14 / EXCELLENT
  ('8160fd31-f2ee-5556-b2a4-2ae0a4522c88', '5bc4044a-2b7a-54d8-b798-d24da5349a31', 'EXCELLENT',
   'C''est celle des parents de CE2 : une vingtaine de parents, presque tous des mères, et la maîtresse, dans la classe de Madame Ould au premier étage. Le conseil d''école, lui, ne réunit que les quatre délégués et le directeur, en salle polyvalente.',
   'La composition de chaque groupe est précise et contrastée — vingt parents contre quatre délégués —, et chaque salle est située.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S15 / INSUFFICIENT
  ('a26679b6-bff6-556f-b997-08f662d6751b', 'f758331a-0b4e-5efa-98b1-362635b077f7', 'INSUFFICIENT',
   'C''est la pièce qui est cassée à l''intérieur du four, celle qui empêche la porte de bien tenir. Je n''ai plus la notice mais je peux vous donner le numéro de série de l''appareil si ça peut vous aider à trouver.',
   'Ils vous disent qu''ils n''ont pas de référence et que trois versions existent. Renvoyer au numéro de série ne les avance pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S15 / EXPECTED
  ('04d696e4-4d80-52f7-a68d-d44b81487c1a', 'f758331a-0b4e-5efa-98b1-362635b077f7', 'EXPECTED',
   'La pièce se trouve en bas à gauche de la porte : c''est la charnière. Elle mesure environ dix centimètres, elle est en métal gris avec deux trous de vis. Un petit ressort est fixé dessus.',
   'Emplacement, nom, dimension, matière et détail du ressort : la pièce est identifiable sans aucune référence.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C9-S15 / EXCELLENT
  ('649089b5-6c03-513c-b972-e118cae9d844', 'f758331a-0b4e-5efa-98b1-362635b077f7', 'EXCELLENT',
   'La pièce se trouve en bas à gauche de la porte : la charnière. Environ dix centimètres, en métal gris, percée de deux trous de vis alignés, avec un ressort à boudin fixé dessus. Celle de droite est identique mais intacte.',
   'Le type de ressort précise la version, et signaler que la pièce symétrique est intacte donne au vendeur un point de comparaison.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S1 / INSUFFICIENT
  ('b01cf1f5-f356-527b-b937-e5edbeac70a1', '7c572584-8d15-5af3-8507-013b5ca91ccf', 'INSUFFICIENT',
   'C''est un fauteuil en tissu beige, acheté en 2015 chez un revendeur de Lyon, avec une armature en hêtre, quatre pieds tournés, un dossier haut, des accoudoirs, une assise de cinquante centimètres et une housse lavable.',
   'Tout est exact, mais rien n''est choisi : l''année d''achat et l''essence du bois n''apprennent rien à qui meuble une chambre d''enfant.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S1 / EXPECTED
  ('0fbd9ef6-4778-56ac-ae20-bf6167d0bc24', '7c572584-8d15-5af3-8507-013b5ca91ccf', 'EXPECTED',
   'Pour une chambre d''enfant, il conviendra : il est bas, donc elle montera dessus toute seule. La housse se lave en machine. Il n''a pas d''angle dur et il est assez léger pour être déplacé facilement.',
   'Chaque trait retenu répond au projet : hauteur, lavage, sécurité, poids. Le reste est laissé de côté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S1 / EXCELLENT
  ('b4906ea7-a35d-59a0-bd8d-9d41a2278a31', '7c572584-8d15-5af3-8507-013b5ca91ccf', 'EXCELLENT',
   'Pour une chambre d''enfant, il conviendra : assise basse, à quarante centimètres du sol, donc elle y grimpera seule. La housse passe en machine à trente degrés. Aucun angle dur, et il pèse à peine cinq kilos, on le déplace d''une main.',
   'Les mêmes traits, chiffrés : la hauteur, la température de lavage et le poids transforment un avis en information utilisable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S2 / INSUFFICIENT
  ('3628d310-edd6-52f0-b890-36a1cb080095', '74d1561b-b30b-5e6a-8621-5af663b8eb9e', 'INSUFFICIENT',
   'C''est un quartier très vivant, avec trois bars à bières, une salle de concert qui programme du rock le week-end, un skatepark et beaucoup d''étudiants. Les loyers sont raisonnables et il y a un grand parking souterrain.',
   'Tout est vrai, mais rien n''est trié : bars, skatepark et parking ne disent rien à un couple de quatre-vingts ans sans voiture.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S2 / EXPECTED
  ('a9e3c841-582a-50fe-9776-d9ec2f6d34f9', '74d1561b-b30b-5e6a-8621-5af663b8eb9e', 'EXPECTED',
   'Pour eux, l''essentiel est que tout soit à pied : la pharmacie, la boulangerie et le médecin sont dans la même rue. Le bus passe toutes les dix minutes. Les trottoirs sont larges et il y a des bancs.',
   'Commerces de proximité, transport, trottoirs, bancs : chaque trait retenu répond à leur situation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S2 / EXCELLENT
  ('e0803cd1-9d51-5af9-a3db-ca7066a9e717', '74d1561b-b30b-5e6a-8621-5af663b8eb9e', 'EXCELLENT',
   'Pour eux, l''essentiel est que tout soit à pied : pharmacie, boulangerie et médecin dans la même rue, à moins de deux cents mètres. Le bus passe toutes les dix minutes et s''arrête devant. Trottoirs larges, sans marche, et un banc tous les cinquante mètres.',
   'Les distances chiffrées et « sans marche » montrent que la sélection est gouvernée par leur situation réelle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S3 / INSUFFICIENT
  ('8a63f2b5-3466-5e0b-8482-c955eb69e4ad', 'ea6d25c5-a396-5134-ab86-2f34e4a05663', 'INSUFFICIENT',
   'Elle s''appelle Rachida, elle a deux enfants, elle est arrivée dans le service en janvier après une reconversion. Elle est très compétente sur les dossiers export et tout le monde l''apprécie beaucoup dans l''équipe.',
   'Sa vie de famille et ses compétences professionnelles ne servent à rien pour décider d''un covoiturage.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S3 / EXPECTED
  ('4107df3e-764b-543a-9317-aaac1c87c7fb', 'ea6d25c5-a396-5134-ab86-2f34e4a05663', 'EXPECTED',
   'Pour un trajet partagé, elle est parfaite : elle habite sur ta route, à Vaise. Elle commence à sept heures comme toi. Elle voyage léger, juste un sac. Et elle ne fume pas.',
   'Domicile, horaire, encombrement, tabac : chaque trait pèse sur la décision, et rien d''autre n''est dit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S3 / EXCELLENT
  ('1732b9d9-91cc-5e3b-85e5-c682b64a3eb8', 'ea6d25c5-a396-5134-ab86-2f34e4a05663', 'EXCELLENT',
   'Pour un trajet partagé, elle est parfaite : elle habite à Vaise, juste sur ta route, et son arrêt est à deux minutes du rond-point. Elle commence à sept heures comme toi, voyage avec un seul sac à dos, et ne fume pas.',
   'La sélection est identique mais chaque élément est situé : « deux minutes du rond-point » répond à sa vraie question, le détour.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S4 / INSUFFICIENT
  ('964be053-d084-5106-9757-afdc50e58dbc', '63e21f7a-b69e-54c8-958d-c179b0d67bb3', 'INSUFFICIENT',
   'C''est un studio au quatrième étage d''un immeuble haussmannien de 1890, avec des moulures au plafond, un parquet à point de Hongrie et une belle vue sur les toits. La cage d''escalier a été refaite l''an dernier.',
   'Moulures, parquet ancien et vue sont réels, mais aucun ne pèse dans la décision d''un étudiant au budget serré.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S4 / EXPECTED
  ('55b105c0-af04-5d50-8fd9-2897771be2a9', '63e21f7a-b69e-54c8-958d-c179b0d67bb3', 'EXPECTED',
   'Pour un étudiant, ce qui compte : il est meublé, donc rien à acheter. La fac est à dix minutes à pied. Les charges comprennent le chauffage. Il y a une laverie au rez-de-chaussée et la fibre est installée.',
   'Meublé, distance, charges, laverie, internet : chaque trait retenu répond au budget ou aux études.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S4 / EXCELLENT
  ('ece2f5dc-eda1-5f91-a531-e0967d9ec8c6', '63e21f7a-b69e-54c8-958d-c179b0d67bb3', 'EXCELLENT',
   'Pour un étudiant, ce qui compte : il est meublé, donc rien à acheter en arrivant. La fac est à dix minutes à pied, sans bus. Le chauffage est compris dans les charges, ce qui évite les mauvaises surprises l''hiver. Laverie en bas, fibre installée.',
   '« Sans bus » et « évite les mauvaises surprises l''hiver » traduisent chaque trait en économie réelle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S5 / INSUFFICIENT
  ('407595a6-5d82-54b8-9d28-3869be479e56', 'ee26b63a-b35f-5899-9521-6304f6b7999c', 'INSUFFICIENT',
   'Nous sommes une famille très unie qui se retrouve chaque été. Mon frère vient de Belgique, ma sœur est enseignante et adore l''histoire médiévale. Nous logeons à l''hôtel du Parc et nous resterons quatre jours dans la région.',
   'Leur hôtel et les goûts de votre sœur ne changent ni le parcours ni le rythme. Rien n''est trié selon le besoin exprimé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S5 / EXPECTED
  ('e6361b02-3b78-5cdb-bf83-de6bfc296b74', 'ee26b63a-b35f-5899-9521-6304f6b7999c', 'EXPECTED',
   'Nous serons sept, et ce qui compte : deux enfants de cinq et sept ans, et ma mère qui marche lentement et doit s''asseoir souvent. Trois adultes peuvent porter. Nous comprenons tous le français.',
   'Âges, mobilité, capacité à porter, langue : chaque trait a un effet direct sur le parcours ou le rythme.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S5 / EXCELLENT
  ('4d74d72d-fd44-5aff-aabd-d6ff5ff9d406', 'ee26b63a-b35f-5899-9521-6304f6b7999c', 'EXCELLENT',
   'Nous serons sept, et ce qui compte : deux enfants de cinq et sept ans, et ma mère qui marche lentement et a besoin de s''asseoir toutes les vingt minutes. Trois adultes peuvent porter ou pousser. Nous comprenons tous le français, sans besoin de traduction.',
   '« Toutes les vingt minutes » donne au guide une contrainte qu''il peut réellement intégrer à son parcours.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S6 / INSUFFICIENT
  ('351b331e-cf9a-5ea2-b1d5-7f968154e581', 'be9e390a-6006-58cb-93b4-ba7f355bfeff', 'INSUFFICIENT',
   'Elle a quinze programmes dont un programme laine et un programme rapide de trente minutes. L''essorage monte à mille quatre cents tours. Il y a un départ différé et un affichage du temps restant. Classe énergétique A.',
   'Les programmes n''ont aucun rapport avec la question posée : monter la machine au troisième sans ascenseur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S6 / EXPECTED
  ('a302625b-76c5-5b6b-99ae-f5966487991c', 'be9e390a-6006-58cb-93b4-ba7f355bfeff', 'EXPECTED',
   'Pour la monter, voici l''essentiel : elle pèse environ soixante-dix kilos, il faudra être deux. Elle mesure quatre-vingt-cinq centimètres de haut sur soixante de large. Le tambour se bloque avec les vis que je vous donnerai.',
   'Poids, dimensions, blocage du tambour : chaque trait sert au transport, comme il a été demandé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S6 / EXCELLENT
  ('06f4a91c-fe96-54f5-9b5f-f81313c235e3', 'be9e390a-6006-58cb-93b4-ba7f355bfeff', 'EXCELLENT',
   'Pour la monter, voici l''essentiel : environ soixante-dix kilos, donc à deux obligatoirement. Quatre-vingt-cinq centimètres de haut sur soixante de large et soixante de profondeur — mesurez votre palier. Je vous donnerai les vis de blocage du tambour, indispensables en voiture.',
   'La troisième dimension et le conseil de mesurer le palier anticipent le problème réel, sans sortir du cadre demandé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S7 / INSUFFICIENT
  ('8be8b57e-e2e7-5594-a57d-668fefefc694', '382c9390-122b-51fe-803e-4265660ad591', 'INSUFFICIENT',
   'Elle a les yeux verts, un petit grain de beauté sous l''œil gauche et une voix assez grave. Elle est très drôle et un peu bavarde, tu vas l''adorer. Elle porte souvent du parfum à la vanille.',
   'Yeux, grain de beauté, voix et parfum ne se perçoivent qu''à un mètre : inutilisables pour repérer quelqu''un dans une gare.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S7 / EXPECTED
  ('c94c5f3a-2cd1-53a5-a8c4-e2a7d7a030c2', '382c9390-122b-51fe-803e-4265660ad591', 'EXPECTED',
   'Dans la foule, tu repéreras d''abord sa taille : elle fait presque un mètre quatre-vingts. Elle a de longs cheveux gris attachés et elle portera un manteau rouge vif. Elle tire une valise jaune.',
   'Taille, cheveux, couleur de manteau, valise : quatre traits visibles à vingt mètres.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S7 / EXCELLENT
  ('3bde480d-b2df-5cb4-954d-3ea08b9eff52', '382c9390-122b-51fe-803e-4265660ad591', 'EXCELLENT',
   'Dans la foule, tu repéreras d''abord sa taille : presque un mètre quatre-vingts, elle dépasse tout le monde. Longs cheveux gris attachés, manteau rouge vif, et une valise jaune à coque rigide. Ce sont trois couleurs qu''on ne rate pas de loin.',
   'Le candidat nomme le critère qui a gouverné son tri — « qu''on ne rate pas de loin » — ce qui rend la sélection explicite.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S8 / INSUFFICIENT
  ('dace222d-0f5e-5396-a34d-5e4b9aa00ece', '36ea5488-c447-5b10-b3c5-5f138596ecca', 'INSUFFICIENT',
   'C''est une belle salle claire de soixante mètres carrés, repeinte l''an dernier en blanc cassé. Les chaises sont neuves et confortables, il y a un tableau blanc et une machine à café. L''acoustique est excellente.',
   'Peinture, chaises et acoustique ne disent rien de l''accessibilité, seule question posée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S8 / EXPECTED
  ('6cea79ee-26e7-50d3-8ac3-5345fd90aacd', '36ea5488-c447-5b10-b3c5-5f138596ecca', 'EXPECTED',
   'Pour des fauteuils, voici les points décisifs : l''entrée est de plain-pied, sans aucune marche. La porte fait quatre-vingt-dix centimètres de large. Les toilettes sont adaptées. On peut circuler entre les tables sans les déplacer.',
   'Plain-pied, largeur de porte, toilettes, circulation : chaque trait décide de l''accessibilité.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S8 / EXCELLENT
  ('dc881dc9-64d2-5027-8ecd-05014208d956', '36ea5488-c447-5b10-b3c5-5f138596ecca', 'EXCELLENT',
   'Pour des fauteuils, voici les points décisifs : entrée de plain-pied depuis le trottoir, sans marche ni ressaut. Porte de quatre-vingt-dix centimètres, toilettes adaptées avec barre d''appui. Entre les tables, il reste un mètre vingt, suffisant pour se croiser.',
   'Chaque point est chiffré et « suffisant pour se croiser » traduit la mesure en usage réel.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S9 / INSUFFICIENT
  ('89e97647-103d-52da-9b71-fe13bc1ac54b', '494b40f1-5c21-56b2-9b84-fa248643d962', 'INSUFFICIENT',
   'Le service existe depuis 2009 et a été réorganisé deux fois, la dernière en 2021 après le départ de l''ancien responsable. L''ambiance s''est beaucoup améliorée depuis. Nous avons même reçu un prix interne l''année dernière.',
   'L''histoire du service est intéressante, mais elle n''aide pas quelqu''un qui doit savoir à qui s''adresser dès lundi.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S9 / EXPECTED
  ('6deb7a1c-63ae-5847-be89-0e2843a4cf9d', '494b40f1-5c21-56b2-9b84-fa248643d962', 'EXPECTED',
   'En une semaine, l''essentiel : nous sommes six. Pour les questions techniques, voyez Salim, il est au bureau du fond. Pour les plannings, c''est Claire. Le responsable n''est là que le mardi et le jeudi.',
   'Effectif, deux interlocuteurs nommés et situés, disponibilité du responsable : tout sert dès le premier jour.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S9 / EXCELLENT
  ('7dcb5a55-4191-5363-a64c-0b25939eda25', '494b40f1-5c21-56b2-9b84-fa248643d962', 'EXCELLENT',
   'En une semaine, l''essentiel : nous sommes six. Questions techniques, voyez Salim, bureau du fond, il répond toujours. Plannings et congés, c''est Claire, à l''entrée. Le responsable ne vient que mardi et jeudi, donc gardez vos validations pour ces jours-là.',
   'La dernière phrase transforme une information en conseil d''organisation, ce qui est exactement ce qu''un remplaçant peut en faire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S10 / INSUFFICIENT
  ('25d45649-f781-54d6-ab21-b7a79b82eca1', '947f4a2d-2196-52ce-ac8c-3fb5e4ffee00', 'INSUFFICIENT',
   'C''est un boîtier APS-C de vingt-quatre mégapixels, avec une monture à baïonnette, un capteur stabilisé sur cinq axes, une plage ISO de 100 à 25600 et un obturateur au 1/4000. L''autofocus a 425 collimateurs.',
   'Chaque chiffre est juste, et aucun ne veut rien dire pour quelqu''un qui n''y connaît rien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S10 / EXPECTED
  ('10de96e7-97bf-50af-becc-d2fdad87653f', '947f4a2d-2196-52ce-ac8c-3fb5e4ffee00', 'EXPECTED',
   'Pour débuter, il est très bien : il a un mode automatique qui décide tout à ta place. Il est léger, tu le porteras autour du cou sans fatigue. L''écran s''oriente pour viser de haut ou de bas. La batterie tient deux jours.',
   'Mode automatique, poids, écran, autonomie : quatre traits qu''un débutant comprend et peut vérifier lui-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S10 / EXCELLENT
  ('30563a66-23ba-5752-afbf-00a01ca3ff1a', '947f4a2d-2196-52ce-ac8c-3fb5e4ffee00', 'EXCELLENT',
   'Pour débuter, il est très bien : un mode automatique décide tout à ta place, tu appuies et c''est net. Il pèse quatre cents grammes, tu l''oublieras autour du cou. L''écran s''oriente pour viser en hauteur. La batterie tient deux jours de balade.',
   '« Tu appuies et c''est net », « deux jours de balade » : chaque trait est traduit en expérience concrète plutôt qu''en spécification.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S11 / INSUFFICIENT
  ('af9bf71d-e62a-5c58-958b-14b7f0d32cf0', 'b80e275c-c3b6-5739-a613-0a6391ad4749', 'INSUFFICIENT',
   'Il y a un massif de rosiers anciens le long de la terrasse, un magnolia qui fleurit en avril et une bordure de lavandes. Le potager a été travaillé pendant des années, la terre y est excellente.',
   'Rosiers, magnolia et qualité de la terre ne répondent pas à la question posée : un grand chien qui saute.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S11 / EXPECTED
  ('4ec2a0b9-4607-5f88-8f41-ecdaae8759b4', 'b80e275c-c3b6-5739-a613-0a6391ad4749', 'EXPECTED',
   'Avec un grand chien, ce qui compte : le jardin fait environ deux cents mètres carrés, entièrement clos. La clôture fait un mètre quatre-vingts, il ne sautera pas par-dessus. Le portail ferme à clé. Le sol est en herbe, pas en gravier.',
   'Surface, hauteur de clôture, portail, nature du sol : tous les traits retenus concernent le chien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S11 / EXCELLENT
  ('34ad4d0b-ae13-5ca3-81d1-33b9d6ee7455', 'b80e275c-c3b6-5739-a613-0a6391ad4749', 'EXCELLENT',
   'Avec un grand chien, ce qui compte : deux cents mètres carrés entièrement clos, avec une clôture d''un mètre quatre-vingts qu''il ne franchira pas. Le portail ferme à clé et il n''y a aucun passage sous la haie. Sol en herbe, et un coin d''ombre sous le tilleul.',
   '« Aucun passage sous la haie » anticipe le vrai défaut des jardins clos, et le coin d''ombre reste un trait utile au chien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S12 / INSUFFICIENT
  ('b2a4d767-acef-53f9-b4b1-326e876ade3f', '20955a66-2d8d-57b3-bb93-d0d256bf8659', 'INSUFFICIENT',
   'Il a refait toute l''installation électrique d''un immeuble de douze logements l''an dernier, et il travaille aussi pour deux entreprises du bâtiment. Il a vingt ans de métier et une équipe de quatre personnes.',
   'Ces références impressionnent, mais elles ne disent pas s''il acceptera un chantier de deux prises.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S12 / EXPECTED
  ('a44ba902-6b7a-522d-a948-7bb4dfd3f897', '20955a66-2d8d-57b3-bb93-d0d256bf8659', 'EXPECTED',
   'Pour deux prises, il est parfait : il accepte les petits chantiers, ce qui est rare. Il se déplace dans le quartier sans facturer le trajet. Il donne un devis par message en général le jour même, et il vient vite.',
   'Acceptation des petits travaux, déplacement, devis, délai : chaque trait décide pour un chantier de cette taille.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S12 / EXCELLENT
  ('467dcc22-23e1-534e-8ee1-f0e3a3bda171', '20955a66-2d8d-57b3-bb93-d0d256bf8659', 'EXCELLENT',
   'Pour deux prises, il est parfait : il accepte les petits chantiers, ce qui est rare, et ne facture pas le déplacement dans le quartier. Il envoie un devis par message dans la journée et il est venu chez moi trois jours après l''appel.',
   'Le délai vécu — « trois jours après l''appel » — vaut mieux que « il vient vite », et la sélection reste parfaitement ciblée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S13 / INSUFFICIENT
  ('e1dc42d2-425e-5d91-b9a8-09b7d1a22931', '74d3cf85-a662-5315-a384-671907be0194', 'INSUFFICIENT',
   'Au premier, il y a un professeur de musique très cultivé qui a beaucoup voyagé. Au troisième, un couple de retraités charmants qui font partie du club de bridge. Tout le monde est très aimable dans l''immeuble.',
   'Ces portraits sont sympathiques, mais aucun ne dit comment l''immeuble réagira à un bébé qui pleure la nuit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S13 / EXPECTED
  ('33c8f26f-7c11-5504-97f9-3de5c054d4f2', '74d3cf85-a662-5315-a384-671907be0194', 'EXPECTED',
   'Avec un bébé, ce qui compte : au-dessus de vous, il y a déjà deux enfants en bas âge, donc personne ne se plaindra. Les retraités du troisième sont un peu sourds. Les murs sont épais et l''immeuble est calme après vingt-deux heures.',
   'Chaque trait est choisi pour son effet sur la question du bruit nocturne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S13 / EXCELLENT
  ('277fd151-8a4a-5564-97a0-06df3516c46e', '74d3cf85-a662-5315-a384-671907be0194', 'EXCELLENT',
   'Avec un bébé, ce qui compte : juste au-dessus, une famille a déjà deux enfants de deux et quatre ans — vous vous réveillerez mutuellement, personne ne se plaindra. Le couple du troisième entend mal. Les murs sont épais, et je n''ai jamais entendu leur télévision.',
   '« Vous vous réveillerez mutuellement » et la preuve de l''isolation — n''avoir jamais entendu la télévision — remplacent utilement une affirmation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S14 / INSUFFICIENT
  ('bb096079-c232-507b-9337-3ebb1a918001', 'c57e4396-6832-5bb2-9ba5-30ce71ec6ea1', 'INSUFFICIENT',
   'Elle est en chêne massif avec un très joli veinage, un plateau huilé qui a pris une belle patine avec les années et des pieds fuselés dans le style scandinave. Elle vient d''un ébéniste de Bordeaux.',
   'Le style et la provenance ne disent pas si la table tient dans sept mètres carrés ni combien de personnes elle accueille.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S14 / EXPECTED
  ('e326c8dc-4cbc-52b3-b05a-06fb02f7f0a9', 'c57e4396-6832-5bb2-9ba5-30ce71ec6ea1', 'EXPECTED',
   'Pour sept mètres carrés : elle fait cent vingt centimètres sur soixante-dix, donc elle passe. Quatre personnes tiennent à l''aise. Elle a une rallonge qui la porte à cent soixante quand tu reçois. Les pieds sont aux angles, rien ne gêne les jambes.',
   'Dimensions, capacité, rallonge, position des pieds : chaque trait répond aux deux contraintes énoncées.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S14 / EXCELLENT
  ('44ddbdaf-adb0-5f20-8f1f-76029dae9d40', 'c57e4396-6832-5bb2-9ba5-30ce71ec6ea1', 'EXCELLENT',
   'Pour sept mètres carrés : cent vingt sur soixante-dix, elle passe sans problème. Quatre personnes à l''aise, six avec la rallonge qui l''allonge à cent soixante. Les pieds sont aux quatre angles, donc personne ne se cogne les genoux, et elle se plaque contre un mur sans gêner l''ouverture du four.',
   'La dernière précision anticipe un problème réel des petites cuisines, sans jamais sortir de la sélection demandée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S15 / INSUFFICIENT
  ('25d03af0-9ce6-5e41-813d-3a32e83946a7', '13713622-48c4-574b-8108-3b077cc46e81', 'INSUFFICIENT',
   'Il y a une grande armoire de trois portes avec beaucoup de rangement, une commode, un bureau si tu as besoin de travailler et une bibliothèque bien fournie. On peut vraiment s''y installer longtemps.',
   'Armoire, commode et bibliothèque servent à un long séjour. Il vient deux nuits, arrive tard et part tôt.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S15 / EXPECTED
  ('e118ee06-4ad0-51b5-a10c-98a3aafef5a4', '13713622-48c4-574b-8108-3b077cc46e81', 'EXPECTED',
   'Pour deux nuits, l''essentiel : le lit fait cent quarante et le matelas est neuf. La chambre donne sur la cour, tu ne seras pas réveillé. La salle de bains est juste en face. Je te laisserai une clé pour rentrer tard.',
   'Lit, calme, proximité de la salle de bains, autonomie : chaque trait sert exactement à deux nuits courtes.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10-S15 / EXCELLENT
  ('0381017c-7a8b-53b6-95a4-a3b7e7aedb4a', '13713622-48c4-574b-8108-3b077cc46e81', 'EXCELLENT',
   'Pour deux nuits, l''essentiel : lit en cent quarante, matelas neuf, et la fenêtre donne sur la cour — tu dormiras jusqu''à ton réveil. La salle de bains est juste en face, tu ne traverseras pas l''appartement à six heures. Tu auras une clé.',
   'Chaque trait est justifié par l''usage qu''il en fera : c''est la sélection elle-même qui devient lisible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S16 / INSUFFICIENT
  ('429caaaf-1f98-5ec1-8c27-3358f158875a', 'f38b4129-5485-5af2-863a-8e46695a2d7d', 'INSUFFICIENT',
   'Il s''agit de ma belle-sœur. Elle passera dans la matinée de vendredi, avant midi si tout va bien. Elle aura les deux clés et le badge du parking. Merci de lui remettre l''attestation en échange.',
   'Le moment et les objets remis sont donnés, mais aucun trait ne permet de la reconnaître à l''accueil.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S16 / EXPECTED
  ('549e3c4e-2d3b-57b6-855d-02c5971cc5b4', 'f38b4129-5485-5af2-863a-8e46695a2d7d', 'EXPECTED',
   'Il s''agit de ma belle-sœur, Lina. C''est une femme d''une quarantaine d''années, de taille moyenne, avec des cheveux châtains attachés. Elle porte des lunettes fines et vient souvent en tailleur gris.',
   'Âge, taille, cheveux, lunettes, vêtement : chaque trait se voit depuis un comptoir d''accueil.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S16 / EXCELLENT
  ('43ce1a1b-7b6d-5e2e-b15a-0fd44f84d1eb', 'f38b4129-5485-5af2-863a-8e46695a2d7d', 'EXCELLENT',
   'Il s''agit de ma belle-sœur, Lina. Une femme d''une quarantaine d''années, de taille moyenne, les cheveux châtains toujours attachés en queue basse. Elle porte de fines lunettes rondes et vient généralement en tailleur gris. Elle parle assez fort et sourit facilement.',
   'L''allure gagne en précision et le caractère ajoute un repère utile quand plusieurs personnes attendent.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S17 / INSUFFICIENT
  ('b720faa2-ef53-5807-b7fe-44536bec1032', '624e058f-4232-59db-af7e-d68af48beb9c', 'INSUFFICIENT',
   'Nous arrivons vendredi soir et nous repartons dimanche. Nous voudrions voir le château samedi matin et le musée l''après-midi, puis peut-être le marché avant de partir. Nous logeons près de la gare.',
   'Vous décrivez votre programme. L''office demandait qui compose le groupe, pour pouvoir vous conseiller.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S17 / EXPECTED
  ('51596385-5bcf-542b-ba07-56e585a3dd63', '624e058f-4232-59db-af7e-d68af48beb9c', 'EXPECTED',
   'Nous serons six : mes parents, qui ont plus de soixante-dix ans, ma sœur et moi, et nos deux enfants de six et neuf ans. Trois générations, donc, avec des rythmes très différents. Tout le monde parle français.',
   'Effectif, âges, générations, langue : la composition est claire et l''office peut adapter son conseil.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S17 / EXCELLENT
  ('bd796d1a-e74b-57e9-8fbc-a58ac70736e9', '624e058f-4232-59db-af7e-d68af48beb9c', 'EXCELLENT',
   'Nous serons six : mes parents, plus de soixante-dix ans et marcheurs prudents, ma sœur et moi, et nos deux enfants de six et neuf ans, infatigables. Trois générations, donc, et deux rythmes qui ne vont pas ensemble. Tout le monde parle français.',
   'Les rythmes opposés sont nommés : c''est le trait du groupe qui pèse le plus sur le conseil demandé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S18 / INSUFFICIENT
  ('337ecacf-4669-59bc-a658-0f4d204a4ee4', '2c0c9646-914d-5319-812b-645b56692523', 'INSUFFICIENT',
   'Oui, il a emménagé samedi dernier. Le camion est resté toute la journée devant le porche et ils ont monté des meubles jusqu''à dix-neuf heures. Il y avait beaucoup de cartons, il doit venir de loin.',
   'Vous racontez le déménagement. Votre voisine demandait à quoi ressemble la personne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S18 / EXPECTED
  ('d09cfa3a-1fc1-59f7-a6dc-51f299adf34d', '2c0c9646-914d-5319-812b-645b56692523', 'EXPECTED',
   'Oui, je l''ai croisé deux fois. C''est un homme d''une cinquantaine d''années, assez grand, les cheveux gris et courts. Il porte souvent une veste en jean. Il dit bonjour le premier et il s''arrête volontiers pour parler.',
   'Âge, taille, cheveux, vêtement, manière d''être : la voisine peut le reconnaître et sait à quoi s''attendre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S18 / EXCELLENT
  ('a8e46518-ad3b-5bda-be17-beed95fbfb83', '2c0c9646-914d-5319-812b-645b56692523', 'EXCELLENT',
   'Oui, je l''ai croisé deux fois. Un homme d''une cinquantaine d''années, assez grand, les cheveux gris coupés court et une barbe de trois jours. Il porte presque toujours une veste en jean. Il dit bonjour le premier et s''arrête volontiers, même quand on est pressé.',
   'Le dernier détail — s''arrêter même quand on est pressé — dit le caractère par un fait plutôt que par un adjectif.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S19 / INSUFFICIENT
  ('0d1a0b80-5645-590e-9481-2fd61e46606e', 'a18eecd8-06f2-54a6-89ae-a7e05c86dead', 'INSUFFICIENT',
   'Nous prévoyons trois stands, une buvette et un podium pour le concert du soir. Le montage aura lieu le vendredi après-midi et le rangement le dimanche matin. Il nous faudrait deux tables supplémentaires.',
   'Vous décrivez la fête. La mairie demandait à quoi ressemble l''équipe que vous avez réunie.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S19 / EXPECTED
  ('a86ca2fb-2c10-5c69-9b23-efbb87a6a40d', 'a18eecd8-06f2-54a6-89ae-a7e05c86dead', 'EXPECTED',
   'L''équipe compte douze personnes cette année. Sept étaient déjà là l''an dernier, cinq sont nouvelles. Il y a quatre retraités, trois lycéens et cinq parents d''élèves. L''ambiance est très bonne et chacun sait déjà ce qu''il fait.',
   'Effectif, ancienneté, profils, ambiance : le groupe est décrit sans glisser vers l''événement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S19 / EXCELLENT
  ('38a94d18-6759-5792-af58-6e53a1390a7d', 'a18eecd8-06f2-54a6-89ae-a7e05c86dead', 'EXCELLENT',
   'L''équipe compte douze personnes, dont sept déjà présentes l''an dernier. Quatre retraités très réguliers, trois lycéens qui viennent surtout le samedi, et cinq parents d''élèves. Les anciens forment les nouveaux sans qu''on ait rien à organiser.',
   'Les disponibilités par sous-groupe et l''entraide spontanée décrivent le fonctionnement réel du groupe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S20 / INSUFFICIENT
  ('1ec12cc6-d4d2-50f1-ad44-52c174c9b94d', 'a4bdbcac-66ed-5efd-803f-40d3f4d98419', 'INSUFFICIENT',
   'Elle arrive à neuf heures et repart vers dix-sept heures. Elle a les clés et le numéro du médecin. Les enfants déjeunent à midi et Léa fait la sieste après. Tout est écrit sur la porte du frigo.',
   'Vous décrivez l''organisation de la journée. Elle demandait à quoi ressemble la personne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S20 / EXPECTED
  ('2742d775-34b2-55c7-aef0-bc2e3206f2da', 'a4bdbcac-66ed-5efd-803f-40d3f4d98419', 'EXPECTED',
   'C''est Élodie, une jeune femme de vingt-cinq ans, petite et brune, avec des cheveux bouclés. Elle porte souvent un sweat orange. Elle est très calme avec les enfants et elle ne hausse jamais la voix.',
   'Âge, taille, cheveux, vêtement, manière d''être : la personne est reconnaissable et rassurante.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S20 / EXCELLENT
  ('c33b991a-0e07-5c73-93bd-22b3a9740e67', 'a4bdbcac-66ed-5efd-803f-40d3f4d98419', 'EXCELLENT',
   'C''est Élodie, vingt-cinq ans, petite et brune, les cheveux bouclés attachés en chignon. Elle porte presque toujours un sweat orange. Avec les enfants, elle est d''un calme rare : elle s''accroupit pour leur parler et ne hausse jamais la voix.',
   'Le geste de s''accroupir montre le calme au lieu de l''affirmer, ce qui rassure bien davantage.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S21 / INSUFFICIENT
  ('32b5342a-18ee-5733-bd11-bb49deccc023', 'feec348c-2384-53ba-bfb0-bd9b3d3dcad7', 'INSUFFICIENT',
   'On commence par vingt minutes d''échauffement, puis des exercices au sol et on finit par des étirements. Le prof adapte toujours les mouvements. Ça dure une heure et c''est le mardi soir à dix-neuf heures.',
   'Vous décrivez la séance. Votre amie demandait qui sont les autres participants.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S21 / EXPECTED
  ('76d92d5b-2217-5a76-8500-e4b8de5fc5de', 'feec348c-2384-53ba-bfb0-bd9b3d3dcad7', 'EXPECTED',
   'Nous sommes une quinzaine, et la plupart ont entre quarante et soixante ans. Trois personnes ont commencé cette année sans jamais avoir fait de sport. Personne ne regarde les autres, l''ambiance est très détendue.',
   'Effectif, tranche d''âge, débutants, ambiance : exactement ce qui peut lever sa crainte.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S21 / EXCELLENT
  ('db83fc5d-8db9-51c5-86c3-cad5d101f3ca', 'feec348c-2384-53ba-bfb0-bd9b3d3dcad7', 'EXCELLENT',
   'Nous sommes une quinzaine, la plupart entre quarante et soixante ans. Trois personnes ont commencé cette année après des années sans sport, et l''une d''elles suivait encore assise il y a six mois. Personne ne regarde personne, on rit beaucoup plus qu''on ne transpire.',
   'L''exemple de la personne assise il y a six mois vaut mieux que toutes les assurances possibles.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S22 / INSUFFICIENT
  ('afacdd26-61a9-5eef-98c3-0dea2a9d1c11', '8f04c9c7-6175-5e08-9c3c-070441b557a3', 'INSUFFICIENT',
   'Le cabinet est le même, au premier étage, et le secrétariat n''a pas changé. Les rendez-vous durent vingt minutes comme d''habitude. Prends ta carte Vitale et ton ordonnance, il aura accès à ton dossier.',
   'Vous décrivez le cabinet. Votre père voulait savoir qui il allait trouver en face de lui.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S22 / EXPECTED
  ('ed74de34-5940-5f70-98e7-de5d4c130290', '8f04c9c7-6175-5e08-9c3c-070441b557a3', 'EXPECTED',
   'C''est le docteur Belkacem, une femme d''une trentaine d''années, brune, plutôt petite. Elle parle doucement et prend le temps d''expliquer. Elle t''a déjà reçu l''hiver dernier quand tu avais ta bronchite.',
   'Âge, aspect, manière de parler, et un souvenir concret : la personne devient familière.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S22 / EXCELLENT
  ('d5fb42c4-a615-5258-b3f1-8b98bb71c000', '8f04c9c7-6175-5e08-9c3c-070441b557a3', 'EXCELLENT',
   'C''est le docteur Belkacem, une femme d''une trentaine d''années, brune et plutôt petite. Elle parle doucement, reformule tout ce qu''elle explique et écrit les noms de médicaments en majuscules. Elle t''avait reçu l''hiver dernier pour ta bronchite.',
   'Reformuler et écrire en majuscules sont deux gestes observés, exactement ce qui rassure une personne âgée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S23 / INSUFFICIENT
  ('7e8553bb-7d11-5673-b711-4c39c12f0b1c', '91a8092a-2105-5f68-a872-e5184ce0dd43', 'INSUFFICIENT',
   'Ils refont toute la vitrine et le carrelage, ça devrait durer trois semaines. Ils garderont les baguettes tradition et ajouteront des pains spéciaux. Le four du fond sera changé. Réouverture prévue début octobre.',
   'Vous décrivez les travaux et l''offre. Il demandait qui sont les personnes qui reprennent.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S23 / EXPECTED
  ('e6dbd497-a575-5989-969d-883a754321a2', '91a8092a-2105-5f68-a872-e5184ce0dd43', 'EXPECTED',
   'Ils sont trois : un couple d''une quarantaine d''années et le frère de la femme, plus jeune. Ils tenaient déjà une boulangerie près de Tours. Ils sont venus se présenter aux commerçants la semaine dernière.',
   'Effectif, âges, lien familial, expérience, démarche : le groupe est décrit et situé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S23 / EXCELLENT
  ('1c12a5fb-b0cd-5121-91dd-1652575db571', '91a8092a-2105-5f68-a872-e5184ce0dd43', 'EXCELLENT',
   'Ils sont trois : un couple d''une quarantaine d''années et le frère de la femme, plus jeune, qui sera au fournil. Ils tenaient déjà une boulangerie près de Tours pendant douze ans. Ils sont passés se présenter à chaque commerçant de la rue, un par un.',
   'Le rôle de chacun et la démarche de présentation, faite « un par un », disent le sérieux du groupe sans le proclamer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S24 / INSUFFICIENT
  ('b609e848-8072-58e2-a29b-524d4113cbc8', 'cc79e190-920e-55ab-9d1d-9dba970f4637', 'INSUFFICIENT',
   'Ah oui, elle appelait sûrement pour l''anniversaire de l''association, on m''avait dit qu''elle contacterait les familles cette semaine. Dis à maman qu''il n''y a aucune inquiétude à avoir, c''est tout à fait normal.',
   'Vous expliquez le motif de l''appel. Votre mère s''inquiète de la personne : elle n''a toujours aucun visage à mettre dessus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S24 / EXPECTED
  ('0d0cf73c-da4f-59a1-96d4-06644560da3e', 'cc79e190-920e-55ab-9d1d-9dba970f4637', 'EXPECTED',
   'C''est Martine, une amie du club de lecture. Une femme d''une soixantaine d''années, petite, avec des cheveux blancs très courts. Elle parle très vite et rit beaucoup. Maman l''a déjà vue à la fête de juin.',
   'Âge, allure, manière de parler, et un souvenir commun : le portrait remplace l''inquiétude.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S24 / EXCELLENT
  ('c8558844-d66e-5817-a68a-44b739e69748', 'cc79e190-920e-55ab-9d1d-9dba970f4637', 'EXCELLENT',
   'C''est Martine, du club de lecture. Une femme d''une soixantaine d''années, petite, cheveux blancs très courts et toujours une écharpe colorée. Elle parle très vite et rit au milieu de ses phrases. Maman l''a vue à la fête de juin, elle s''en souviendra.',
   '« Rit au milieu de ses phrases » est un trait qui se reconnaît au téléphone : la description est adaptée au canal.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S25 / INSUFFICIENT
  ('8d1e1344-aec8-58b2-b9e5-3d49267b4499', 'c69e0c60-c915-5676-ab8c-bc9bb1fafb39', 'INSUFFICIENT',
   'Nous arrivons lundi vers onze heures en car. Nous visitons la grotte mardi et le musée mercredi matin. Le départ est prévu jeudi après le déjeuner. Merci de prévoir des paniers-repas pour les deux sorties.',
   'Vous décrivez le séjour. Ils demandaient la composition du groupe, pour répartir les chambres.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S25 / EXPECTED
  ('4166187b-2130-54a2-b58f-e23a777491bf', 'c69e0c60-c915-5676-ab8c-bc9bb1fafb39', 'EXPECTED',
   'Le groupe compte vingt-huit élèves de quatrième, seize filles et douze garçons, âgés de treize à quinze ans. Trois adultes les accompagnent : deux enseignantes et un parent. Deux élèves ont un traitement médical à prendre le soir.',
   'Effectif, répartition, âges, encadrants, besoins particuliers : tout ce qui sert à répartir des chambres.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S25 / EXCELLENT
  ('e597dade-3d31-55d7-8b81-67d6699368de', 'c69e0c60-c915-5676-ab8c-bc9bb1fafb39', 'EXCELLENT',
   'Le groupe compte vingt-huit élèves de quatrième, seize filles et douze garçons, de treize à quinze ans. Trois adultes accompagnent : deux enseignantes et un parent, qui souhaitent des chambres réparties dans les deux étages. Deux élèves suivent un traitement à prendre le soir.',
   'La demande de répartition des adultes anticipe exactement la question que le centre allait poser ensuite.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S26 / INSUFFICIENT
  ('2677cf6c-23e9-5280-b7d2-1e4e30e61e79', '37145258-97a8-5b40-9165-a9101825f35f', 'INSUFFICIENT',
   'C''est le stand avec la bâche bleue au bout de l''allée, il y a toujours des cagettes en bois empilées devant. Il vend surtout des légumes de saison et des œufs. Les tomates sont excellentes en ce moment.',
   'Vous décrivez l''étal et les produits. Votre amie demandait à quoi ressemble le maraîcher lui-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S26 / EXPECTED
  ('282cb4c2-ff95-5fcc-9991-b0d4e15da074', '37145258-97a8-5b40-9165-a9101825f35f', 'EXPECTED',
   'C''est un homme d''une soixantaine d''années, grand et sec, avec une casquette grise qu''il ne quitte jamais. Il a les mains très abîmées. Il parle peu mais il répond toujours quand on lui demande conseil.',
   'Âge, silhouette, casquette, mains, manière de parler : le portrait suffit à le reconnaître.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S26 / EXCELLENT
  ('1d8be951-0566-5e7f-bdb5-12537e5f1345', '37145258-97a8-5b40-9165-a9101825f35f', 'EXCELLENT',
   'C''est un homme d''une soixantaine d''années, grand et sec, avec une vieille casquette grise qu''il ne quitte jamais, même en plein soleil. Ses mains sont très abîmées. Il parle peu, mais si tu lui demandes ce qui est bon aujourd''hui, il te répondra franchement.',
   'La manière d''aborder la personne est indiquée, ce qui rend le portrait immédiatement utile.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S27 / INSUFFICIENT
  ('736b4f83-c6d2-5ce4-bbe3-cb9f8cb54959', '172b23b8-d23e-5778-a935-1a92b6935e8b', 'INSUFFICIENT',
   'L''immeuble date des années soixante, la façade a été ravalée il y a deux ans et l''ascenseur est aux normes. Les parties communes sont nettoyées le lundi. Le chauffage est collectif et les charges restent raisonnables.',
   'Vous décrivez le bâtiment. Elle demandait à quoi ressemblent les habitants.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S27 / EXPECTED
  ('e33ea764-96ab-5aa1-8543-7fed4e56159c', '172b23b8-d23e-5778-a935-1a92b6935e8b', 'EXPECTED',
   'Nous sommes huit foyers : trois couples de retraités installés depuis longtemps, deux familles avec enfants et trois personnes seules. Tout le monde se dit bonjour. Il y a une fête des voisins chaque année en juin.',
   'Effectif, profils, relations, habitude commune : l''ambiance de l''immeuble est décrite par des faits.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S27 / EXCELLENT
  ('4cba528b-ed18-513a-9f0f-0835a71c7c4e', '172b23b8-d23e-5778-a935-1a92b6935e8b', 'EXCELLENT',
   'Nous sommes huit foyers : trois couples de retraités installés depuis vingt ans, deux familles avec enfants et trois personnes seules. On se dit bonjour et on se garde les colis. La fête des voisins de juin réunit presque tout le monde, y compris le deuxième étage.',
   'Se garder les colis et la participation quasi complète à la fête montrent l''entente au lieu de l''affirmer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S28 / INSUFFICIENT
  ('f495a211-4570-5847-906d-d0ff19e470d5', '06b68b61-d518-5c3e-8b5d-bd8a9ec9f4bb', 'INSUFFICIENT',
   'Il est en deuxième année de BTS commerce international, avec une option logistique. Il a obtenu son bac avec mention l''an dernier et il a validé tous ses modules. Il cherche un stage de huit semaines à partir de mars.',
   'Le parcours scolaire est complet, mais elle demandait à qui elle aurait affaire au quotidien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S28 / EXPECTED
  ('9c32f46b-7f74-51b7-ac17-486d017af95e', '06b68b61-d518-5c3e-8b5d-bd8a9ec9f4bb', 'EXPECTED',
   'C''est Yanis, dix-neuf ans, grand et plutôt réservé. Il écoute beaucoup avant de parler. Il arrive toujours en avance et il pose des questions quand il n''a pas compris, ce qui est rare à cet âge.',
   'Âge, allure, caractère, et deux comportements observés : elle sait à qui elle aura affaire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S28 / EXCELLENT
  ('111add5e-1fcd-59f3-8574-085a77da038e', '06b68b61-d518-5c3e-8b5d-bd8a9ec9f4bb', 'EXCELLENT',
   'C''est Yanis, dix-neuf ans, grand et plutôt réservé : il écoute longtemps avant de parler. Il est arrivé en avance aux trois rendez-vous que je lui ai fixés. Et quand il ne comprend pas, il le dit, au lieu de faire semblant.',
   '« Aux trois rendez-vous que je lui ai fixés » remplace une qualité annoncée par une preuve, et le dernier trait est décisif pour un stage.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S29 / INSUFFICIENT
  ('09a2fea4-4156-59d4-acd2-2afe47687ca9', '4c47a9fc-739c-559e-90e5-cb500d99bcc3', 'INSUFFICIENT',
   'La salle fait deux cents places assises, avec un balcon au fond. La sono a été refaite l''an dernier et l''acoustique est très bonne. Ils programment surtout du jazz et de la chanson, deux concerts par semaine.',
   'Vous décrivez la salle et la programmation. Il demandait qui vient écouter.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S29 / EXPECTED
  ('82733d7f-3f0b-56df-a469-f7d5056a6659', '4c47a9fc-739c-559e-90e5-cb500d99bcc3', 'EXPECTED',
   'Le public est plutôt âgé, entre cinquante et soixante-dix ans pour la plupart, avec quelques étudiants. Ils écoutent en silence et applaudissent longtemps. Beaucoup viennent seuls et se connaissent entre eux.',
   'Âges, comportement d''écoute, habitudes : le public est décrit tel qu''un musicien a besoin de le connaître.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S29 / EXCELLENT
  ('12458044-74f1-539c-b2c3-4bbbcc785d67', '4c47a9fc-739c-559e-90e5-cb500d99bcc3', 'EXCELLENT',
   'Le public est plutôt âgé, la plupart entre cinquante et soixante-dix ans, avec quelques étudiants au balcon. Ils écoutent dans un silence complet, ne parlent jamais pendant les morceaux, et applaudissent très longtemps. Beaucoup viennent seuls et se saluent avant d''entrer.',
   '« Ne parlent jamais pendant les morceaux » est précisément ce qu''un musicien veut savoir avant de choisir son programme.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S30 / INSUFFICIENT
  ('3ef8437b-573c-59a9-9016-c9af51d2e2d9', '565b5ccc-f262-59a7-a416-0ca05e497a45', 'INSUFFICIENT',
   'Elle reprendra le suivi des commandes, la relance des impayés et le point hebdomadaire du mardi. Je lui laisserai les accès au logiciel et un document récapitulatif. Les dossiers urgents sont déjà identifiés.',
   'Vous listez la passation. Le responsable demandait qui est cette personne, qu''il ne connaît pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S30 / EXPECTED
  ('9e36e4a6-f740-5464-add6-4d1414d473d9', '565b5ccc-f262-59a7-a416-0ca05e497a45', 'EXPECTED',
   'Je propose Fatou, du service voisin. Elle a trente-cinq ans et dix ans de maison. Elle est très méthodique et travaille vite. Elle a déjà remplacé une collègue l''été dernier et personne n''a rien eu à reprendre.',
   'Âge, ancienneté, manière de travailler, antécédent : le portrait professionnel est complet.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C7-S30 / EXCELLENT
  ('64b6feaa-efe7-55de-8c5b-b787017bcaf0', '565b5ccc-f262-59a7-a416-0ca05e497a45', 'EXCELLENT',
   'Je propose Fatou, du service voisin : trente-cinq ans, dix ans de maison. Elle est méthodique au point de tout noter, et elle pose ses questions dès le premier jour plutôt qu''au bout d''une semaine. Elle a déjà remplacé une collègue l''été dernier, sans une seule erreur.',
   'Chaque qualité est traduite en comportement observable, ce qui est exactement ce qu''un responsable peut évaluer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S1 / INSUFFICIENT
  ('791debc1-897a-5110-ac63-de4a78075576', 'db781b4a-efaa-5b6a-ad77-a146211424e5', 'INSUFFICIENT',
   'Oui il est encore libre ! C''est un très bon studio, vraiment agréable à vivre et bien placé. Je pense qu''il vous plaira beaucoup. Le quartier est calme et les voisins sont sympathiques.',
   '« Agréable » et « bien placé » sont des jugements, pas des caractéristiques. On ne peut pas se représenter la pièce.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S1 / EXPECTED
  ('110fc434-8f2a-580d-8898-ce1cf5ce7cd7', 'db781b4a-efaa-5b6a-ad77-a146211424e5', 'EXPECTED',
   'C''est une pièce de vingt-six mètres carrés, avec un coin cuisine le long du mur et une salle d''eau séparée. La fenêtre donne sur la cour. Les murs sont blancs, le sol en parquet clair. Tout est en bon état.',
   'Surface, agencement, exposition, matériaux, état : chaque élément se vérifie à la visite.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S1 / EXCELLENT
  ('1a742cf3-0e3d-5c36-8576-8744e1a1734b', 'db781b4a-efaa-5b6a-ad77-a146211424e5', 'EXCELLENT',
   'Une pièce de vingt-six mètres carrés, avec un coin cuisine le long du mur de gauche et une salle d''eau séparée derrière une cloison. L''unique fenêtre donne sur la cour, donc c''est calme mais un peu sombre le matin. Parquet clair, murs repeints l''an dernier.',
   'Les positions sont données et la réserve sur la lumière rend la description crédible plutôt que vendeuse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S2 / INSUFFICIENT
  ('c079e666-a6f6-5ebd-930c-f7cddc6f0c9d', '9db0edd9-34b3-52ce-aa45-f54daafd77a0', 'INSUFFICIENT',
   'C''est un sac avec mes affaires de sport à l''intérieur, mes chaussures et une serviette. Il y a aussi mon badge de la salle et une gourde bleue. J''en ai vraiment besoin pour demain matin.',
   'Vous décrivez le contenu. Ils doivent reconnaître le sac sans l''ouvrir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S2 / EXPECTED
  ('219dc370-2c39-5236-89d4-ff2eba3373e7', '9db0edd9-34b3-52ce-aa45-f54daafd77a0', 'EXPECTED',
   'C''est un sac de sport en toile noire, de forme allongée, environ cinquante centimètres de long. Il a une bandoulière réglable et une poche latérale à fermeture éclair. Le logo blanc est à moitié effacé.',
   'Type, matière, forme, taille, détails extérieurs : le sac est identifiable de l''extérieur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S2 / EXCELLENT
  ('c2fbd4ea-fdbe-52b9-93f2-d0f785983937', '9db0edd9-34b3-52ce-aa45-f54daafd77a0', 'EXCELLENT',
   'Un sac de sport en toile noire, allongé, environ cinquante centimètres, avec une bandoulière réglable et une poche latérale à fermeture éclair. Le logo blanc sur le flanc est à moitié effacé, et la fermeture principale a une attache de rechange en ficelle rouge.',
   'L''attache en ficelle rouge est le genre de détail qui rend l''identification certaine parmi plusieurs sacs noirs.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S3 / INSUFFICIENT
  ('8751986f-53d3-58e6-9845-5041ed24cce1', '4a055e34-909c-5ff2-acd5-8e2059b2985f', 'INSUFFICIENT',
   'C''est vraiment bien ici, je suis très contente d''avoir déménagé. Le quartier est beaucoup mieux que l''ancien, tu verras quand tu viendras. Je crois que tu vas adorer, ça te ressemble.',
   'Rien n''est décrit : quatre phrases d''enthousiasme ne donnent aucune image du quartier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S3 / EXPECTED
  ('9935da55-92fc-57e6-9d84-57d5efd9b751', '4a055e34-909c-5ff2-acd5-8e2059b2985f', 'EXPECTED',
   'De ma fenêtre, je vois une place plantée de platanes avec un kiosque au milieu. Les immeubles autour sont bas, en pierre claire. Il y a une boulangerie à l''angle et un café avec des tables dehors. C''est très calme le soir.',
   'Ce qu''on voit, les matériaux, les commerces, l''ambiance sonore : le quartier devient visible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S3 / EXCELLENT
  ('f2005a7e-dae7-59a2-bdc3-9364b035797c', '4a055e34-909c-5ff2-acd5-8e2059b2985f', 'EXCELLENT',
   'De ma fenêtre, je vois une place plantée de grands platanes, avec un kiosque à musique au milieu. Les immeubles autour sont bas, en pierre claire, avec des volets bleus. Une boulangerie occupe l''angle et le café voisin sort ses tables dès qu''il fait beau. Le soir, on n''entend plus rien.',
   'Les volets bleus et les tables sorties « dès qu''il fait beau » font passer d''un inventaire à une image.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S4 / INSUFFICIENT
  ('4611b9a1-8108-5c47-a841-47df4e9ba0c3', '3efbf76b-2901-5ebc-a553-be57bc6c353a', 'INSUFFICIENT',
   'Madame, Monsieur, le vélo a été volé devant la gare mercredi entre dix-sept et dix-neuf heures. L''antivol a été sectionné. J''ai déposé plainte au commissariat central le lendemain matin. Bien cordialement.',
   'Vous racontez les circonstances. L''assurance demandait la description du vélo lui-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S4 / EXPECTED
  ('dd03c2cc-32f2-5316-89bc-4d975d36cd8c', '3efbf76b-2901-5ebc-a553-be57bc6c353a', 'EXPECTED',
   'Madame, Monsieur, il s''agit d''un vélo de ville vert foncé, à cadre bas, équipé d''un porte-bagages arrière et de garde-boue. Il a sept vitesses et une sonnette argentée. La selle est en cuir brun, assez usée.',
   'Type, couleur, cadre, équipements, état de la selle : le vélo est identifiable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S4 / EXCELLENT
  ('6aec2add-7380-5d66-ae61-0c806ada8606', '3efbf76b-2901-5ebc-a553-be57bc6c353a', 'EXCELLENT',
   'Madame, Monsieur, il s''agit d''un vélo de ville vert foncé à cadre bas, avec porte-bagages arrière, garde-boue et sept vitesses. La selle en cuir brun est très usée sur le côté droit, et le garde-boue avant porte un autocollant blanc à moitié décollé.',
   'L''usure localisée et l''autocollant décollé sont deux marques uniques, bien plus utiles qu''un adjectif de plus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S5 / INSUFFICIENT
  ('9d83a53b-334c-56e1-846d-a2693d5a57c2', '1f0beb22-0f79-53fc-87c0-ddbe6397d2ea', 'INSUFFICIENT',
   'Bonjour, c''est une chambre très charmante, vraiment cosy, où nos hôtes se sentent toujours bien. Beaucoup nous écrivent après leur séjour pour nous dire qu''ils ont passé un excellent moment. Vous ne serez pas déçus.',
   'Les avis des autres ne remplacent pas la description : on ne sait rien de la pièce.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S5 / EXPECTED
  ('e78eeb9f-0a0b-5006-8f5b-48ab1bc3f88d', '1f0beb22-0f79-53fc-87c0-ddbe6397d2ea', 'EXPECTED',
   'La chambre fait dix-huit mètres carrés, avec un lit en cent soixante, une armoire ancienne et un bureau sous la fenêtre. Elle donne à l''est, donc le soleil entre le matin. La salle de bains est privative, avec une douche.',
   'Surface, lit, mobilier, exposition, sanitaires : le couple peut décider.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S5 / EXCELLENT
  ('d4f53b19-662c-5801-b25c-4f59c46b1a41', '1f0beb22-0f79-53fc-87c0-ddbe6397d2ea', 'EXCELLENT',
   'La chambre fait dix-huit mètres carrés : un lit en cent soixante, une armoire ancienne en noyer et un bureau sous la fenêtre. Elle donne à l''est, le soleil entre dès sept heures — les rideaux sont épais. Salle de bains privative avec douche à l''italienne.',
   'La précision sur l''heure du soleil et les rideaux anticipe la seule vraie objection d''une chambre à l''est.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S6 / INSUFFICIENT
  ('8ee79447-b5a9-5cc7-a1a4-d6e34d4dfbb8', '5c6ca7d3-f01e-5776-94e2-133d4f897cbd', 'INSUFFICIENT',
   'Oui je le donne, il marche encore très bien et il a fait son temps chez moi mais il peut servir des années. Venez le chercher quand vous voulez, je suis là presque tous les soirs après dix-huit heures.',
   'Aucune caractéristique : ni taille, ni aspect, ni état précis. Elle ne sait pas s''il entrera dans sa cuisine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S6 / EXPECTED
  ('148d29d5-94af-5916-8996-f73721096c9a', '5c6ca7d3-f01e-5776-94e2-133d4f897cbd', 'EXPECTED',
   'C''est un four encastrable en inox, de soixante centimètres de large sur soixante de haut. Il a une porte vitrée et cinq programmes. Il fonctionne bien, mais le voyant de température ne s''allume plus.',
   'Dimensions, matière, fonctions, et un défaut annoncé : elle peut décider en connaissance de cause.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S6 / EXCELLENT
  ('484dab76-d44c-54b3-88da-f6caf0263fb2', '5c6ca7d3-f01e-5776-94e2-133d4f897cbd', 'EXCELLENT',
   'C''est un four encastrable en inox, soixante centimètres de large, de haut et de profondeur — mesurez votre niche. Porte vitrée, cinq programmes, chaleur tournante. Il chauffe parfaitement, mais le voyant de température ne s''allume plus et la poignée est un peu desserrée.',
   'La troisième dimension et les deux défauts précis évitent un déplacement pour rien, ce que la description doit servir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S7 / INSUFFICIENT
  ('3565e859-1200-541f-b030-72346705782f', 'be52610b-0abb-537a-a936-b3139e8b0b93', 'INSUFFICIENT',
   'Bonjour, c''est une très bonne salle, tout le village s''en sert pour les mariages et les repas. Elle est bien située à côté de la mairie et le parking est juste devant. Vous ne regretterez pas votre choix.',
   'L''usage et la situation sont donnés, mais la salle elle-même n''est pas décrite : ni taille, ni capacité, ni équipement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S7 / EXPECTED
  ('2628922d-c7fd-5fcf-88f0-769af53907d4', 'be52610b-0abb-537a-a936-b3139e8b0b93', 'EXPECTED',
   'La salle accueille cent vingt personnes assises. Elle fait environ deux cents mètres carrés, avec un parquet et de grandes fenêtres sur deux côtés. Il y a une cuisine attenante, une sono et un vidéoprojecteur. Les toilettes ont été refaites.',
   'Capacité, surface, matériaux, équipements, état : l''association peut décider.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S7 / EXCELLENT
  ('13249a9f-c8ff-5d9a-827d-96426ec50eab', 'be52610b-0abb-537a-a936-b3139e8b0b93', 'EXCELLENT',
   'La salle accueille cent vingt personnes assises sur environ deux cents mètres carrés, avec un parquet et de grandes fenêtres sur deux côtés. Cuisine attenante équipée, sono et vidéoprojecteur fixé au plafond. Les toilettes sont neuves, mais le chauffage met une heure à monter.',
   'La réserve sur le chauffage est exactement ce qu''une association a besoin de savoir avant de réserver en hiver.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S8 / INSUFFICIENT
  ('69a8149a-133f-5b18-b2ab-b82ff0b42ea6', '558232b4-40c0-5848-be8d-1ad2923f50d0', 'INSUFFICIENT',
   'Bonjour, c''est la montre de mon grand-père, qui la portait tous les jours quand il travaillait à l''usine. Elle a beaucoup de valeur pour moi. Elle s''est arrêtée il y a un mois et je voudrais vraiment la faire repartir.',
   'L''histoire de la montre est touchante, mais l''horloger a besoin de sa matière, de sa taille et de son mécanisme pour estimer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S8 / EXPECTED
  ('34af71dc-c354-5174-8a17-5940623770a6', '558232b4-40c0-5848-be8d-1ad2923f50d0', 'EXPECTED',
   'C''est une montre mécanique à remontage manuel, avec un boîtier rond en acier d''environ trente-cinq millimètres. Le cadran est crème avec des chiffres noirs et une petite trotteuse à six heures. Le bracelet en cuir est craquelé.',
   'Mécanisme, boîtier, taille, cadran, bracelet : l''horloger peut estimer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S8 / EXCELLENT
  ('8ebff1a1-13a2-5915-8c63-4364ed0e1696', '558232b4-40c0-5848-be8d-1ad2923f50d0', 'EXCELLENT',
   'Une montre mécanique à remontage manuel, boîtier rond en acier d''environ trente-cinq millimètres, cadran crème à chiffres noirs et petite trotteuse à six heures. Le verre porte une rayure en diagonale, le bracelet en cuir est craquelé, et le remontoir tourne dans le vide.',
   '« Le remontoir tourne dans le vide » est le symptôme précis dont l''horloger a besoin, ajouté sans sortir de la description.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S9 / INSUFFICIENT
  ('c9d0050c-d11b-5e12-9fc5-d75921fc59d5', '68be9f12-3bf6-551d-88c3-b7e20e85ad97', 'INSUFFICIENT',
   'Il serait parfait pour un salon, franchement. Tu pourrais mettre les bacs au fond et les fauteuils devant la vitrine, et même prévoir un petit coin d''attente. Il y a largement la place, tu verrais tout de suite le potentiel.',
   'Vous imaginez l''aménagement futur. Elle demandait à quoi ressemble le local aujourd''hui.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S9 / EXPECTED
  ('f8d4487e-8e9c-5a96-b24b-74fd587d8a08', '68be9f12-3bf6-551d-88c3-b7e20e85ad97', 'EXPECTED',
   'Le local fait environ quarante mètres carrés, en longueur. La vitrine occupe toute la façade, sur trois mètres. Il y a un point d''eau au fond et des toilettes. Les murs sont bruts et le sol en béton ciré.',
   'Surface, forme, vitrine, équipements, revêtements : le local est décrit dans son état réel.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S9 / EXCELLENT
  ('e650f38e-2454-50c3-ae60-c8562b94982d', '68be9f12-3bf6-551d-88c3-b7e20e85ad97', 'EXCELLENT',
   'Le local fait environ quarante mètres carrés, tout en longueur, avec une vitrine de trois mètres sur toute la façade côté rue. Un point d''eau et des toilettes au fond. Les murs sont bruts, le sol en béton ciré, et le plafond monte à trois mètres cinquante.',
   'La hauteur sous plafond et l''orientation de la vitrine sont précisément ce qui décide de l''usage d''un local commercial.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S10 / INSUFFICIENT
  ('1c7de197-fe78-5944-8644-de3c797d7f17', '1ae90a42-fde6-5743-9d04-27f383bec90d', 'INSUFFICIENT',
   'Bonjour, c''est une commode ancienne à laquelle je tiens énormément et que je voudrais vraiment sauver. Elle est dans un triste état mais je suis sûr qu''elle peut être magnifique. Pouvez-vous passer voir cette semaine ?',
   'Ni dimensions, ni bois, ni nature des dégâts : le menuisier ne peut rien préparer avant de venir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S10 / EXPECTED
  ('d3090c33-b31e-5ab2-a28a-dd81be83efc9', '1ae90a42-fde6-5743-9d04-27f383bec90d', 'EXPECTED',
   'C''est une commode en chêne de quatre-vingt-dix centimètres de haut sur un mètre de large, avec trois tiroirs. Le plateau est fendu sur toute sa longueur et un pied avant est cassé. Les poignées en laiton manquent sur deux tiroirs.',
   'Essence, dimensions, structure, dégâts localisés : le menuisier peut estimer le travail.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S10 / EXCELLENT
  ('f8216a58-2eb2-53f3-9282-93f7b77da7b0', '1ae90a42-fde6-5743-9d04-27f383bec90d', 'EXCELLENT',
   'Une commode en chêne, quatre-vingt-dix centimètres de haut sur un mètre de large et cinquante de profondeur, trois tiroirs à queues d''aronde. Le plateau est fendu sur toute sa longueur, le pied avant gauche est cassé net, et deux poignées en laiton manquent.',
   'Les queues d''aronde renseignent sur la facture du meuble, et « cassé net » précise la nature de la réparation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S11 / INSUFFICIENT
  ('3665456e-0d15-502e-bcd2-2e0190d675d3', '01f499c2-8800-5a5e-a029-228048a20d89', 'INSUFFICIENT',
   'Bonjour, je voudrais que tout soit bien tenu, avec la pelouse tondue régulièrement et les haies taillées deux fois par an. J''aimerais aussi qu''on s''occupe du désherbage. Pouvez-vous me dire votre tarif horaire ?',
   'Vous listez vos attentes. Le jardinier demandait la description du jardin pour pouvoir chiffrer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S11 / EXPECTED
  ('0ef7f30a-4817-553b-9099-47473e41fbbb', '01f499c2-8800-5a5e-a029-228048a20d89', 'EXPECTED',
   'Le jardin fait environ trois cents mètres carrés, dont deux cents de pelouse. Il y a une haie de laurier sur deux côtés, quatre arbres fruitiers et un massif le long de la maison. L''accès se fait par un portail d''un mètre vingt.',
   'Surfaces, composition, linéaire de haie, accès : le jardinier peut chiffrer sans se déplacer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S11 / EXCELLENT
  ('898c8756-788b-5e3e-bc75-6d0511eb53f4', '01f499c2-8800-5a5e-a029-228048a20d89', 'EXCELLENT',
   'Le jardin fait environ trois cents mètres carrés, dont deux cents de pelouse en pente douce. Haie de laurier sur deux côtés, soit une trentaine de mètres, quatre arbres fruitiers et un massif le long de la maison. L''accès se fait par un portail d''un mètre vingt, sans marche.',
   'La pente, le linéaire chiffré et l''absence de marche sont les trois éléments qui font varier un devis d''entretien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S12 / INSUFFICIENT
  ('72c9525f-ef6a-5506-a88e-6e70bd474220', '2a2e86d5-4a14-5057-9dbf-326b26f407a1', 'INSUFFICIENT',
   'Bonjour, mon fils le rapportera lundi avec l''archet et la housse. Il en a pris grand soin toute l''année et il a beaucoup progressé grâce à vous. Merci encore pour ce prêt, cela nous a vraiment aidés.',
   'Vous parlez du retour et de l''année écoulée. Le professeur demandait à quoi ressemble l''instrument.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S12 / EXPECTED
  ('d6f461d4-818a-5b39-9268-2e8f53029139', '2a2e86d5-4a14-5057-9dbf-326b26f407a1', 'EXPECTED',
   'C''est un violon trois quarts, avec un vernis brun foncé. La housse est noire, avec une poche avant. L''archet a une mèche claire. Il y a une petite éraflure sur la table, côté droit, qui existait déjà.',
   'Type, taille, vernis, accessoires, marque préexistante : le professeur peut vérifier le retour.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S12 / EXCELLENT
  ('d2e8a7b1-71d2-566f-842d-297f3c7913c6', '2a2e86d5-4a14-5057-9dbf-326b26f407a1', 'EXCELLENT',
   'C''est un violon trois quarts, vernis brun foncé, avec une petite éraflure sur la table côté droit — elle existait déjà à la remise, c''est noté sur la fiche. La housse noire a une poche avant déchirée au coin. L''archet a une mèche claire, complète.',
   'Distinguer ce qui préexistait de ce qui s''est abîmé pendant l''année est exactement ce qu''une vérification de retour demande.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S13 / INSUFFICIENT
  ('550cdda5-8879-58ed-b39a-27cc3fbbf83e', '4d5c3b8e-acc7-5786-ac60-10dedb864c49', 'INSUFFICIENT',
   'Bonjour, la cave est incluse dans la vente, elle appartient au lot depuis l''origine. Elle est privative et fermée par une porte avec serrure. Vous en aurez la clé à la signature chez le notaire.',
   'Vous décrivez le statut juridique. L''acheteur demandait à quoi ressemble la cave, pour savoir s''il peut y stocker.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S13 / EXPECTED
  ('fd1aa513-b94d-5960-b4d4-a43893b6bf6d', '4d5c3b8e-acc7-5786-ac60-10dedb864c49', 'EXPECTED',
   'La cave fait environ huit mètres carrés, avec un plafond à deux mètres. Les murs sont en pierre et le sol en terre battue. Il n''y a pas de fenêtre mais une ampoule au plafond. Elle reste sèche toute l''année.',
   'Surface, hauteur, matériaux, éclairage, humidité : l''acheteur sait s''il peut y entreposer du matériel.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S13 / EXCELLENT
  ('c238ed82-f582-5592-a915-85fb245d084e', '4d5c3b8e-acc7-5786-ac60-10dedb864c49', 'EXCELLENT',
   'La cave fait environ huit mètres carrés, plafond à deux mètres, murs en pierre et sol en terre battue. Une ampoule au plafond, pas de fenêtre. Elle est restée sèche ces cinq dernières années, même en hiver. L''escalier est raide et l''ouverture de porte fait soixante-dix centimètres.',
   'L''escalier raide et la largeur de porte décident de ce qui peut réellement descendre : c''est la précision utile.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S14 / INSUFFICIENT
  ('f30499b8-f7f3-54a4-8d52-77000b8c2f11', '03a7ca1e-250e-589f-a74a-e46b0282635e', 'INSUFFICIENT',
   'Bonjour, je l''ai acheté il y a environ trois ans dans un magasin qui a fermé depuis. Je n''ai plus la facture ni la boîte. Il est toujours sous garantie normalement, puisque la garantie est de cinq ans sur cette gamme.',
   'Vous parlez de l''achat et de la garantie. Ils demandaient à quoi ressemble l''appareil, n''ayant pas le modèle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S14 / EXPECTED
  ('491a43ab-19bf-56a2-9d75-d46b8164f567', '03a7ca1e-250e-589f-a74a-e46b0282635e', 'EXPECTED',
   'C''est un aspirateur traîneau rouge et gris, d''environ quarante centimètres de long. Il a une molette de puissance sur le dessus et deux pédales, une pour l''enrouleur et une pour l''arrêt. Il s''éteint tout seul après dix minutes.',
   'Type, couleurs, taille, commandes, symptôme : le service peut identifier le modèle et la panne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S14 / EXCELLENT
  ('d2493750-8e23-54d8-8bf8-14f05691c551', '03a7ca1e-250e-589f-a74a-e46b0282635e', 'EXCELLENT',
   'C''est un aspirateur traîneau rouge et gris, environ quarante centimètres de long, avec une molette de puissance graduée de un à cinq sur le dessus et deux pédales à l''arrière. Il s''éteint seul au bout de dix minutes, puis refuse de redémarrer avant une heure.',
   'La molette graduée identifie la gamme, et le délai avant redémarrage oriente vers une sécurité thermique.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S15 / INSUFFICIENT
  ('033341fc-3565-501b-89e8-1bc6cb624943', '959e75f0-0c70-5290-ae72-27eeaa19219d', 'INSUFFICIENT',
   'Ce bassin est un élément essentiel du patrimoine de notre commune et nous nous battons depuis quatre ans pour sa rénovation. Nous avons réuni plus de six cents signatures. Il est temps que la municipalité prenne ses responsabilités.',
   'Vous plaidez pour la rénovation. Le journaliste demandait à quoi ressemble le bassin, pour l''écrire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S15 / EXPECTED
  ('7ab3786e-7991-5218-813a-d81e425bce5b', '959e75f0-0c70-5290-ae72-27eeaa19219d', 'EXPECTED',
   'Le bassin est ovale, d''environ quinze mètres sur huit. Il est bordé de pierres de taille et le fond est en béton. Une fontaine centrale ne fonctionne plus depuis trois ans. Des saules l''entourent sur le côté ouest.',
   'Forme, dimensions, matériaux, état, environnement : le journaliste a de quoi écrire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11-S15 / EXCELLENT
  ('ba57e10c-24cc-5952-9eb7-597d11c1dcd1', '959e75f0-0c70-5290-ae72-27eeaa19219d', 'EXCELLENT',
   'Le bassin est ovale, environ quinze mètres sur huit, bordé de pierres de taille dont plusieurs se sont descellées. Le fond en béton est fissuré côté nord. La fontaine centrale, en fonte, ne fonctionne plus depuis trois ans. Trois saules l''ombragent à l''ouest.',
   'Chaque dégradation est localisée et la matière de la fontaine est précisée : l''article peut être écrit sans revoir les lieux.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S16 / INSUFFICIENT
  ('f45f7218-156c-5807-b7db-6b8d3e6f57c0', 'd7c65e2f-9a7d-5fc4-a7e1-5caaf8264a6c', 'INSUFFICIENT',
   'C''est un chèque d''un montant assez important, émis il y a quelques semaines au profit d''un artisan. Il était dans une enveloppe blanche que j''ai postée près de chez moi. Il n''a jamais été encaissé apparemment.',
   '« Assez important », « quelques semaines », « un artisan » : rien ne se vérifie dans un fichier bancaire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S16 / EXPECTED
  ('1c069eac-ad6a-57ad-9260-20196b8b589b', 'd7c65e2f-9a7d-5fc4-a7e1-5caaf8264a6c', 'EXPECTED',
   'Il s''agit du chèque de quatre cent vingt euros, émis le 14 mars à l''ordre de l''entreprise Rivière. C''est le numéro 0047123 du carnet. Il a été posté le 15 mars depuis la boîte de la rue Carnot.',
   'Montant, date, bénéficiaire, numéro, lieu et date de dépôt : chaque élément est vérifiable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S16 / EXCELLENT
  ('44c359ba-5bfc-5800-a49a-9be561ff64e3', 'd7c65e2f-9a7d-5fc4-a7e1-5caaf8264a6c', 'EXCELLENT',
   'Il s''agit du chèque de quatre cent vingt euros, émis le 14 mars à l''ordre de l''entreprise Rivière, numéro 0047123 du carnet ouvert en janvier. Il a été posté le 15 mars vers dix-huit heures depuis la boîte de la rue Carnot, dans une enveloppe blanche sans fenêtre.',
   'Même nature d''éléments, poussés d''un cran : l''heure de dépôt et le type d''enveloppe restent tous deux vérifiables.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S17 / INSUFFICIENT
  ('bb89b63e-2007-51df-a2d1-506d5fd8a0af', 'a70c7fba-9c0a-5823-8e3f-480d8b13eb88', 'INSUFFICIENT',
   'Ça fuit pas mal dans la salle de bains, surtout le soir quand on utilise beaucoup d''eau. Il y a de l''humidité un peu partout et une odeur désagréable. C''est vraiment embêtant, il faudrait venir rapidement.',
   '« Pas mal », « un peu partout » : le plombier ne sait ni où chercher ni quel matériel prendre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S17 / EXPECTED
  ('af8b2f2b-9b15-53dc-8106-5a5609c0a815', 'a70c7fba-9c0a-5823-8e3f-480d8b13eb88', 'EXPECTED',
   'La fuite se trouve sous le lavabo de la salle de bains, au raccord du siphon, à environ soixante centimètres du sol. Il tombe une goutte toutes les dix secondes. Une bassine d''un litre se remplit en une nuit.',
   'Pièce, élément, hauteur, débit chiffré : tout est vérifiable et permet de préparer l''intervention.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S17 / EXCELLENT
  ('760828b4-6e3f-523f-9d07-6ac283c4dbf0', 'a70c7fba-9c0a-5823-8e3f-480d8b13eb88', 'EXCELLENT',
   'La fuite se trouve sous le lavabo de la salle de bains, au raccord du siphon côté mur, à environ soixante centimètres du sol. Une goutte toutes les dix secondes, soit un litre par nuit. Le tuyau est en PVC gris de trente-deux millimètres.',
   'Le côté du raccord, la matière et le diamètre du tuyau décident du matériel à emporter.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S18 / INSUFFICIENT
  ('cb83af9a-210b-5320-a029-98df56318388', 'bf712839-fd0c-5f91-b25e-7931e7dc17c7', 'INSUFFICIENT',
   'Le mien est assez grand et plutôt lourd, un carton normal quoi. Il vient d''un site de vente en ligne. Je crois qu''il y a une étiquette dessus avec mon nom. Vous devriez le reconnaître sans difficulté.',
   '« Assez grand », « plutôt lourd », « un carton normal » : avec deux colis au même nom, rien ne permet de choisir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S18 / EXPECTED
  ('851cbfb8-14cf-5059-8251-fbae0d36a413', 'bf712839-fd0c-5f91-b25e-7931e7dc17c7', 'EXPECTED',
   'Le mien mesure environ quarante centimètres sur trente et pèse à peu près trois kilos. C''est un carton brun fermé par du ruban adhésif bleu. L''étiquette est collée sur le dessus, en haut à gauche.',
   'Dimensions, poids, couleur, ruban, position de l''étiquette : chaque élément se vérifie d''un coup d''œil.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S18 / EXCELLENT
  ('1931011d-9bfe-5d5f-96f0-d5a0ab851d54', 'bf712839-fd0c-5f91-b25e-7931e7dc17c7', 'EXCELLENT',
   'Le mien mesure environ quarante centimètres sur trente et dix de haut, pour trois kilos. Carton brun fermé par du ruban adhésif bleu, avec l''étiquette collée sur le dessus en haut à gauche et un autocollant « fragile » orange sur le flanc droit.',
   'La troisième dimension et l''autocollant orange sont deux repères de plus, aussi vérifiables que les premiers.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S19 / INSUFFICIENT
  ('3bd398ee-2bd1-5005-a2cc-df19a0162b9d', '835318e4-62c0-5a63-9c7c-85e68152a265', 'INSUFFICIENT',
   'Il y a beaucoup d''humidité sur le mur, c''est vraiment très visible et ça s''étend de plus en plus vite. La peinture est en train de partir par endroits. C''est franchement inquiétant, il faudrait venir vite.',
   '« Beaucoup », « par endroits », « de plus en plus vite » : l''expert ne peut rien préparer avec cela.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S19 / EXPECTED
  ('8488dd2b-7691-5d3f-a922-3cda0dc61c5f', '835318e4-62c0-5a63-9c7c-85e68152a265', 'EXPECTED',
   'Les traces se trouvent sur le mur nord de la chambre, derrière l''armoire. Elles partent de la plinthe et montent à environ quatre-vingts centimètres, sur un mètre cinquante de large. La peinture cloque et le mur est noir par plaques.',
   'Mur, emplacement, hauteur, largeur, aspect : tout est mesurable et vérifiable sur place.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S19 / EXCELLENT
  ('af70bf6d-141d-5fab-aaed-2ee6827736b5', '835318e4-62c0-5a63-9c7c-85e68152a265', 'EXCELLENT',
   'Les traces se trouvent sur le mur nord de la chambre, derrière l''armoire. Elles partent de la plinthe et montent à quatre-vingts centimètres, sur un mètre cinquante de large. La peinture cloque sur toute la zone et trois plaques noires de dix centimètres environ sont apparues depuis février.',
   'La taille des plaques et la date d''apparition ajoutent deux éléments datés et mesurés, décisifs pour une expertise.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S20 / INSUFFICIENT
  ('7cdf8f26-2804-53f6-b559-e61b88b2c9bf', 'af343de7-7345-5fc8-88b7-388a668cac15', 'INSUFFICIENT',
   'C''était quelqu''un qui avait vraiment l''air louche, il tournait autour de l''entrée sans raison. Il m''a semblé jeune et pas du quartier. Je n''ai pas aimé sa façon de regarder les boîtes aux lettres.',
   '« L''air louche », « pas du quartier » sont des impressions. Rien ne permet de retrouver la personne sur un enregistrement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S20 / EXPECTED
  ('ec20407b-f19c-59fc-837c-4182464da91b', 'af343de7-7345-5fc8-88b7-388a668cac15', 'EXPECTED',
   'La personne est passée mardi entre quatorze heures et quatorze heures dix. C''est un homme d''environ un mètre quatre-vingts, en veste noire à capuche et pantalon clair. Il portait un sac à dos gris et il est resté trois ou quatre minutes dans le hall.',
   'Heure, taille, vêtements, sac, durée : chaque élément se retrouve sur un enregistrement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S20 / EXCELLENT
  ('f4a83bf8-30ee-55f6-a65d-59d37adfad8e', 'af343de7-7345-5fc8-88b7-388a668cac15', 'EXCELLENT',
   'La personne est passée mardi entre quatorze heures et quatorze heures dix. Un homme d''environ un mètre quatre-vingts, veste noire à capuche, pantalon clair, sac à dos gris porté sur une seule épaule. Il est resté trois à quatre minutes dans le hall, puis est ressorti côté cour.',
   'La façon de porter le sac et la sortie côté cour sont deux faits observables de plus, toujours sans jugement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S21 / INSUFFICIENT
  ('4b248b91-c5f6-5e82-96d2-778215340db8', '69cf4bcf-b134-5766-873b-a788ed043ee4', 'INSUFFICIENT',
   'Il y a un bruit bizarre qui revient souvent, surtout depuis quelques temps. C''est assez fort et ça m''inquiète un peu. Parfois ça disparaît pendant plusieurs jours puis ça revient sans prévenir.',
   '« Bizarre », « souvent », « parfois » : le garagiste ne pourra pas reproduire le bruit lors de l''essai.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S21 / EXPECTED
  ('edc31825-6b61-5afc-bc13-e1b6791ea6ad', '69cf4bcf-b134-5766-873b-a788ed043ee4', 'EXPECTED',
   'Le bruit apparaît à partir de soixante kilomètres-heure, seulement en virage à droite. C''est un grincement métallique qui vient de la roue avant gauche. Il dure tant que le virage dure et s''arrête ensuite.',
   'Vitesse, condition, nature, localisation, durée : le bruit est reproductible lors d''un essai.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S21 / EXCELLENT
  ('0356d2d2-b449-5831-874f-fdd505c44507', '69cf4bcf-b134-5766-873b-a788ed043ee4', 'EXCELLENT',
   'Le bruit apparaît à partir de soixante kilomètres-heure, seulement en virage à droite, jamais à gauche. C''est un grincement métallique venant de la roue avant gauche. Il dure tant que le virage dure, et il est nettement plus fort par temps sec.',
   '« Jamais à gauche » et l''influence du temps sec sont deux conditions négatives et positives qui orientent le diagnostic.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S22 / INSUFFICIENT
  ('a7252369-be3a-53af-b682-bdf7b5a3ae8f', '95f4213b-aa2a-5ca8-85e8-77ec89fe5802', 'INSUFFICIENT',
   'C''est une plante magnifique que ma voisine m''a donnée il y a deux ans. Elle pousse très bien et tout le monde me demande son nom. Elle fleurit chaque année et elle sent vraiment très bon.',
   'Aucun caractère observable : la jardinerie ne peut pas identifier une plante sur son parfum et son succès.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S22 / EXPECTED
  ('a0d2b3cc-934a-5154-baf0-5706f467dd0d', '95f4213b-aa2a-5ca8-85e8-77ec89fe5802', 'EXPECTED',
   'La plante mesure environ un mètre vingt. Les feuilles sont allongées, vert foncé, avec un bord dentelé, longues de dix centimètres. Les fleurs sont blanches, en grappes, et apparaissent en mai. La tige est ligneuse à la base.',
   'Taille, forme et bord des feuilles, couleur et disposition des fleurs, période, tige : tout est observable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S22 / EXCELLENT
  ('f9d4da09-b49d-527b-a3d9-b271329592e3', '95f4213b-aa2a-5ca8-85e8-77ec89fe5802', 'EXCELLENT',
   'La plante mesure environ un mètre vingt. Feuilles allongées de dix centimètres, vert foncé, à bord dentelé, opposées deux par deux sur la tige. Fleurs blanches en grappes serrées, ouvertes début mai pendant trois semaines. Tige ligneuse à la base, verte au sommet.',
   'La disposition des feuilles et la durée de floraison sont précisément les caractères qu''utilise une clé d''identification.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S23 / INSUFFICIENT
  ('8cc7acbe-e306-5199-a80b-172df1b5a914', '503236a9-7aaf-5ce3-9143-e4e2e16cff00', 'INSUFFICIENT',
   'Elle est largement assez grande, ne vous inquiétez pas, tous les locataires précédents y garaient leur voiture sans aucun problème. C''est une place très pratique et l''accès est facile même aux heures de pointe.',
   '« Largement assez grande » ne dit rien à quelqu''un qui a un monospace : aucune mesure, aucune contrainte.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S23 / EXPECTED
  ('ee48831e-463d-58fb-ae87-776c0f65314d', '503236a9-7aaf-5ce3-9143-e4e2e16cff00', 'EXPECTED',
   'La place fait deux mètres quarante de large sur cinq mètres de long. Elle est en sous-sol, avec une hauteur limitée à un mètre quatre-vingt-dix à l''entrée. La rampe d''accès est en pente et le virage avant la place est assez serré.',
   'Largeur, longueur, hauteur limite, accès : le locataire peut vérifier avec les dimensions de son véhicule.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S23 / EXCELLENT
  ('53239d51-de5d-5714-baf7-0042c745ffd9', '503236a9-7aaf-5ce3-9143-e4e2e16cff00', 'EXCELLENT',
   'La place fait deux mètres quarante de large sur cinq mètres, en sous-sol, avec une hauteur limitée à un mètre quatre-vingt-dix à l''entrée du parking. La rampe descend sur quinze mètres et le virage juste avant la place se prend en deux manœuvres avec un véhicule long.',
   'Le nombre de manœuvres est une information concrète, vérifiable, et bien plus honnête que « accès facile ».', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S24 / INSUFFICIENT
  ('234a3bba-e938-594d-bed2-a651d33612b6', '53f3cc6c-bf61-5edf-b45a-a9fe257f4ac9', 'INSUFFICIENT',
   'Madame, Monsieur, il manque un papier important que j''avais pourtant bien joint à mon envoi. Je l''avais mis avec les autres dans la même enveloppe. C''est très ennuyeux car mon dossier est bloqué depuis.',
   '« Un papier important » ne permet aucune recherche : ni nature, ni date, ni émetteur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S24 / EXPECTED
  ('61605f75-36ea-5c0c-8e31-ec5fbecc8906', '53f3cc6c-bf61-5edf-b45a-a9fe257f4ac9', 'EXPECTED',
   'Il s''agit de l''attestation d''hébergement établie le 12 février par Monsieur Diallo, mon logeur. C''est une feuille A4 manuscrite, signée en bas à droite, accompagnée d''une copie de sa pièce d''identité.',
   'Nature, date, émetteur, format, signature, annexe : la pièce est identifiable dans un dossier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S24 / EXCELLENT
  ('d18c0ed8-cc29-50d5-8057-712a26812026', '53f3cc6c-bf61-5edf-b45a-a9fe257f4ac9', 'EXCELLENT',
   'Il s''agit de l''attestation d''hébergement établie le 12 février par Monsieur Diallo, mon logeur, domicilié au 7 rue des Tilleuls. Une feuille A4 manuscrite à l''encre bleue, signée en bas à droite, agrafée à une copie recto-verso de sa carte d''identité.',
   'L''adresse, l''encre et l''agrafage sont trois repères matériels supplémentaires, tous vérifiables dans une pile de dossiers.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S25 / INSUFFICIENT
  ('2f7e4bf2-122d-5398-bb28-7c9fb6dc4125', 'fdc7defc-d074-584e-80ce-c8fac475c478', 'INSUFFICIENT',
   'L''accès est vraiment compliqué, la rue est étroite et il y a souvent des voitures garées n''importe comment. Le passage est un peu juste pour un gros véhicule. Il vaudrait mieux venir tôt le matin pour éviter les problèmes.',
   '« Étroite », « un peu juste » : impossible de choisir un camion sur ces mots.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S25 / EXPECTED
  ('c43e1c4e-b785-50f5-8e00-9db1c1e140ac', 'fdc7defc-d074-584e-80ce-c8fac475c478', 'EXPECTED',
   'L''accès se fait par une rue de trois mètres cinquante de large, en sens unique. Le porche de l''immeuble mesure deux mètres dix de haut et deux mètres de large. Il y a quarante mètres entre la rue et la cage d''escalier.',
   'Largeur de rue, sens, dimensions du porche, distance de portage : le camion se choisit sur ces chiffres.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S25 / EXCELLENT
  ('10ef8561-2f43-5475-8c44-8ec20345a19a', 'fdc7defc-d074-584e-80ce-c8fac475c478', 'EXCELLENT',
   'L''accès se fait par une rue de trois mètres cinquante en sens unique, sans stationnement possible devant. Le porche mesure deux mètres dix de haut sur deux de large, et quarante mètres séparent la rue de la cage d''escalier, dont vingt en pente légère.',
   'L''absence de stationnement et la portion en pente changent le devis : deux faits vérifiables de plus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S26 / INSUFFICIENT
  ('468d68ee-58d2-5ecc-9b3c-0281f13a3682', '57b6aa6b-ccc1-52fc-8ee6-32ce397bbb25', 'INSUFFICIENT',
   'Tu la reconnaîtras facilement, elle est très souriante et vraiment adorable. Elle travaille avec nous depuis longtemps et elle connaît tout le catalogue par cœur. Demande-lui ce que tu veux, elle saura te répondre.',
   'Souriante et adorable ne se voient pas de loin dans un salon bondé, et ne la distinguent pas des autres hôtesses.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S26 / EXPECTED
  ('b5b2d0a5-774d-56f7-a70b-6e3a641e987d', '57b6aa6b-ccc1-52fc-8ee6-32ce397bbb25', 'EXPECTED',
   'Tu la trouveras au comptoir de droite du stand 24. C''est une femme d''environ trente ans, un mètre soixante-dix, cheveux noirs attachés. Elle porte le polo bleu de l''entreprise et un badge au nom de Sonia Merle.',
   'Position, âge, taille, cheveux, uniforme, badge nommé : chaque élément se vérifie sur place.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S26 / EXCELLENT
  ('479c7216-d819-5cf5-a71e-ff6bc81d0c61', '57b6aa6b-ccc1-52fc-8ee6-32ce397bbb25', 'EXCELLENT',
   'Tu la trouveras au comptoir de droite du stand 24, celui qui fait l''angle de l''allée C. Une femme d''environ trente ans, un mètre soixante-dix, cheveux noirs attachés, polo bleu de l''entreprise et badge « Sonia Merle ». Elle est la seule du stand à porter des lunettes.',
   'L''angle d''allée et « la seule à porter des lunettes » transforment une description en identification certaine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S27 / INSUFFICIENT
  ('a48de944-f692-58d9-8149-3d363797d6ac', '1f251b67-1a99-592c-a73d-b67d40ec0ce0', 'INSUFFICIENT',
   'Nous avons des coupures tout le temps depuis le début de l''hiver, c''est vraiment insupportable. Parfois ça dure longtemps, parfois c''est très bref. Cela arrive surtout le soir quand tout le monde est à la maison.',
   '« Tout le temps », « parfois », « surtout le soir » : aucun relevé exploitable pour une réclamation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S27 / EXPECTED
  ('a8b1cb09-f9cb-5fc3-a205-f2172cac00f0', '1f251b67-1a99-592c-a73d-b67d40ec0ce0', 'EXPECTED',
   'J''ai relevé trois coupures : le 4 janvier de dix-neuf heures dix à dix-neuf heures quarante, le 11 janvier de vingt heures à vingt heures cinq, et le 19 janvier de dix-huit heures trente à vingt heures quinze.',
   'Trois dates, trois plages horaires : le fournisseur peut confronter le relevé à son réseau.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S27 / EXCELLENT
  ('2de5e86b-7fcf-5e5e-9fc3-644318f0a647', '1f251b67-1a99-592c-a73d-b67d40ec0ce0', 'EXCELLENT',
   'J''ai relevé trois coupures : le 4 janvier de dix-neuf heures dix à dix-neuf heures quarante, le 11 janvier de vingt heures à vingt heures cinq, et le 19 janvier de dix-huit heures trente à vingt heures quinze. À chaque fois, seul le tableau du bas a disjoncté.',
   'Le détail du tableau concerné est le seul élément technique qui manquait, et il est aussi vérifiable que les horaires.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S28 / INSUFFICIENT
  ('97100da3-0078-53db-9ef2-5a4eb475e0c1', '04598999-329c-53a9-8faf-7bb3cd97167f', 'INSUFFICIENT',
   'Après le portail, vous continuez tout droit un petit moment, puis vous tournez au niveau des bâtiments. Ce n''est pas très loin, vous verrez c''est bien indiqué. Mon bâtiment est celui qui est un peu en retrait.',
   '« Un petit moment », « au niveau des bâtiments », « un peu en retrait » : rien ne se repère pour qui ne connaît pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S28 / EXPECTED
  ('f78f123e-65b1-577a-b334-cb3342dbb34f', '04598999-329c-53a9-8faf-7bb3cd97167f', 'EXPECTED',
   'Après le portail, comptez cinquante mètres tout droit jusqu''à un grand cèdre. Tournez à gauche : le bâtiment C est le deuxième, avec une façade jaune. Ma porte est la première à droite au rez-de-chaussée, numéro 4.',
   'Distance, repère visible, direction, couleur, position, numéro : chaque étape se vérifie depuis la précédente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S28 / EXCELLENT
  ('4feecd59-65cc-5f5e-a7c2-b76f96130ef8', '04598999-329c-53a9-8faf-7bb3cd97167f', 'EXCELLENT',
   'Après le portail, comptez cinquante mètres tout droit jusqu''à un grand cèdre, seul arbre de l''allée. Tournez à gauche : bâtiment C, le deuxième, façade jaune, lettre peinte en noir au-dessus de la porte. Ma porte est la première à droite au rez-de-chaussée, numéro 4.',
   '« Seul arbre de l''allée » et la lettre peinte rendent chaque repère exclusif, ce qui est l''essentiel pour un livreur pressé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S29 / INSUFFICIENT
  ('55bcfefe-9e1d-50a3-ac99-c398a0bddf9d', 'b21205c7-b558-5280-a060-eb619834ffe8', 'INSUFFICIENT',
   'Nous serons une trentaine de personnes à peu près, peut-être un peu plus. Il y aura des enfants et quelques personnes qui ne mangent pas de tout. Je vous préciserai ça plus tard quand j''aurai les réponses.',
   '« Une trentaine », « quelques personnes », « pas de tout » : aucun devis ne se calcule sur ces valeurs.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S29 / EXPECTED
  ('573fe423-aee3-5b5c-b038-33fa0d461757', 'b21205c7-b558-5280-a060-eb619834ffe8', 'EXPECTED',
   'Nous serons exactement trente-deux : vingt-six adultes et six enfants de moins de dix ans. Quatre personnes ne mangent pas de porc, deux sont végétariennes et une est allergique aux fruits à coque.',
   'Effectif exact, répartition, régimes nommés et comptés : le devis peut être établi.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S29 / EXCELLENT
  ('5e488021-5fb3-5369-9646-ce7f43eb7cbb', 'b21205c7-b558-5280-a060-eb619834ffe8', 'EXCELLENT',
   'Nous serons exactement trente-deux : vingt-six adultes et six enfants de moins de dix ans, dont deux de moins de trois ans. Quatre personnes ne mangent pas de porc, deux sont végétariennes, et une est allergique aux fruits à coque, y compris aux traces.',
   'Les moins de trois ans et la mention des traces sont deux précisions qui changent réellement une prestation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S30 / INSUFFICIENT
  ('00ca4e3a-0fdd-57f1-8ea3-f5e8e5f47812', '2c000a7c-85e7-5d90-a2d9-91515714431b', 'INSUFFICIENT',
   'Je me suis déplacée pour rien et personne ne s''est occupé de moi, ce qui est franchement inadmissible pour un cabinet de cette taille. J''ai attendu très longtemps sans aucune explication avant de finir par repartir.',
   'Le reproche remplace le constat : aucune heure, aucun fait observable à vérifier dans le registre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S30 / EXPECTED
  ('e6167b7f-e07a-52af-87a4-3e8e7648972c', '2c000a7c-85e7-5d90-a2d9-91515714431b', 'EXPECTED',
   'Je me suis présentée le 9 avril à quatorze heures, comme indiqué sur ma convocation. La porte du cabinet était fermée et aucun mot n''était affiché. J''ai attendu jusqu''à quatorze heures quarante et je suis repartie.',
   'Date, heure, état des lieux, durée d''attente, heure de départ : tout est vérifiable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C3-S30 / EXCELLENT
  ('c2441611-46b6-5a6a-9e02-97496787c93a', '2c000a7c-85e7-5d90-a2d9-91515714431b', 'EXCELLENT',
   'Je me suis présentée le 9 avril à quatorze heures, comme indiqué sur ma convocation. La porte était fermée à clé, la salle d''attente éteinte, et aucun mot n''était affiché. Deux autres personnes attendaient sur le palier. Je suis repartie à quatorze heures quarante.',
   'L''éclairage, la serrure et les deux témoins sont trois constats matériels de plus, toujours sans le moindre reproche.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S16 / INSUFFICIENT
  ('5b710eb4-5449-5814-98c3-23dfa8dd124b', '3b3bddf9-b179-590d-a704-3c9fdea541b9', 'INSUFFICIENT',
   'Il y a un lave-vaisselle. La maison est en pierre. Les chambres sont à l''étage. Le jardin est grand. Le salon a une cheminée. C''est à trois kilomètres du village. La cuisine est petite.',
   'Toutes les informations sont justes, mais elles se suivent sans ordre : le lecteur saute de l''intérieur au village et revient.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S16 / EXPECTED
  ('6cdb3869-874e-52d6-a004-ae645def181f', '3b3bddf9-b179-590d-a704-3c9fdea541b9', 'EXPECTED',
   'De l''extérieur, c''est une maison en pierre avec un grand jardin clos, à trois kilomètres du village. Au rez-de-chaussée, un salon avec cheminée et une petite cuisine équipée. Les trois chambres sont à l''étage. On s''y sent très bien.',
   'L''ordre va de l''extérieur au rez-de-chaussée puis à l''étage : le lecteur avance sans revenir en arrière.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S16 / EXCELLENT
  ('0fd4ddbe-b867-5e22-87f8-4ba447fd9147', '3b3bddf9-b179-590d-a704-3c9fdea541b9', 'EXCELLENT',
   'De l''extérieur, c''est une maison en pierre entourée d''un grand jardin clos, à trois kilomètres du village. On entre dans un salon avec cheminée, prolongé par une petite cuisine équipée. L''escalier mène aux trois chambres. Rien n''est luxueux, mais tout fonctionne.',
   '« On entre », « prolongé par », « l''escalier mène » : le lecteur est guidé de pièce en pièce, et la fin referme sans lister.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S17 / INSUFFICIENT
  ('f989aca2-0a5a-5cec-8b88-6c6a4a0e8257', '4cefd021-3aa7-5fa3-a1d9-9d69484207e2', 'INSUFFICIENT',
   'Il rit beaucoup. Il est grand. Il vient de Lille. Il a une barbe. Il pose beaucoup de questions. Il a quarante ans environ. Il porte des chemises. Il connaît bien le logiciel.',
   'Huit phrases courtes sans lien : l''aspect, l''origine et le caractère se mélangent, et rien ne referme.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S17 / EXPECTED
  ('aa3b56d4-b160-56c5-97c1-42c543654397', '4cefd021-3aa7-5fa3-a1d9-9d69484207e2', 'EXPECTED',
   'C''est un homme d''une quarantaine d''années, grand, avec une barbe courte. Il porte des chemises claires. Il vient de Lille et il connaît déjà bien notre logiciel. Il rit facilement et pose beaucoup de questions. Tu l''apprécieras.',
   'L''aspect, puis le parcours, puis le caractère : trois groupes cohérents, et une phrase finale qui referme.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S17 / EXCELLENT
  ('fc957318-2b39-5360-b71e-c0c545a6608e', '4cefd021-3aa7-5fa3-a1d9-9d69484207e2', 'EXCELLENT',
   'C''est un homme d''une quarantaine d''années, grand, la barbe courte, toujours en chemise claire. Il arrive de Lille et connaît déjà notre logiciel, ce qui aide. Côté caractère, il rit facilement et pose beaucoup de questions — plutôt bon signe.',
   '« Côté caractère » annonce le changement de groupe, et la remarque finale referme sans ajouter de trait nouveau.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S18 / INSUFFICIENT
  ('7d2ae671-f7d0-54e9-b13d-50555cfcf1cb', '2f30588d-1dce-556e-b059-561661a5fd30', 'INSUFFICIENT',
   'Il y a un autocollant rond sur la quatrième page. L''élastique est cassé. C''est un carnet. La couverture est bleue. Il fait la taille d''une main. Les pages sont quadrillées. Mon prénom est écrit dedans.',
   'On commence par la quatrième page et on finit par le format : le lecteur ne peut pas construire l''image.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S18 / EXPECTED
  ('4b36ecdc-3eef-54ef-9efb-87964b2449b4', '2f30588d-1dce-556e-b059-561661a5fd30', 'EXPECTED',
   'C''est un carnet de la taille d''une main, à couverture bleue rigide. Les pages sont quadrillées. Un élastique de fermeture est cassé. Mon prénom, Awa, est écrit sur la première page. Il est assez usé.',
   'Format, couverture, pages, fermeture, marque personnelle : l''ordre va de l''ensemble au détail.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S18 / EXCELLENT
  ('388e1026-8c1f-542c-826b-db7b4f728a1c', '2f30588d-1dce-556e-b059-561661a5fd30', 'EXCELLENT',
   'C''est un carnet de la taille d''une main, à couverture bleue rigide et assez usée aux coins. Les pages sont quadrillées et l''élastique de fermeture a cassé. Sur la première page, mon prénom, Awa, est écrit au feutre noir.',
   'Chaque phrase reste sur un niveau — l''objet, puis l''intérieur, puis la marque — et la dernière ferme naturellement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S19 / INSUFFICIENT
  ('2b495e19-2a52-534a-bca5-8d06ef3732c7', '27ab7989-570a-5115-ba45-152a87e65651', 'INSUFFICIENT',
   'Il y a des machines à coudre. C''est au rez-de-chaussée. Il y a une grande table au milieu. L''entrée est vitrée. On y trouve aussi des outils. Le fond sert au bois. Les murs sont blancs.',
   'Le lecteur passe des machines à l''entrée puis au fond : aucun parcours ne se dessine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S19 / EXPECTED
  ('e6b71d54-9122-5fe3-b9fe-7df59183cf48', '27ab7989-570a-5115-ba45-152a87e65651', 'EXPECTED',
   'On entre par une porte vitrée au rez-de-chaussée. La première salle est claire, avec une grande table au milieu et des machines à coudre le long du mur. Au fond, un espace est réservé au travail du bois. C''est simple et bien tenu.',
   'L''entrée, la première salle, le fond : le lecteur traverse l''atelier dans l''ordre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S19 / EXCELLENT
  ('c019b83b-11d6-52e7-a854-97221e436239', '27ab7989-570a-5115-ba45-152a87e65651', 'EXCELLENT',
   'On entre par une porte vitrée au rez-de-chaussée. La première salle est très claire : une grande table au milieu, des machines à coudre alignées le long du mur de gauche. Au fond, derrière une cloison, l''espace bois avec ses outils accrochés. Tout est simple et bien rangé.',
   '« Derrière une cloison » et « le long du mur de gauche » ancrent chaque élément dans le parcours, sans jamais le rompre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S20 / INSUFFICIENT
  ('7199a4aa-3a51-535f-8851-ccbe0255fede', '24564798-d240-564e-8d3c-44eaedd0a367', 'INSUFFICIENT',
   'Elles s''entendent bien. Il y a quatorze joueuses. Trois ont commencé cette année. L''entraîneuse est patiente. Elles ont entre douze et quatorze ans. Elles se prêtent leurs affaires. Deux viennent de l''autre club.',
   'L''ambiance ouvre, l''effectif arrive ensuite, puis les âges : le lecteur ne peut pas se représenter le groupe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S20 / EXPECTED
  ('0620ca8f-d285-5e46-a2e6-e680da343189', '24564798-d240-564e-8d3c-44eaedd0a367', 'EXPECTED',
   'L''équipe compte quatorze joueuses, entre douze et quatorze ans. Trois ont commencé cette année et deux arrivent de l''autre club. L''ambiance est très bonne : elles se prêtent leurs affaires et l''entraîneuse est patiente. Ta fille s''y sentira bien.',
   'Effectif et âges, puis composition, puis ambiance : trois temps, et une clôture nette.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S20 / EXCELLENT
  ('624955e4-7b13-5a16-9734-9f6fd7adf4d2', '24564798-d240-564e-8d3c-44eaedd0a367', 'EXCELLENT',
   'L''équipe compte quatorze joueuses de douze à quatorze ans. Trois ont commencé cette année et deux arrivent de l''autre club, donc les nouvelles ne sont jamais seules. Côté ambiance, elles se prêtent leurs affaires et l''entraîneuse ne hausse jamais la voix.',
   '« Donc les nouvelles ne sont jamais seules » relie deux informations au lieu de les juxtaposer : c''est exactement la compétence.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S21 / INSUFFICIENT
  ('ebddf429-d977-5f7e-b348-8f8ccfc6762e', '13a6ac9a-221f-5b4a-9587-73027baa6774', 'INSUFFICIENT',
   'L''accoudoir gauche est un peu bas. Il est noir. On règle la hauteur. Le tissu est propre. Il a cinq roulettes. Le dossier s''incline. Une roulette grince. Il est en maille.',
   'Aspect, réglages et défauts alternent à chaque phrase : rien ne se construit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S21 / EXPECTED
  ('76623ce4-1593-56e1-9c61-8e99336e1fb3', '13a6ac9a-221f-5b4a-9587-73027baa6774', 'EXPECTED',
   'C''est un fauteuil de bureau noir, en maille respirante, monté sur cinq roulettes. La hauteur se règle et le dossier s''incline. Le tissu est propre. Une roulette grince un peu et l''accoudoir gauche est plus bas que l''autre.',
   'Aspect, puis réglages, puis état : trois groupes nets, et le lecteur sait tout dans l''ordre utile.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S21 / EXCELLENT
  ('eb5d95bc-d693-5682-8c36-8c3ea76b6d2c', '13a6ac9a-221f-5b4a-9587-73027baa6774', 'EXCELLENT',
   'C''est un fauteuil de bureau noir en maille respirante, monté sur cinq roulettes. Côté réglages, la hauteur et l''inclinaison du dossier fonctionnent bien. L''ensemble est propre, à deux détails près : une roulette grince et l''accoudoir gauche est légèrement plus bas.',
   '« Côté réglages » et « à deux détails près » annoncent chaque changement de groupe : la description se suit toute seule.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S22 / INSUFFICIENT
  ('316e4459-12db-52c1-a08f-5da3c98c6d48', 'f028c2c4-8ccb-5ce8-bdce-9f3636899920', 'INSUFFICIENT',
   'Il y a un coin café maintenant. La vitrine est pareille. Les rayons ont été déplacés. L''enseigne est la même. Les murs sont repeints en vert. Le comptoir n''a pas bougé. Il y a des fauteuils.',
   'Ce qui a changé et ce qui est resté s''alternent sans logique : le lecteur ne sait plus ce qu''il reconnaîtra.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S22 / EXPECTED
  ('a3b584b5-315d-5956-a3be-c9fc12291c7c', 'f028c2c4-8ccb-5ce8-bdce-9f3636899920', 'EXPECTED',
   'La vitrine n''a pas bougé, mais tout l''intérieur a changé. Les murs sont repeints en vert et les rayons ont été déplacés le long des côtés. Au fond, un coin café avec des fauteuils a remplacé la réserve. L''enseigne et le comptoir sont les mêmes.',
   'Ce qui reste encadre ce qui change : le lecteur garde ses repères pendant toute la description.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S22 / EXCELLENT
  ('91f20942-cb46-59dc-8d8e-ff9c53378158', 'f028c2c4-8ccb-5ce8-bdce-9f3636899920', 'EXCELLENT',
   'La vitrine n''a pas bougé, mais tout l''intérieur a changé. Les murs sont repeints en vert sombre et les rayons, autrefois au milieu, longent maintenant les côtés. Cela libère le fond, où un coin café a remplacé la réserve. Seul le vieux comptoir est resté.',
   '« Cela libère le fond » relie deux changements par une conséquence : la description devient un raisonnement lisible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S23 / INSUFFICIENT
  ('b91f8027-111c-5a09-9ef4-e682c6bc4fc6', 'c7951ce1-0fcf-511f-bf85-250bac66f117', 'INSUFFICIENT',
   'Il dort beaucoup. Il est très âgé. Sa fille vient le soir. Il a des cheveux blancs. Il parle peu. Il est près de la fenêtre. Il écoute la radio. Il est maigre.',
   'Aspect, habitudes, visites et position s''entremêlent sur huit phrases sans lien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S23 / EXPECTED
  ('53d14f93-8659-5eda-a8f8-ef297ca734a3', 'c7951ce1-0fcf-511f-bf85-250bac66f117', 'EXPECTED',
   'C''est un monsieur âgé, très maigre, avec des cheveux blancs. Son lit est près de la fenêtre. Il parle peu et dort une grande partie de la journée. Il écoute la radio l''après-midi. Sa fille vient chaque soir.',
   'Aspect, place dans la chambre, rythme de la journée, visites : quatre groupes qui se suivent.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S23 / EXCELLENT
  ('f7af3e34-eccc-5f45-b628-a9747e937a9b', 'c7951ce1-0fcf-511f-bf85-250bac66f117', 'EXCELLENT',
   'C''est un monsieur âgé et très maigre, les cheveux blancs, installé près de la fenêtre. Il parle peu et dort une bonne partie de la journée ; l''après-midi, il écoute la radio à voix basse. Sa fille passe chaque soir, ce qui le réveille toujours.',
   'Le point-virgule et « ce qui le réveille toujours » relient les moments de la journée en une progression continue.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S24 / INSUFFICIENT
  ('4d0cdf09-d227-5130-ab7a-728e43ffce7a', 'fe53d5fc-9ee6-59b0-8d4e-1dcfa9e4358d', 'INSUFFICIENT',
   'Le bouton du milieu ne marche pas. Elle est grise. Il faut appuyer longtemps. Elle est près de l''imprimante. Le gobelet tombe de travers. Elle est haute. Le café est correct.',
   'Défauts et aspect s''alternent : on apprend un défaut avant même de savoir de quoi il s''agit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S24 / EXPECTED
  ('6e0c1a2e-de31-5a3c-8f59-fc93ac0326fa', 'fe53d5fc-9ee6-59b0-8d4e-1dcfa9e4358d', 'EXPECTED',
   'C''est une vieille machine grise, assez haute, posée près de l''imprimante. Le bouton du milieu ne répond plus, il faut utiliser celui de droite. Le gobelet tombe souvent de travers. Cela dit, le café est correct.',
   'Aspect et emplacement d''abord, fonctionnement ensuite, et une clôture qui nuance.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S24 / EXCELLENT
  ('055d4a74-de9a-5bc1-b9d7-9ad1f8f088b4', 'fe53d5fc-9ee6-59b0-8d4e-1dcfa9e4358d', 'EXCELLENT',
   'C''est une vieille machine grise, assez haute, posée près de l''imprimante. Le bouton du milieu ne répond plus : il faut appuyer longuement sur celui de droite, et tenir le gobelet, qui tombe souvent de travers. Cela dit, le café est meilleur qu''au rez-de-chaussée.',
   'Les deux-points font découler le geste du défaut, et la comparaison finale referme sans ajouter de trait isolé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S25 / INSUFFICIENT
  ('e841e31f-9682-5c4b-b4d2-cc52f41f58b2', 'c11c2e34-66a7-5d84-b903-6e75a6bb46df', 'INSUFFICIENT',
   'On s''arrête souvent. Nous sommes douze. Il y a des retraités. On marche quinze kilomètres. Deux personnes ont soixante-quinze ans. Le rythme est lent. Certains viennent avec leur chien. On part le matin.',
   'L''effectif, les âges et le rythme sont tous là, mais rien ne montre que l''un explique l''autre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S25 / EXPECTED
  ('8bd8e83a-df52-585c-9c4e-551fa0fee322', 'c11c2e34-66a7-5d84-b903-6e75a6bb46df', 'EXPECTED',
   'Nous sommes une douzaine, surtout des retraités, dont deux ont plus de soixante-quinze ans. Le rythme est donc lent et nous nous arrêtons souvent. Nous faisons environ quinze kilomètres. Certains viennent avec leur chien.',
   '« Donc » relie la composition au rythme : le lecteur comprend le groupe au lieu de le subir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S25 / EXCELLENT
  ('362bc7c3-6bc3-5906-9736-aff1f98e9574', 'c11c2e34-66a7-5d84-b903-6e75a6bb46df', 'EXCELLENT',
   'Nous sommes une douzaine, surtout des retraités, dont deux ont plus de soixante-quinze ans : le rythme est lent et nous nous arrêtons toutes les demi-heures. Quinze kilomètres tout de même, en prenant la journée. Deux ou trois viennent avec leur chien.',
   'Les deux-points et « tout de même » enchaînent cause, conséquence et nuance sans un mot de liaison superflu.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S26 / INSUFFICIENT
  ('053efa0a-2a3d-52bb-91e9-e79c52a61134', 'dc7e0397-28d4-5c0b-ba7f-399b5f445027', 'INSUFFICIENT',
   'La cuisine donne sur le jardin. L''entrée est petite. Le salon fait vingt-cinq mètres carrés. Il y a des toilettes. Le couloir dessert tout. La cuisine est carrelée. Le salon a deux fenêtres.',
   'On commence par la cuisine, on revient à l''entrée, on repart au salon : le parcours est impossible à suivre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S26 / EXPECTED
  ('730c42ef-4792-5990-a9f0-fb049fcdb37f', 'dc7e0397-28d4-5c0b-ba7f-399b5f445027', 'EXPECTED',
   'En entrant, on tombe sur une petite entrée avec des toilettes à droite. Un couloir dessert tout le rez-de-chaussée. À gauche, le salon de vingt-cinq mètres carrés, avec deux fenêtres. Au bout, la cuisine carrelée donne sur le jardin.',
   'Le lecteur avance avec le visiteur : entrée, couloir, salon, cuisine, jardin.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S26 / EXCELLENT
  ('bf5ec1e1-369c-50ef-899b-4f2cf5d30a34', 'dc7e0397-28d4-5c0b-ba7f-399b5f445027', 'EXCELLENT',
   'En entrant, on tombe sur une petite entrée, toilettes à droite. Le couloir dessert tout : à gauche, le salon de vingt-cinq mètres carrés, éclairé par deux fenêtres. Au bout du couloir, la cuisine carrelée ouvre directement sur le jardin. On fait le tour en une minute.',
   'Chaque phrase repart d''où la précédente s''arrêtait, et la dernière referme en donnant l''échelle de l''ensemble.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S27 / INSUFFICIENT
  ('94b781ce-0030-5b81-915e-f10904530416', 'c2004014-8329-5a0a-901b-b70c1fa4f380', 'INSUFFICIENT',
   'La housse est usée. C''est un quatre-quarts. L''archet est neuf. Le vernis est brun. Il y a une éraflure. Les cordes datent de l''an dernier. Le chevalet est d''origine. La mentonnière est en bois.',
   'Housse, instrument, archet, vernis : chaque phrase change de niveau, et l''état se disperse partout.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S27 / EXPECTED
  ('f2d72f1a-ef5e-5b44-a228-8769ce5aca57', 'c2004014-8329-5a0a-901b-b70c1fa4f380', 'EXPECTED',
   'C''est un violon quatre-quarts au vernis brun, avec une mentonnière en bois et un chevalet d''origine. Il vient avec un archet neuf et une housse. Les cordes ont été changées l''an dernier. Il y a une éraflure sur la table.',
   'Instrument, accessoires, état : trois groupes nets, faciles à suivre pour un professeur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S27 / EXCELLENT
  ('43c355a0-f146-57de-b246-112112b0c599', 'c2004014-8329-5a0a-901b-b70c1fa4f380', 'EXCELLENT',
   'C''est un violon quatre-quarts au vernis brun, mentonnière en bois et chevalet d''origine. Il vient avec un archet neuf et une housse, usée mais qui ferme bien. Côté état, les cordes datent de l''an dernier et une éraflure marque la table, sans gêner le son.',
   '« Côté état » regroupe explicitement les défauts, et « sans gêner le son » referme sur ce qui intéresse un professeur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S28 / INSUFFICIENT
  ('c7169be3-3dc2-5c78-9ebe-6f7aaa1c8c3b', '312b55bb-cbf1-52a5-9f2d-da463d9f51da', 'INSUFFICIENT',
   'On ne parle pas beaucoup. Nous sommes quatre. Karim conduit. Le trajet dure quarante minutes. Deux dorment. Nous partons à six heures quarante. Une écoute la radio. Ils travaillent tous à la zone nord.',
   'Effectif, horaire, ambiance et trajet se suivent sans ordre : rien ne relie les personnes à ce qui se passe dans la voiture.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S28 / EXPECTED
  ('181d103c-6562-5c08-ab83-a515b8c8d142', '312b55bb-cbf1-52a5-9f2d-da463d9f51da', 'EXPECTED',
   'Nous sommes quatre, tous à la zone nord. Karim conduit et nous partons à six heures quarante. Comme il est tôt, on ne parle presque pas : deux dorment et une écoute la radio. Le trajet dure quarante minutes.',
   '« Comme il est tôt » relie l''heure au silence : le groupe s''explique au lieu de s''énumérer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S28 / EXCELLENT
  ('80309d51-9775-5515-b802-57bae81b3a94', '312b55bb-cbf1-52a5-9f2d-da463d9f51da', 'EXCELLENT',
   'Nous sommes quatre, tous à la zone nord, et c''est Karim qui conduit. Comme on part à six heures quarante, personne ne parle : deux dorment jusqu''à l''autoroute, une écoute la radio très bas. Quarante minutes qui passent vite.',
   '« Jusqu''à l''autoroute » situe même le sommeil dans le trajet, et la clôture referme sur la durée sans la répéter platement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S29 / INSUFFICIENT
  ('edb3410e-8194-5daf-865d-16876b905277', 'e80a9ed8-63e4-579f-bc10-c9734c056e5f', 'INSUFFICIENT',
   'Il y a une grue. Le terrain est clôturé. C''est au bout de la rue. Ils ont creusé. La palissade est verte. Deux étages sont montés. C''était un parking avant.',
   'Le lecteur voit une grue avant de savoir où il se trouve : l''ordre empêche de construire l''image.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S29 / EXPECTED
  ('1c5624de-0be2-5c72-93de-a73bc82751cf', 'e80a9ed8-63e4-579f-bc10-c9734c056e5f', 'EXPECTED',
   'Le chantier occupe l''ancien parking, au bout de la rue. Le terrain est clôturé par une palissade verte. Ils ont creusé au printemps et deux étages sont déjà montés. Une grue est installée au centre. Cela devrait durer un an.',
   'Emplacement, clôture, avancement, équipement, durée : chaque phrase prolonge la précédente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S29 / EXCELLENT
  ('984c0a7c-b8f0-50c5-847d-13268dda01b9', 'e80a9ed8-63e4-579f-bc10-c9734c056e5f', 'EXCELLENT',
   'Le chantier occupe l''ancien parking, au bout de la rue, derrière une palissade verte. Ils ont creusé au printemps, et deux étages sont montés depuis, avec une grue installée au centre du terrain. Au rythme actuel, cela devrait durer encore un an.',
   '« Depuis » et « au rythme actuel » inscrivent la description dans une durée : le lecteur suit aussi le temps, pas seulement l''espace.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S30 / INSUFFICIENT
  ('d1778995-7bca-597c-9508-a974af121cbe', '0a5e7b55-bfbe-56c1-86ee-ef42a10f6b96', 'INSUFFICIENT',
   'Le cuir est craquelé. C''est un appareil photo à soufflet. Il y a une inscription en allemand. Il fait vingt centimètres. Le soufflet est intact. L''objectif est rond. La poignée est en métal.',
   'L''état ouvre la description, puis la nature, puis la taille : le brocanteur doit tout reconstruire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S30 / EXPECTED
  ('a2114f56-5f9e-53fc-b6f0-26c18c7b7b25', '0a5e7b55-bfbe-56c1-86ee-ef42a10f6b96', 'EXPECTED',
   'C''est un appareil photo à soufflet, d''environ vingt centimètres de long, recouvert de cuir noir. L''objectif est rond et la poignée en métal. Une inscription en allemand figure sur le dessus. Le cuir est craquelé mais le soufflet est intact.',
   'Nature, taille, matière, détails, marques, état : l''ordre descend régulièrement du général au particulier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C8-S30 / EXCELLENT
  ('541eda83-2138-5732-8142-e91e500dcddc', '0a5e7b55-bfbe-56c1-86ee-ef42a10f6b96', 'EXCELLENT',
   'C''est un appareil photo à soufflet d''environ vingt centimètres, recouvert de cuir noir, avec un objectif rond et une poignée métallique. Sur le dessus, une inscription en allemand, encore lisible. Le cuir est craquelé aux angles, mais le soufflet n''a aucun trou.',
   '« Encore lisible » et « aucun trou » sont deux précisions d''état placées exactement là où le brocanteur les attend.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S1 / INSUFFICIENT
  ('31e793c4-7148-52b5-b521-221808ece92f', 'c8e5f66e-e9c2-542a-9fdc-a83e3cc26ef6', 'INSUFFICIENT',
   'Je suis parti très tôt le matin. Le train était presque vide et je suis arrivé à Nantes vers neuf heures. Ensuite j''ai pris le tramway jusqu''au centre-ville.',
   'Le voyage est raconté, mais rien ne dit pourquoi ce train plutôt que l''autre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S1 / EXPECTED
  ('d4cb835c-633a-5266-b1f2-93f4807651f4', 'c8e5f66e-e9c2-542a-9fdc-a83e3cc26ef6', 'EXPECTED',
   'J''ai pris celui de six heures dix parce que le suivant arrivait seulement à dix heures trente. Avec une demi-heure de marge, le moindre retard me faisait manquer mon rendez-vous.',
   'La raison est donnée et elle explique vraiment le choix.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S1 / EXCELLENT
  ('77747c3c-4c0e-5fb8-8ec0-fa073eec89bb', 'c8e5f66e-e9c2-542a-9fdc-a83e3cc26ef6', 'EXCELLENT',
   'J''ai pris celui de six heures dix parce que le suivant n''arrivait qu''à dix heures trente, pour un rendez-vous à onze heures. Sur cette ligne, un retard de quarante minutes arrive une fois par mois.',
   'La raison est appuyée sur un risque précis : le choix devient évident.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S2 / INSUFFICIENT
  ('f66b06b6-edce-5064-ab67-25dffaa0ef08', '783f6136-9a29-5873-b8ea-cffe6bb8cd4a', 'INSUFFICIENT',
   'La machine s''est arrêtée au bout de dix minutes. Le tambour était plein d''eau et le voyant rouge clignotait. J''ai appuyé plusieurs fois sur le bouton mais rien ne se passait.',
   'Tout est décrit, rien n''est expliqué : on ignore ce qui a causé l''arrêt.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S2 / EXPECTED
  ('82f04cfd-b3fd-5446-a929-9bfdec80b9bf', '783f6136-9a29-5873-b8ea-cffe6bb8cd4a', 'EXPECTED',
   'Elle s''est arrêtée parce que le filtre était bouché par des mouchoirs oubliés dans une poche. L''eau ne pouvait plus partir, donc le programme s''est bloqué.',
   'La cause est nommée et l''enchaînement rend l''arrêt compréhensible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S2 / EXCELLENT
  ('e934a9b8-25e0-5b56-bc73-a1b1c8630b82', '783f6136-9a29-5873-b8ea-cffe6bb8cd4a', 'EXCELLENT',
   'Elle s''est arrêtée parce que le filtre était bouché : j''avais laissé des mouchoirs en papier dans une poche. Ils se sont défaits pendant le lavage, l''eau n''a plus pu partir, et la sécurité a coupé.',
   'Chaque étape mène à la suivante : l''explication se suit du début à la fin.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S3 / INSUFFICIENT
  ('f1f10af1-3b11-5774-bc4e-7c82009e1201', '8376662f-0b1f-5f74-8892-1cf2d2bffa85', 'INSUFFICIENT',
   'Il m''a proposé un café et j''ai dit non merci. Il en a pris un pour lui et nous avons continué à parler du planning de la semaine.',
   'La scène est racontée, mais le refus reste sans explication.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S3 / EXPECTED
  ('3b5fabe9-40a1-52d6-af17-138ccb328cc7', '8376662f-0b1f-5f74-8892-1cf2d2bffa85', 'EXPECTED',
   'J''ai refusé parce que le café de l''après-midi m''empêche de dormir. Depuis un mois, je m''arrête au deuxième de la matinée et je dors beaucoup mieux.',
   'La raison est donnée et elle explique le refus sans s''étendre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S3 / EXCELLENT
  ('7e0237fc-3d09-5390-9cc2-53f38e0e521a', '8376662f-0b1f-5f74-8892-1cf2d2bffa85', 'EXCELLENT',
   'J''ai refusé parce qu''un café après quatorze heures me tient éveillé jusqu''à deux heures du matin. Je l''ai découvert en arrêtant pendant les vacances : je dormais enfin.',
   'L''explication s''appuie sur une expérience précise : le refus devient évident.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S4 / INSUFFICIENT
  ('ffff1134-3dd1-5a89-b39b-156a59b46f5a', 'b20fa551-52e7-5a90-88b7-29124a455ac4', 'INSUFFICIENT',
   'Je monte toujours à pied. Les escaliers sont à gauche en entrant et il y a quatre étages. En général j''arrive en haut en deux minutes.',
   'C''est une description de l''habitude, pas son explication.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S4 / EXPECTED
  ('ae8e7c41-0ae9-539c-a6c7-1587ce18718c', 'b20fa551-52e7-5a90-88b7-29124a455ac4', 'EXPECTED',
   'Je prends les escaliers parce que je reste assis toute la journée devant un écran. Ces quatre étages sont le seul moment où je bouge vraiment.',
   'La raison est donnée et elle rend le choix compréhensible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S4 / EXCELLENT
  ('a197b2d5-e2cb-5997-9d85-47a036830fa7', 'b20fa551-52e7-5a90-88b7-29124a455ac4', 'EXCELLENT',
   'Je prends les escaliers parce que mon poste me tient assis sept heures par jour. Mon médecin m''a conseillé de marcher un peu chaque matin, et c''est le seul moment où j''y arrive sans y penser.',
   'La raison est ancrée dans une situation concrète, sans devenir un discours.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S5 / INSUFFICIENT
  ('826940db-c5a8-5f92-ad8f-11ddcd232cb1', '4dee591b-3e43-545b-8fdb-f4d6b41a699d', 'INSUFFICIENT',
   'J''ai appelé le salon vendredi soir pour annuler mon rendez-vous du samedi. La personne au téléphone a été très aimable et m''a proposé une autre date.',
   'L''annulation est racontée, mais on ne sait pas ce qui l''a provoquée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S5 / EXPECTED
  ('3be80037-6997-58d1-a8e8-22529ecbac8a', '4dee591b-3e43-545b-8fdb-f4d6b41a699d', 'EXPECTED',
   'J''ai annulé parce que ma fille est tombée malade vendredi soir et que personne ne pouvait la garder. Je ne voulais pas la laisser seule avec de la fièvre.',
   'La cause est nommée et elle rend l''annulation compréhensible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S5 / EXCELLENT
  ('cab85f3a-177c-5713-bde3-d24c84cebf68', '4dee591b-3e43-545b-8fdb-f4d6b41a699d', 'EXCELLENT',
   'J''ai annulé parce que ma fille a eu trente-neuf de fièvre vendredi soir. Ma voisine, qui la garde d''habitude, était partie pour le week-end, et mon mari travaillait samedi matin.',
   'Les précisions écartent les autres solutions : l''annulation devient inévitable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S6 / INSUFFICIENT
  ('771b78bb-bfb8-5edf-80ec-b63e06f9325b', '6cc8f335-0e21-50a3-9d72-3883c732ba8c', 'INSUFFICIENT',
   'Le premier appartement était moins cher mais le second m''a plu tout de suite. J''ai signé le bail le lendemain et j''ai emménagé deux semaines plus tard. Il est très agréable à vivre.',
   '« Il m''a plu » ne dit pas ce qui a emporté la décision.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S6 / EXPECTED
  ('6eadd156-647e-5762-b60d-7ccd2b45c43f', '6cc8f335-0e21-50a3-9d72-3883c732ba8c', 'EXPECTED',
   'J''ai choisi le plus cher parce qu''il est à dix minutes à pied de mon travail. L''autre était à quarante minutes de bus, avec un changement. Les cent euros de plus, je les reperdais en abonnement et en fatigue.',
   'La raison est chiffrée et elle explique vraiment le surcoût accepté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S6 / EXCELLENT
  ('bc2c0605-89e2-5307-b844-7ce1f534d80b', '6cc8f335-0e21-50a3-9d72-3883c732ba8c', 'EXCELLENT',
   'J''ai choisi le plus cher parce qu''il est à dix minutes à pied de l''atelier où je commence à six heures. L''autre était à quarante minutes, avec un bus qui ne circule pas avant cinq heures et demie. Cent euros, c''est moins que trois taxis par semaine.',
   'Le surcoût est comparé à une dépense évitée : la raison tient debout toute seule.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S7 / INSUFFICIENT
  ('5abfb2f5-0496-5fcd-b908-7cc66278e658', 'beed6da5-fb54-557d-ab44-2912b0de14d9', 'INSUFFICIENT',
   'En novembre j''avais payé quatre-vingts euros et en janvier cent soixante. C''est beaucoup d''argent d''un coup, et je ne m''y attendais pas en ouvrant l''enveloppe. J''ai relu la facture deux fois pour être sûr du montant.',
   'L''écart est constaté, mais rien ne dit d''où il vient.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S7 / EXPECTED
  ('a2408908-1c2b-5671-a86b-74dac0f408f2', 'beed6da5-fb54-557d-ab44-2912b0de14d9', 'EXPECTED',
   'Elle a doublé parce que le chauffage électrique a tourné tous les jours en janvier. En novembre, il faisait encore doux et je ne l''allumais que le soir. Le mois de janvier a été très froid.',
   'La cause est nommée et le lien avec le montant est fait.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S7 / EXCELLENT
  ('e308f2a6-9ae3-5da2-9921-dd8c69ec7949', 'beed6da5-fb54-557d-ab44-2912b0de14d9', 'EXCELLENT',
   'Elle a doublé parce que janvier a été bien plus froid que novembre : le chauffage tournait du matin au soir dans les deux chambres. À cela s''ajoute une semaine de vacances scolaires, où les enfants sont restés à la maison toute la journée. Le compteur a suivi.',
   'Deux causes s''additionnent et chacune est reliée à la consommation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S8 / INSUFFICIENT
  ('005016f2-a1f4-5a5f-8f65-fde9dc01721d', '5131bfc8-9ab0-5fe1-aaf6-fd61559143af', 'INSUFFICIENT',
   'Le client parlait très fort et tout le monde nous regardait. Je suis resté derrière mon guichet sans bouger jusqu''à ce qu''il finisse. Ensuite il est parti et la file a repris.',
   'La scène est racontée ; le silence n''est jamais expliqué.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S8 / EXPECTED
  ('6f7aa5e2-b1c3-504e-951b-46d53f9f9c2e', '5131bfc8-9ab0-5fe1-aaf6-fd61559143af', 'EXPECTED',
   'Je n''ai rien répondu parce qu''il ne m''écoutait pas : chaque fois que j''ouvrais la bouche, il parlait plus fort. Répondre n''aurait servi à rien. J''ai attendu qu''il s''arrête pour lui proposer une solution.',
   'La raison est donnée et elle transforme le silence en choix.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S8 / EXCELLENT
  ('87eb50ec-4742-5f52-b574-f69538bcf1cb', '5131bfc8-9ab0-5fe1-aaf6-fd61559143af', 'EXCELLENT',
   'Je n''ai rien répondu parce qu''il coupait chacune de mes phrases : il ne m''entendait plus. Répondre devant la file l''aurait mis en colère devant témoins, et personne n''en serait sorti. J''ai attendu qu''il souffle, puis je lui ai proposé le bureau du fond.',
   'Le silence apparaît comme une décision réfléchie, pas comme une absence.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S9 / INSUFFICIENT
  ('3249312c-8753-53e7-b59d-64ee86bba87d', '1ea67799-baf5-5a15-af8c-e6dc1a61824c', 'INSUFFICIENT',
   'Mon responsable m''a proposé six heures de plus par semaine. J''ai réfléchi deux jours et je lui ai dit non. Il a compris et il a proposé ces heures à un collègue.',
   'Le refus est raconté, mais sa raison n''apparaît jamais.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S9 / EXPECTED
  ('a2d0d144-19eb-58e9-a2b0-f48821729be2', '1ea67799-baf5-5a15-af8c-e6dc1a61824c', 'EXPECTED',
   'J''ai dit non parce que je suis le seul à récupérer ma fille à l''école le soir. Six heures de plus, c''est rentrer à dix-neuf heures quatre jours par semaine. Aucune garde n''est possible à cette heure-là.',
   'La raison est concrète et elle explique pourquoi le salaire n''a pas suffi.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S9 / EXCELLENT
  ('41966783-2caf-5f5a-b32b-b0d08821229e', '1ea67799-baf5-5a15-af8c-e6dc1a61824c', 'EXCELLENT',
   'J''ai dit non parce que je récupère ma fille à seize heures trente et que personne d''autre ne le peut. Six heures de plus, c''est quatre soirs à dix-neuf heures, et le périscolaire ferme à dix-huit. L''argent aurait payé une garde que je n''ai pas trouvée.',
   'La raison est chiffrée et va jusqu''à répondre à l''objection de l''argent.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S10 / INSUFFICIENT
  ('722f3806-ed53-548e-a31e-480ad14dfdff', '0cf14ffd-5532-5132-8ef1-fa34eac3fe96', 'INSUFFICIENT',
   'Le livreur est passé mardi après-midi et il est reparti avec mon colis. J''ai reçu un message qui disait que la livraison avait échoué et qu''il fallait aller le chercher en point relais.',
   'L''échec est rapporté, mais sa cause n''est jamais donnée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S10 / EXPECTED
  ('a86c0982-2696-5730-b133-4fa07fd94f40', '0cf14ffd-5532-5132-8ef1-fa34eac3fe96', 'EXPECTED',
   'Il est reparti avec parce que l''interphone ne marche plus depuis quinze jours. Il a sonné en bas sans réponse, et mon numéro n''était pas sur l''étiquette. Il n''avait aucun moyen de me joindre.',
   'La cause est nommée et l''enchaînement rend le départ logique.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S10 / EXCELLENT
  ('88291e8e-1e9f-5cbe-ab90-e0a5a068ac2b', '0cf14ffd-5532-5132-8ef1-fa34eac3fe96', 'EXCELLENT',
   'Il est reparti avec parce que le colis demandait une signature et que personne ne pouvait lui ouvrir. L''interphone est en panne depuis quinze jours, la gardienne était en congé, et j''avais donné mon ancien numéro à la commande.',
   'Trois causes s''additionnent et ferment toutes les issues : le départ s''explique seul.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S11 / INSUFFICIENT
  ('2b46ca1c-6585-59b2-961d-de5421fd18e6', '1e998c4e-888e-5ea7-a3bf-9317c535b04d', 'INSUFFICIENT',
   'Elle est passée devant moi sans rien dire et je ne lui ai fait aucune remarque. En sortant, je lui ai dit merci et elle a eu l''air surprise. Je crois qu''elle n''a pas compris pourquoi.',
   'Le geste est raconté, la contradiction reste entière.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S11 / EXPECTED
  ('98dff7d3-a963-5698-8b7b-ca86014db5bb', '1e998c4e-888e-5ea7-a3bf-9317c535b04d', 'EXPECTED',
   'Je l''ai remerciée parce qu''elle avait gardé ma place et surveillé mon chariot pendant que je retournais chercher du pain. Elle est passée devant moi ensuite, c''est vrai, mais sans elle j''aurais tout repris depuis le début.',
   'La contradiction est levée : on comprend ce qui a motivé le merci.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S11 / EXCELLENT
  ('b0b9e80a-2b53-51b1-8c1b-2c3cf9050b84', '1e998c4e-888e-5ea7-a3bf-9317c535b04d', 'EXCELLENT',
   'Je l''ai remerciée parce que c''est elle qui avait gardé ma place dans la file pendant que je retournais chercher du pain. Elle a fini par passer devant moi, ce qui est logique : j''avais mis dix minutes. Sans elle, j''aurais recommencé toute la queue.',
   'La raison retourne complètement la scène et rend le merci évident.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S12 / INSUFFICIENT
  ('061a868a-b0e5-57d0-bafd-95d614553ac6', 'f7e6046e-8e12-5043-ba24-5f5ed7f13e0d', 'INSUFFICIENT',
   'Il m''a offert un téléphone très cher pour mon anniversaire et je le lui ai rendu deux jours après. Il n''a pas beaucoup apprécié et nous n''en avons plus reparlé depuis ce jour-là.',
   'Le refus est raconté, mais sa raison n''est jamais donnée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S12 / EXPECTED
  ('c4ad2bb6-5fc0-535e-84d4-2fa8e33ecc6f', 'f7e6046e-8e12-5043-ba24-5f5ed7f13e0d', 'EXPECTED',
   'Je le lui ai rendu parce que je sais ce qu''il gagne et ce que coûte cet appareil. Accepter aurait voulu dire qu''il se prive pendant deux mois pour moi. Le mien fonctionne encore très bien.',
   'La raison porte sur la situation, jamais sur l''intention de la personne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S12 / EXCELLENT
  ('fddcbe78-623b-529a-9a2f-b4858674ab91', 'f7e6046e-8e12-5043-ba24-5f5ed7f13e0d', 'EXCELLENT',
   'Je le lui ai rendu parce que ce téléphone représente presque un mois de son salaire et qu''il rembourse encore sa voiture. Le mien marche très bien, je n''en avais aucun besoin. Je lui ai dit que le geste m''avait touché, et que c''était justement pour ça.',
   'La raison est nette, et la dernière phrase la rend recevable sans reproche.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S13 / INSUFFICIENT
  ('eb605b05-7468-5e13-be6d-7e3fd5ec48f6', 'f776ace3-e26e-5625-9c64-9bb00ce0e1db', 'INSUFFICIENT',
   'Le match de samedi n''a pas eu lieu. Il pleuvait beaucoup ce matin-là et le terrain était très mouillé. Les enfants sont rentrés à la maison assez déçus de ne pas jouer.',
   'La cause supposée est reprise telle quelle : rien n''est expliqué.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S13 / EXPECTED
  ('6b1ae7a7-a562-50f9-b404-2cc09046a712', 'f776ace3-e26e-5625-9c64-9bb00ce0e1db', 'EXPECTED',
   'Ce n''est pas la pluie qui a fait annuler le match : le terrain est synthétique et se joue sous l''averse. C''est l''arbitre qui ne s''est pas présenté, et aucun bénévole n''avait la licence pour le remplacer.',
   'La fausse cause est écartée et la vraie est donnée nettement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S13 / EXCELLENT
  ('5323d159-dc64-57c3-88e3-27ce171bafeb', 'f776ace3-e26e-5625-9c64-9bb00ce0e1db', 'EXCELLENT',
   'Ce n''est pas la pluie qui a fait annuler le match : le terrain est synthétique et l''entraînement de la veille s''était tenu sous l''averse. L''arbitre prévu s''est blessé le vendredi soir, et le règlement interdit de jouer sans arbitre officiel. Personne au club n''a cette licence.',
   'L''écartement est argumenté, et la vraie cause s''appuie sur une règle précise.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S14 / INSUFFICIENT
  ('323f5008-3dfa-566c-bdaf-7840c39c1a40', 'fff9183b-f562-5294-9b55-1040b2a5e2c5', 'INSUFFICIENT',
   'Ma collègue a annoncé la nouvelle et j''ai ri sans pouvoir me retenir. Tout le monde s''est tourné vers moi et j''ai été très gêné pendant tout le reste de la réunion.',
   'La gêne est décrite, le rire n''est toujours pas expliqué.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S14 / EXPECTED
  ('aff8d0d4-6e7e-5d29-b663-6e7d9451b7fc', 'fff9183b-f562-5294-9b55-1040b2a5e2c5', 'EXPECTED',
   'J''ai ri parce qu''elle venait d''annoncer exactement ce que j''avais prédit la veille, mot pour mot, devant deux personnes présentes dans la salle. Ce n''était pas la nouvelle qui me faisait rire, c''était la coïncidence.',
   'La raison lève le malentendu : le rire ne portait pas sur la nouvelle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S14 / EXCELLENT
  ('ffae9245-fddd-575d-8a3d-49daf065d04e', 'fff9183b-f562-5294-9b55-1040b2a5e2c5', 'EXCELLENT',
   'J''ai ri parce que la veille, à la pause, j''avais dit à deux collègues que le budget finirait par sauter, et ils m''avaient répondu que j''exagérais. Ces deux collègues étaient assis en face de moi. Ce n''était pas la nouvelle qui me faisait rire, c''était leur tête.',
   'La scène rend le rire non seulement compréhensible, mais presque inévitable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S15 / INSUFFICIENT
  ('adef361a-0c2f-5982-9f9e-99fa8a0d6697', '558e163c-6446-5d49-81a1-4b551e7f0539', 'INSUFFICIENT',
   'Mon arrêt allait jusqu''au trente mais je suis revenu le vingt. Le médecin était d''accord et mes collègues ont été contents de me revoir au bureau ce matin-là. J''ai retrouvé mes dossiers exactement comme je les avais laissés.',
   'Le retour est raconté, mais aucune raison n''est avancée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S15 / EXPECTED
  ('ad6d22f0-3e12-5f3f-8e54-302d1b4cbb07', '558e163c-6446-5d49-81a1-4b551e7f0539', 'EXPECTED',
   'Je suis revenu plus tôt parce que mon indemnité ne couvrait que la moitié de mon salaire. Dix jours de plus, c''était le loyer de décembre en moins. Le médecin a accepté à condition que je reste assis.',
   'La raison est concrète et elle explique vraiment la décision.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9-S15 / EXCELLENT
  ('b2f46099-f4e1-5268-8301-87d4d86eaf81', '558e163c-6446-5d49-81a1-4b551e7f0539', 'EXCELLENT',
   'Je suis revenu plus tôt parce que l''indemnité ne couvrait que la moitié de mon salaire et que je paie seul le loyer. Dix jours de plus, c''était deux cents euros que je n''avais pas. Le médecin a accepté en me limitant aux tâches assises, et mon chef a déplacé mon poste.',
   'L''explication va jusqu''aux conditions du retour : la décision est entièrement éclairée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S16 / INSUFFICIENT
  ('a372fc0d-58de-596b-9c7e-42d01c64b52c', 'efe9e382-92b7-5d0d-87f1-015db7bb2658', 'INSUFFICIENT',
   'Le square a rouvert au printemps après six mois de travaux. Il y a maintenant des jeux neufs, un bac à sable et de nouveaux bancs. Les allées ont été refaites en gravier clair. Beaucoup de familles y passent le mercredi et le samedi après-midi.',
   'Tout est exact, mais c''est une description : après six phrases, on ignore toujours ce que vous en pensez.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S16 / EXPECTED
  ('3e5a0a04-7ecd-5b7e-ae84-b3e2d8c4d76d', 'efe9e382-92b7-5d0d-87f1-015db7bb2658', 'EXPECTED',
   'Ce square est une vraie réussite. Les jeux sont neufs et bien séparés selon les âges, ce qui évite que les petits se fassent bousculer. Les bancs sont assez nombreux pour que les parents s''assoient. Le seul regret, c''est le manque d''ombre en plein été.',
   'L''avis tombe dès les trois premiers mots, puis tout ce qui suit le justifie.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S16 / EXCELLENT
  ('3c68838f-5151-59d0-80c3-ca65e5fc856b', 'efe9e382-92b7-5d0d-87f1-015db7bb2658', 'EXCELLENT',
   'Ce square est une vraie réussite. Les jeux sont neufs et séparés par tranche d''âge, si bien que les petits ne se font plus bousculer comme avant. Les bancs sont assez nombreux pour que les parents s''assoient vraiment. Il manque encore de l''ombre en plein été, mais cela viendra avec les arbres.',
   'La position ouvre, chaque phrase la soutient, et la réserve finale ne l''affaiblit jamais.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S17 / INSUFFICIENT
  ('8250e400-c538-5b70-ac13-d7667fe51473', 'b8089520-9d1d-5658-80ac-d778404d6b96', 'INSUFFICIENT',
   'La nouvelle machine est plus grande que l''ancienne et elle a un écran tactile au lieu des boutons. Le cycle court dure trente minutes et le long une heure. Elle prend les pièces et la carte. Elle est installée au fond, à la place de l''ancienne.',
   'C''est une fiche technique. Le gérant demandait ce que vous en pensez, et cela n''apparaît nulle part.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S17 / EXPECTED
  ('bc256e79-8b87-5e48-a131-b5a8313dc00b', 'b8089520-9d1d-5658-80ac-d778404d6b96', 'EXPECTED',
   'Cette nouvelle machine est bien meilleure que l''ancienne. Elle lave plus grand, ce qui permet de faire une couette en une fois. Le cycle court de trente minutes est très pratique le soir. L''écran tactile est un peu lent, mais on s''y fait vite.',
   'L''avis est posé d''emblée, et les trois arguments qui suivent en découlent.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S17 / EXCELLENT
  ('7097bb09-5edb-5624-8a09-faa64e97b61c', 'b8089520-9d1d-5658-80ac-d778404d6b96', 'EXCELLENT',
   'Cette nouvelle machine est bien meilleure que l''ancienne. Elle lave assez grand pour une couette en une seule fois, ce qui m''évite deux passages. Le cycle court de trente minutes sauve les soirs pressés. L''écran tactile répond lentement au début, mais il suffit d''appuyer une seconde de plus.',
   'La position tient jusqu''au bout, et la réserve est accompagnée de sa solution au lieu d''être laissée en suspens.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S18 / INSUFFICIENT
  ('ac5ef135-523a-56fc-9569-c41fb0b66980', '37f49d41-4e87-5ddb-a4ed-e5cd87b92555', 'INSUFFICIENT',
   'Monsieur Sarr est arrivé en septembre dernier. Il sort les poubelles le lundi et le jeudi, nettoie le hall deux fois par semaine et relève les compteurs chaque trimestre. Il est présent de sept heures à midi. Il habite dans la loge du rez-de-chaussée avec sa famille.',
   'Vous listez ses tâches et ses horaires. Le conseil demandait votre avis sur son travail.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S18 / EXPECTED
  ('4561edb1-5987-5dba-a876-eb9893bfc25e', '37f49d41-4e87-5ddb-a4ed-e5cd87b92555', 'EXPECTED',
   'Monsieur Sarr fait un travail remarquable. Le hall n''a jamais été aussi propre, et il ne se contente pas du minimum : il repeint, il répare, il prévient quand une ampoule va lâcher. Il connaît tout le monde par son nom. Je souhaite vraiment qu''il reste.',
   'L''avis ouvre la réponse, les faits qui suivent le justifient, et la dernière phrase le confirme.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S18 / EXCELLENT
  ('33326bc8-5eb2-5879-8b68-4bf90723868f', '37f49d41-4e87-5ddb-a4ed-e5cd87b92555', 'EXCELLENT',
   'Monsieur Sarr fait un travail remarquable. Le hall n''a jamais été aussi propre, et il va bien au-delà de ses tâches : il a repeint la cage d''escalier de lui-même et il prévient avant qu''une ampoule ne lâche. Il connaît chaque habitant par son nom, y compris les nouveaux. Je souhaite qu''il reste.',
   'Chaque preuve est plus précise, et « y compris les nouveaux » montre l''attention plutôt que de l''affirmer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S19 / INSUFFICIENT
  ('e620a009-8246-5428-aa7a-86210ffa539f', '150bcbe3-bb0a-55c6-9c77-3f49000121f2', 'INSUFFICIENT',
   'Il y a quatre personnes à l''accueil, deux le matin et deux l''après-midi. Elles s''occupent des retours, des inscriptions et du rayon jeunesse. Une d''entre elles anime l''heure du conte le mercredi. Elles portent toutes un badge avec leur prénom.',
   'Vous décrivez l''équipe et son organisation. La question portait sur ce que vous en pensez.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S19 / EXPECTED
  ('0ce44b72-c703-5eb2-a060-e0aa883d686f', '150bcbe3-bb0a-55c6-9c77-3f49000121f2', 'EXPECTED',
   'L''équipe de la médiathèque est vraiment accueillante. On n''hésite jamais à demander, même une question idiote. Elles prennent le temps de chercher avec vous au lieu de désigner un rayon. L''animatrice du mercredi tient trente enfants sans jamais hausser le ton.',
   'L''avis ouvre, et chaque phrase suivante apporte une preuve concrète.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S19 / EXCELLENT
  ('fd17d0fc-4812-5e12-aebc-b550855e9833', '150bcbe3-bb0a-55c6-9c77-3f49000121f2', 'EXCELLENT',
   'L''équipe de la médiathèque est vraiment accueillante. On ose y poser des questions idiotes, ce qui n''est pas rien. Au lieu de désigner un rayon du doigt, elles se lèvent et cherchent avec vous. L''animatrice du mercredi tient trente enfants sans jamais hausser le ton — je ne sais pas comment elle fait.',
   '« Ce qui n''est pas rien » et la remarque finale montrent une position engagée, sans jamais quitter le groupe décrit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S20 / INSUFFICIENT
  ('2aad9caa-67d4-5d26-bb9f-777670c5f9ec', '43ba3f06-0be5-5ac4-b824-782262f558f9', 'INSUFFICIENT',
   'Le banc a été posé au printemps, contre le mur de la boulangerie. Il est en bois avec des pieds en fonte, assez long pour trois personnes. Il est orienté vers la place. Les gens s''y installent surtout le matin, entre sept et dix heures.',
   'C''est une description complète, mais la mairie demandait votre avis, et il n''apparaît pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S20 / EXPECTED
  ('131dd350-aa13-5aab-a037-deadebc455cd', '43ba3f06-0be5-5ac4-b824-782262f558f9', 'EXPECTED',
   'Ce banc est une excellente idée. Les personnes âgées qui font la queue peuvent enfin s''asseoir en attendant. Il est bien placé, à l''abri du vent et au soleil le matin. Les jours de marché, il déborde un peu sur le passage, mais cela reste supportable.',
   'L''avis est net dès le départ, et la réserve finale ne le remet pas en cause.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S20 / EXCELLENT
  ('7c5d8b24-a35f-5540-8dab-8270a6eb954d', '43ba3f06-0be5-5ac4-b824-782262f558f9', 'EXCELLENT',
   'Ce banc est une excellente idée. Les personnes âgées qui font la queue peuvent enfin s''asseoir, et j''y ai vu des voisins se parler qui ne se disaient rien avant. Il est bien placé : à l''abri du vent, au soleil le matin. Les jours de marché il gêne un peu le passage, sans plus.',
   'L''observation sur les voisins qui se parlent apporte une raison que personne n''attendait, et la position n''en bouge pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S21 / INSUFFICIENT
  ('2ad49058-86a8-57ad-a716-4e38d8728d66', 'a76001d0-59bd-5771-ad76-b75d4cda0d7e', 'INSUFFICIENT',
   'Le pain a changé depuis la reprise : la baguette tradition est meilleure, plus croustillante, et il y a maintenant du pain aux graines. Les croissants sont un peu moins bons qu''avant. Les prix ont légèrement augmenté, de cinq centimes environ.',
   'Vous jugez les produits. Votre voisin demandait votre avis sur la boulangère elle-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S21 / EXPECTED
  ('f8f6f9b1-6ebf-5d7e-9235-ece0cb8e1100', 'a76001d0-59bd-5771-ad76-b75d4cda0d7e', 'EXPECTED',
   'La nouvelle boulangère est très agréable. Elle retient les habitudes de chacun dès la deuxième visite et prépare la commande avant même qu''on parle. Elle prend le temps de discuter sans jamais faire attendre la file. Elle est un peu brusque au téléphone, mais c''est tout.',
   'L''avis porte bien sur la personne, et chaque phrase l''appuie par un comportement observé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S21 / EXCELLENT
  ('25b2ff21-abf5-5903-bf7a-39d81c8dfbcb', 'a76001d0-59bd-5771-ad76-b75d4cda0d7e', 'EXCELLENT',
   'La nouvelle boulangère est très agréable. Dès ma deuxième visite, elle savait ce que je prenais et le posait sur le comptoir avant que je parle. Elle discute sans jamais faire attendre la file, ce qui demande un vrai savoir-faire. Au téléphone elle est plus sèche, mais c''est le seul reproche.',
   '« Ce qui demande un vrai savoir-faire » transforme une observation en jugement argumenté, sans quitter la personne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S22 / INSUFFICIENT
  ('275bf205-51b3-52da-b7cb-265258194fc6', '893f5d28-938d-55a3-a82f-ae5fbf68d4ca', 'INSUFFICIENT',
   'La halle ouvre le mardi, le jeudi et le samedi de sept heures à treize heures. On y trouve trois maraîchers, deux fromagers, un poissonnier et un boucher. Il y a aussi un stand de fleurs à l''entrée. Le parking est gratuit pendant deux heures.',
   'Un inventaire complet, mais aucun avis : le futur visiteur ne sait pas si cela vaut le déplacement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S22 / EXPECTED
  ('516f9feb-d4de-59e3-977c-673f8d604522', '893f5d28-938d-55a3-a82f-ae5fbf68d4ca', 'EXPECTED',
   'Cette halle vaut vraiment le détour. Les produits sont frais et les vendeurs connaissent leur métier : on peut demander conseil sans être pris de haut. Les prix sont corrects pour de la qualité. Il y a beaucoup de monde le samedi, mieux vaut venir tôt.',
   'L''avis ouvre, puis les raisons le justifient, et le conseil final aide réellement un visiteur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S22 / EXCELLENT
  ('b958ae1b-1ffc-5bf2-b2b7-ecf52e3939b5', '893f5d28-938d-55a3-a82f-ae5fbf68d4ca', 'EXCELLENT',
   'Cette halle vaut vraiment le détour. Les produits sont frais et les vendeurs connaissent leur métier : on peut demander comment cuisiner quelque chose sans se faire regarder de travers. Les prix restent corrects pour cette qualité. Le samedi c''est bondé dès dix heures — venez le jeudi si vous pouvez.',
   '« Sans se faire regarder de travers » rend concret un jugement sur des personnes, et le conseil final est daté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S23 / INSUFFICIENT
  ('78866d06-6d4a-538f-b8c1-b0c9732a783b', '91242cf7-a35e-5e78-a060-74132025937b', 'INSUFFICIENT',
   'Tante Suzanne y tient beaucoup, c''était celui de son mari. Elle serait très touchée qu''on le prenne, et un peu blessée si on refusait. Elle nous en parle chaque fois qu''on va la voir. Il faudrait peut-être accepter, ne serait-ce que pour elle.',
   'Vous parlez de votre tante et de ses sentiments. La question portait sur le fauteuil.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S23 / EXPECTED
  ('b846831a-0545-5487-9ced-da58ef1354a9', '91242cf7-a35e-5e78-a060-74132025937b', 'EXPECTED',
   'Ce fauteuil est un très bon meuble. L''armature en chêne est parfaitement saine et l''assise n''a pas bougé, ce qui est rare pour cet âge. Le velours vert est démodé mais intact. Il suffirait d''une housse pour qu''il tienne encore vingt ans.',
   'L''avis est net, et chaque raison porte sur le meuble lui-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S23 / EXCELLENT
  ('2be4ba85-02d9-5ab8-b3d9-c58a7a4d10eb', '91242cf7-a35e-5e78-a060-74132025937b', 'EXCELLENT',
   'Ce fauteuil est un très bon meuble. L''armature en chêne est saine, sans jeu ni grincement, et l''assise n''a pas creusé — rare à cet âge. Le velours vert est démodé, mais il n''a ni accroc ni tache. Une housse suffirait, et il tiendra encore vingt ans.',
   '« Sans jeu ni grincement » et « ni accroc ni tache » remplacent les adjectifs par des vérifications, sans jamais changer de sujet.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S24 / INSUFFICIENT
  ('28f9cb43-a8dc-568a-a2f5-c1cabd708b14', '969a7465-3898-5e1e-bc07-110f4b545a78', 'INSUFFICIENT',
   'Nous sommes arrivés à huit heures et nous avons monté les tables avant l''ouverture. Ensuite nous avons servi environ cent vingt repas jusqu''à quatorze heures. Le rangement a duré une heure. Nous avons terminé plus tôt que prévu, vers quinze heures trente.',
   'C''est le récit de la journée. La responsable demandait ce que vous pensez de l''équipe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S24 / EXPECTED
  ('d2813965-888c-5c62-8baa-6b0e0e635640', '969a7465-3898-5e1e-bc07-110f4b545a78', 'EXPECTED',
   'Cette équipe du samedi est très solide. Personne n''attend qu''on lui dise quoi faire : chacun voit ce qui manque et s''en occupe. Les anciens montrent aux nouveaux sans les reprendre sèchement. Le seul point faible est qu''on manque de monde au rangement.',
   'L''avis ouvre, les preuves suivent, et la réserve porte sur le groupe et non sur l''organisation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S24 / EXCELLENT
  ('8c758e6b-fb3c-516c-a1cf-9d6c5fb51422', '969a7465-3898-5e1e-bc07-110f4b545a78', 'EXCELLENT',
   'Cette équipe du samedi est très solide. Personne n''attend les consignes : chacun voit ce qui manque et s''en occupe, ce qui fait gagner un temps considérable. Les anciens montrent aux nouveaux sans jamais les reprendre devant les autres. Il manque seulement deux ou trois bras au moment du rangement.',
   '« Sans jamais les reprendre devant les autres » est une observation fine sur la manière d''être du groupe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S25 / INSUFFICIENT
  ('54c5db0f-495f-5d27-af19-b8568a4d6c6b', 'bad9d7bc-85bf-5d4a-8035-73df0a3d874a', 'INSUFFICIENT',
   'Il y a douze emplacements devant la poste et la station est rarement vide. L''abonnement coûte trente euros à l''année. On déverrouille avec une application ou avec une carte. La station la plus proche est à quatre cents mètres, devant la gare.',
   'Vous décrivez la station et le service. La question portait sur les vélos eux-mêmes.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S25 / EXPECTED
  ('d9ac0cbf-2531-5427-ba38-5c5140cf43e9', 'bad9d7bc-85bf-5d4a-8035-73df0a3d874a', 'EXPECTED',
   'Ces vélos sont plutôt bons. Le cadre est lourd mais très stable, on ne craint rien sur les pavés. Les trois vitesses suffisent pour le quartier. Le panier avant est solide. En revanche, les selles sont souvent dures à régler et deux vélos sur douze ont les freins fatigués.',
   'L''avis ouvre, puis chaque qualité et chaque défaut porte sur le vélo lui-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S25 / EXCELLENT
  ('c3f96403-f4f9-5ca5-b3b2-3d41ace2590b', 'bad9d7bc-85bf-5d4a-8035-73df0a3d874a', 'EXCELLENT',
   'Ces vélos sont plutôt bons. Le cadre est lourd, mais cette lourdeur les rend stables sur les pavés, ce qui compte ici. Trois vitesses suffisent largement pour le quartier et le panier avant tient un cartable. Les selles se règlent mal, et sur douze vélos j''en ai trouvé deux aux freins fatigués.',
   'Le défaut du poids est retourné en qualité, et les chiffres rendent la réserve vérifiable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S26 / INSUFFICIENT
  ('d06f7cf6-ed38-586e-a2c8-6ad1bcce97ed', '4ceaf0b8-c52f-5a46-bd19-127de9cf0e9f', 'INSUFFICIENT',
   'Il faudrait surtout revoir les délais : j''ai attendu trois semaines pour un rendez-vous et quarante minutes sur place le jour même. Le système de prise de rendez-vous en ligne ne fonctionne pas toujours. C''est cela le vrai problème, pas la décoration.',
   'Vous parlez des délais et du système de rendez-vous. On vous demandait votre avis sur la salle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S26 / EXPECTED
  ('6f05c4e8-c8b4-55d4-84f3-192b2a3aea28', '4ceaf0b8-c52f-5a46-bd19-127de9cf0e9f', 'EXPECTED',
   'Cette salle est bien plus agréable qu''avant. Les chaises sont espacées, on ne se touche plus les coudes. Le coin enfants avec le tapis occupe vraiment les petits. La lumière est douce au lieu du néon blanc. Il manque juste un porte-manteau.',
   'L''avis est net, et chaque raison décrit un élément de la salle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S26 / EXCELLENT
  ('e0b87092-3c99-5ee5-ad0f-d7c8bb25823b', '4ceaf0b8-c52f-5a46-bd19-127de9cf0e9f', 'EXCELLENT',
   'Cette salle est bien plus agréable qu''avant. Les chaises sont assez espacées pour qu''on ne se touche plus les coudes, ce qui change tout quand on attend une demi-heure. Le coin tapis occupe réellement les petits. La lumière douce a remplacé le néon blanc. Il manque juste un porte-manteau.',
   '« Ce qui change tout quand on attend une demi-heure » relie la qualité à l''usage réel, sans glisser vers les délais.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S27 / INSUFFICIENT
  ('73396ded-57fb-5883-a453-a2aff0ef555d', '41ba636d-9478-5666-bdc3-0c8ce2d3c1d2', 'INSUFFICIENT',
   'Mon fils a beaucoup progressé cette année. Il joue maintenant six morceaux de mémoire et il répète presque tous les soirs sans qu''on le lui demande. Il a passé son examen de fin d''année avec une bonne note. Il veut continuer l''an prochain.',
   'Vous parlez de votre fils. L''école demandait votre avis sur l''enseignement de Monsieur Perez.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S27 / EXPECTED
  ('bacaaac4-8f9d-5085-8341-d1c59257bb12', '41ba636d-9478-5666-bdc3-0c8ce2d3c1d2', 'EXPECTED',
   'Monsieur Perez est un excellent professeur. Il adapte chaque cours à l''élève au lieu de suivre un programme fixe. Il ne se moque jamais d''une fausse note et il explique pourquoi elle arrive. Mon fils, qui n''osait pas jouer devant nous, joue maintenant au salon.',
   'L''avis porte sur le professeur, et les progrès du fils servent de preuve, à leur juste place.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S27 / EXCELLENT
  ('6e2edaec-c881-545b-8492-e733f6504d62', '41ba636d-9478-5666-bdc3-0c8ce2d3c1d2', 'EXCELLENT',
   'Monsieur Perez est un excellent professeur. Il adapte chaque cours à l''élève plutôt que de dérouler un programme. Devant une fausse note, il ne se moque jamais : il explique d''où elle vient, ce qui évite qu''elle revienne. Mon fils n''osait pas jouer devant nous ; il joue au salon maintenant.',
   '« Ce qui évite qu''elle revienne » explique la méthode, et la preuve finale reste subordonnée au jugement sur le professeur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S28 / INSUFFICIENT
  ('c9fcaf15-eea0-589b-a857-03cf02470845', 'fbb10e53-6f0f-574d-8895-78517c45c5f2', 'INSUFFICIENT',
   'Ce sont une famille avec deux enfants, le père travaille à l''hôpital et la mère est enseignante je crois. Ils sont arrivés il y a trois ans. Ils ont un chien. La grand-mère vient souvent le week-end, elle garde les petits.',
   'Vous les décrivez sans jamais donner votre avis, alors que la question le demandait explicitement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S28 / EXPECTED
  ('a4cbcf9b-3c8a-5345-880e-215f7732f9f5', 'fbb10e53-6f0f-574d-8895-78517c45c5f2', 'EXPECTED',
   'Les voisins du troisième sont vraiment agréables. Ils préviennent quand ils reçoivent du monde et ils font attention le soir, même avec deux enfants. Ils m''ont gardé mes clés pendant mes vacances. Leur chien aboie parfois le matin, mais ils le sortent tôt exprès.',
   'L''avis est net, et chaque preuve vient d''une expérience réelle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S28 / EXCELLENT
  ('060e6205-6c63-57fa-a0e2-04e512e3672b', 'fbb10e53-6f0f-574d-8895-78517c45c5f2', 'EXCELLENT',
   'Les voisins du troisième sont vraiment agréables. Ils préviennent avant de recevoir du monde, ce que personne d''autre ne fait ici, et ils marchent doucement le soir malgré deux enfants. Ils ont gardé mes clés trois semaines sans que j''aie à demander deux fois. Leur chien aboie tôt, mais brièvement.',
   '« Ce que personne d''autre ne fait ici » situe le jugement par rapport à l''immeuble, ce qui le rend beaucoup plus fort.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S29 / INSUFFICIENT
  ('a8a6678e-f5e8-5ee6-a969-c0ab9284117c', 'ff28502f-3d67-507b-8dae-c5bc2dedc8dd', 'INSUFFICIENT',
   'La salle est réservée par mail auprès du gardien, deux jours à l''avance. Elle sert aux assemblées, aux anniversaires et au club de tarot du jeudi. Il faudrait un planning affiché, parce qu''on se retrouve parfois à deux groupes en même temps.',
   'Vous parlez de la réservation et des usages. La question portait sur la table elle-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S29 / EXPECTED
  ('2731cfc6-79f0-5603-a470-70aa90bd59e4', 'ff28502f-3d67-507b-8dae-c5bc2dedc8dd', 'EXPECTED',
   'Cette table est un bon choix. Elle est assez grande pour seize personnes, et surtout elle se plie, ce que l''ancienne ne faisait pas. On peut donc libérer la salle pour les ateliers. Le plateau se raye vite, il faudra prévoir des sets.',
   'L''avis ouvre, les raisons portent sur la table, et la réserve reste concrète.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S29 / EXCELLENT
  ('191772ab-40cc-5c5d-9b4e-45740a459731', 'ff28502f-3d67-507b-8dae-c5bc2dedc8dd', 'EXCELLENT',
   'Cette table est un bon choix. Seize personnes y tiennent sans se serrer, et elle se plie en deux minutes, ce que l''ancienne ne permettait pas : la salle se libère enfin pour les ateliers. Le plateau clair se raye vite, il faudra des sets, mais cela reste un détail.',
   'Le pliage est chiffré en temps et sa conséquence est explicitée : l''avis devient démontré plutôt qu''affirmé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S30 / INSUFFICIENT
  ('775dda62-9593-5b19-9931-0165d8b37fc4', 'b0c3a515-6cac-5fab-8799-99d03caa98e8', 'INSUFFICIENT',
   'Nous sommes partis du pont Neuf vers quatorze heures avec les enfants. Nous avons marché une heure puis nous nous sommes arrêtés pique-niquer. Au retour il a commencé à pleuvoir et nous avons pressé le pas. Nous étions rentrés avant dix-sept heures.',
   'C''est le récit de votre après-midi. L''office demandait votre avis sur le chemin.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S30 / EXPECTED
  ('75868278-b863-5a6a-9c17-86b317806966', 'b0c3a515-6cac-5fab-8799-99d03caa98e8', 'EXPECTED',
   'Ce chemin est parfait pour une promenade en famille. Il est plat et large, on peut y marcher à trois de front ou pousser une poussette. Les arbres font de l''ombre presque tout du long. Il n''y a aucun banc entre les deux ponts, ce qui est dommage.',
   'L''avis ouvre, et chaque raison décrit une qualité du chemin utile au visiteur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C1-S30 / EXCELLENT
  ('8a30ad20-2708-5849-972e-9be23080bc5c', 'b0c3a515-6cac-5fab-8799-99d03caa98e8', 'EXCELLENT',
   'Ce chemin est parfait pour une promenade en famille. Plat et large, il permet de marcher à trois de front ou de pousser une poussette sans jamais se mettre en file. Les arbres ombragent presque tout le parcours. Seul manque : pas un seul banc sur les deux kilomètres.',
   '« Sans jamais se mettre en file » et la distance chiffrée donnent au lecteur de quoi décider vraiment.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S16 / INSUFFICIENT
  ('c523f966-9d3d-52b0-86bc-14923d4f4ebd', '7ad52ac2-904b-58f8-9dbd-e5f68a189899', 'INSUFFICIENT',
   'Cette cour est un bon endroit pour les enfants. L''école est très bien, avec des enseignants sérieux et une directrice à l''écoute. Les parents sont contents et les résultats sont bons. Mon fils s''y plaît beaucoup depuis la maternelle. Franchement, c''est une école où l''on se sent bien.',
   'Tout ce qui suit parle de l''école, pas de la cour : l''avis reste sans raison qui le soutienne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S16 / EXPECTED
  ('c689858f-79e2-5393-a300-467f31a80eaf', '7ad52ac2-904b-58f8-9dbd-e5f68a189899', 'EXPECTED',
   'Cette cour est bien conçue parce qu''elle sépare nettement les espaces. Les grands ont le terrain de foot d''un côté, les petits ont le préau et le bac à sable de l''autre. Du coup les plus jeunes ne se font pas bousculer pendant la récréation.',
   'La raison porte sur la cour et explique précisément pourquoi elle convient aux enfants.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S16 / EXCELLENT
  ('cb881a1b-9ff3-55a3-829b-3fbb98b959b5', '7ad52ac2-904b-58f8-9dbd-e5f68a189899', 'EXCELLENT',
   'Cette cour est bien conçue parce qu''elle sépare nettement les espaces. Le terrain de foot des grands occupe tout un côté, tandis que le préau et le bac à sable restent hors de la trajectoire des ballons. Les petits n''ont plus besoin de surveiller derrière eux pour jouer tranquilles.',
   'La raison est poussée jusqu''à son effet observable : les petits n''ont plus à surveiller derrière eux.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S17 / INSUFFICIENT
  ('7ce70741-82e3-5a12-a520-61648a786b66', '6b420d3e-935f-5177-8d47-5626e926cd45', 'INSUFFICIENT',
   'Ce four est le meilleur appareil de la cuisine. J''adore cuisiner, surtout le week-end quand j''ai le temps. Je fais souvent des gratins et des tartes pour tout le monde. C''est ma façon de me détendre après une semaine chargée.',
   'Vous parlez de votre goût pour la cuisine. Aucune raison ne porte sur le four.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S17 / EXPECTED
  ('aba4a465-d15a-569e-9879-e5ca217fbb41', '6b420d3e-935f-5177-8d47-5626e926cd45', 'EXPECTED',
   'Ce four est le meilleur appareil parce qu''il chauffe vraiment de manière régulière. Un gratin cuit pareil devant et au fond, ce qui n''arrive jamais avec les autres fours que j''ai eus. On n''a pas besoin de tourner le plat à mi-cuisson.',
   'La raison est une propriété du four, et son effet concret est donné.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S17 / EXCELLENT
  ('a83f1743-6af5-570f-96c4-ea6230c76c2c', '6b420d3e-935f-5177-8d47-5626e926cd45', 'EXCELLENT',
   'Ce four est le meilleur appareil parce qu''il chauffe de manière parfaitement régulière. Un gratin cuit pareil devant et au fond : on ne tourne pas le plat à mi-cuisson, et rien ne brûle sur le bord pendant que le centre reste cru. C''est rare, même sur des fours neufs.',
   'Le contre-exemple précis — le bord brûlé, le centre cru — donne toute sa force à la raison avancée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S18 / INSUFFICIENT
  ('b3ef0344-90a5-5fe3-8ed4-9dbf9bfb7162', 'e1a6f738-ac76-5697-9bc9-c338104158cd', 'INSUFFICIENT',
   'Ce pharmacien est remarquable. La pharmacie est ouverte jusqu''à vingt heures et même le dimanche matin, ce qui est très pratique. Elle est grande, bien rangée, et il y a rarement la queue. Le parking juste devant aide beaucoup. Et on trouve toujours une place pour se garer devant.',
   'Horaires, taille, parking : toutes ces raisons portent sur la pharmacie, aucune sur le pharmacien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S18 / EXPECTED
  ('cbc21daa-d1be-5dfc-bd48-bcffe17ab7e7', 'e1a6f738-ac76-5697-9bc9-c338104158cd', 'EXPECTED',
   'Ce pharmacien est remarquable parce qu''il prend le temps d''expliquer chaque traitement. Il ne se contente pas de tendre la boîte : il note les horaires de prise sur l''emballage et vérifie que vous avez compris. Ma mère, qui mélangeait ses comprimés, ne se trompe plus.',
   'La raison porte sur son comportement, et l''exemple final prouve son effet.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S18 / EXCELLENT
  ('4412cd48-8dfd-5af0-b3b4-71844ea08705', 'e1a6f738-ac76-5697-9bc9-c338104158cd', 'EXCELLENT',
   'Ce pharmacien est remarquable parce qu''il prend le temps d''expliquer chaque traitement. Il ne tend pas la boîte : il écrit les horaires de prise directement sur l''emballage, en gros, et fait répéter. Ma mère mélangeait ses comprimés depuis des années ; depuis qu''elle va chez lui, plus une erreur.',
   '« En gros » et « fait répéter » précisent le geste, et la preuve est datée par un avant et un après.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S19 / INSUFFICIENT
  ('0721c1ae-adfc-5433-8fd5-426b3aa81321', 'fd6b18eb-74bb-5a8d-add5-77f32e9a97e1', 'INSUFFICIENT',
   'Cette équipe travaille bien. Nos produits sont solides et tombent rarement en panne, donc il y a peu de réclamations. La garantie est de cinq ans, plus longue que chez nos concurrents. Les clients sont globalement satisfaits de la marque.',
   'Vous parlez des produits et de la garantie. Rien n''explique la qualité du travail de l''équipe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S19 / EXPECTED
  ('d70dc9ad-bd4c-5c12-abf4-1b9e67a2bc18', 'fd6b18eb-74bb-5a8d-add5-77f32e9a97e1', 'EXPECTED',
   'Cette équipe travaille bien parce qu''elle ne laisse jamais un dossier sans réponse. Chaque appel est rappelé dans la journée, même quand la solution n''est pas trouvée : ils préviennent qu''ils cherchent. Les clients n''ont donc pas à relancer trois fois.',
   'La raison porte sur une pratique du groupe, et sa conséquence pour le client est nommée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S19 / EXCELLENT
  ('9fd459c3-0c6b-58b7-a7d2-a858c015d801', 'fd6b18eb-74bb-5a8d-add5-77f32e9a97e1', 'EXCELLENT',
   'Cette équipe travaille bien parce qu''elle ne laisse jamais un dossier sans réponse. Chaque appel est rappelé le jour même, y compris quand la solution n''est pas trouvée : ils préviennent qu''ils cherchent encore. Résultat, personne ne relance trois fois, et les dossiers difficiles ne s''enterrent pas.',
   'La raison est poussée jusqu''à son effet le plus fort : les dossiers difficiles ne s''enterrent pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S20 / INSUFFICIENT
  ('08166ecf-3218-50be-a8a8-64e7f2353ace', '5b0e5849-3bc6-547d-b053-15874e408322', 'INSUFFICIENT',
   'Ce marché vaut mieux. J''aime beaucoup y aller le samedi matin, c''est devenu une habitude et j''y retrouve souvent des connaissances. C''est agréable de sortir tôt quand il fait beau. Je préfère vraiment cette ambiance-là. C''est un moment que je ne raterais pour rien, vraiment. On y passe bien une heure sans s''en rendre compte.',
   'Vous exprimez un plaisir personnel. Rien ne dit ce qui, dans ce marché, justifie la préférence.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S20 / EXPECTED
  ('a27db439-fbc7-5a7a-b70a-1301e5072055', '5b0e5849-3bc6-547d-b053-15874e408322', 'EXPECTED',
   'Ce marché vaut mieux parce qu''on parle directement à celui qui a produit. Le maraîcher dit quand il a récolté et ce qui se garde. On achète donc la bonne quantité au lieu de jeter la moitié en fin de semaine.',
   'La raison porte sur ce qui se passe dans ce marché, et son effet concret est donné.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S20 / EXCELLENT
  ('c502a27b-aad8-5422-bda6-0944409890ef', '5b0e5849-3bc6-547d-b053-15874e408322', 'EXCELLENT',
   'Ce marché vaut mieux parce qu''on parle directement à celui qui a produit. Le maraîcher dit quand il a récolté, ce qui se garde une semaine et ce qu''il faut manger dans deux jours. On achète la bonne quantité au lieu d''en jeter la moitié le vendredi soir — c''est là que l''écart se fait.',
   '« C''est là que l''écart se fait » désigne exactement ce que la raison démontre, sans partir sur un débat plus large.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S21 / INSUFFICIENT
  ('cd4f9e91-546a-5840-8028-f182f1aaf7ca', 'b7624f52-e3cc-5e71-bfe2-ebe5ab8e579f', 'INSUFFICIENT',
   'Je déconseille ce siège. L''occasion, c''est toujours risqué pour ce genre d''achat, on ne sait jamais d''où ça vient ni comment ça a été traité. Je préfère acheter neuf quand il s''agit des enfants, quitte à mettre plus cher. C''est un principe auquel je tiens depuis la naissance du premier.',
   'Vous énoncez un principe sur l''occasion en général. Rien ne concerne ce siège-là.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S21 / EXPECTED
  ('e0eed266-47c5-5e37-af3c-3d165c7cccc2', 'b7624f52-e3cc-5e71-bfe2-ebe5ab8e579f', 'EXPECTED',
   'Je déconseille ce siège parce que la sangle centrale est effilochée près de la boucle. C''est précisément l''endroit qui retient l''enfant en cas de choc. Le reste a beau être impeccable, cette pièce-là ne se remplace pas sur ce modèle.',
   'La raison est un défaut observable sur cet objet, et son importance est expliquée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S21 / EXCELLENT
  ('860e6b23-0159-52f2-9060-ecef3d887928', 'b7624f52-e3cc-5e71-bfe2-ebe5ab8e579f', 'EXCELLENT',
   'Je déconseille ce siège parce que la sangle centrale est effilochée juste au-dessus de la boucle. C''est exactement la pièce qui retient l''enfant en cas de choc, et elle travaille à chaque serrage. La coque a beau être impeccable, cette sangle ne se remplace pas sur ce modèle.',
   '« Elle travaille à chaque serrage » explique pourquoi l''usure va s''aggraver : la raison devient démonstration.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S22 / INSUFFICIENT
  ('f3ba6095-2ce0-5a2c-b35b-6266eb72a833', 'de4d2b95-dec5-5fbd-a0cb-e7c5f4a63402', 'INSUFFICIENT',
   'Cette classe est vraiment bien. La maîtresse est formidable, très organisée et patiente. Elle envoie un compte rendu chaque vendredi et elle reçoit les parents quand on le demande. Elle a beaucoup d''expérience, plus de vingt ans. Elle connaît très bien les programmes et prépare des sorties chaque trimestre.',
   'Toutes les raisons portent sur l''enseignante. La question portait sur la classe, c''est-à-dire le groupe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S22 / EXPECTED
  ('5e03f737-8815-591d-8451-8e9d4bb7f800', 'de4d2b95-dec5-5fbd-a0cb-e7c5f4a63402', 'EXPECTED',
   'Cette classe est particulièrement soudée. Les élèves s''entraident vraiment : quand l''un rate un jour, deux autres lui recopient les leçons sans qu''on demande. Aucun groupe ne s''est formé contre un autre. Ma fille, qui était isolée l''an dernier, a trouvé sa place en un mois.',
   'La raison décrit un fonctionnement du groupe, et la preuve concerne bien les élèves.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S22 / EXCELLENT
  ('4b91aeae-af09-55e2-9ab0-a25b81cb632a', 'de4d2b95-dec5-5fbd-a0cb-e7c5f4a63402', 'EXCELLENT',
   'Cette classe est particulièrement soudée. Quand un élève manque un jour, deux autres lui recopient les leçons sans qu''on ait rien demandé. Aucun petit groupe ne s''est formé contre un autre, ce qui était le problème l''an dernier. Ma fille y a trouvé sa place en un mois.',
   'Le contraste avec l''année précédente montre que la raison porte bien sur ce groupe-ci, et pas sur les enfants en général.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S23 / INSUFFICIENT
  ('3cf00f17-7f39-5c48-9d31-6524586eefe4', '3e3c8be7-3dfd-51cd-bd5c-e11b2726a213', 'INSUFFICIENT',
   'Ce pont mérite d''être conservé. Le patrimoine ancien fait l''identité d''une ville et une commune qui laisse disparaître ses vieilles pierres perd quelque chose d''irremplaçable. Nos enfants doivent pouvoir voir ce que leurs grands-parents ont connu. Une ville sans mémoire finit par ressembler à toutes les autres, et cela se voit vite.',
   'C''est un discours sur le patrimoine, qui vaudrait pour n''importe quel pont. Rien ne concerne celui-ci.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S23 / EXPECTED
  ('582761e1-98f3-5280-808a-89d8f5a18e4f', '3e3c8be7-3dfd-51cd-bd5c-e11b2726a213', 'EXPECTED',
   'Ce pont mérite d''être conservé parce qu''il reste le seul passage à pied entre les deux rives du quartier. Sans lui, il faut faire huit cents mètres jusqu''au pont routier, où il n''y a qu''un trottoir étroit. Les enfants de l''école passent par là chaque jour.',
   'La raison est propre à ce pont : sa fonction réelle et l''absence d''alternative.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S23 / EXCELLENT
  ('e7e2f8b2-a3e2-5261-9d07-cea64dbd5e3b', '3e3c8be7-3dfd-51cd-bd5c-e11b2726a213', 'EXCELLENT',
   'Ce pont mérite d''être conservé parce qu''il reste le seul passage piéton entre les deux rives du quartier. L''autre est à huit cents mètres et son unique trottoir fait quatre-vingts centimètres, contre des voitures lancées. Une quarantaine d''enfants traversent le vieux pont chaque matin.',
   'Les mesures et le nombre d''enfants transforment la raison en démonstration vérifiable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S24 / INSUFFICIENT
  ('b0e31421-cd43-59cb-ac9b-b9a5bff0e66a', '81e1cfc7-9d8f-5e88-a0f6-e4cff1cfd24d', 'INSUFFICIENT',
   'Cette perceuse ne conviendra pas. J''ai fait pas mal de travaux chez moi et je sais qu''il faut du bon matériel pour ce genre de chantier. Sans l''outil adapté on s''épuise et le résultat n''est jamais propre. Mieux vaut louer.',
   'Vous parlez de votre expérience et de principes généraux. Rien ne dit ce qui, dans cette perceuse, pose problème.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S24 / EXPECTED
  ('7e71002a-8383-5979-8f60-b1b4e7b21793', '81e1cfc7-9d8f-5e88-a0f6-e4cff1cfd24d', 'EXPECTED',
   'Cette perceuse ne conviendra pas parce qu''elle n''a pas de fonction percussion. Tes murs sont en béton, et sans percussion la mèche tourne sans avancer, même en appuyant fort. Elle est parfaite pour le bois ou le placo, mais pas pour ça.',
   'La raison est une caractéristique de l''outil, et son effet sur le projet du voisin est expliqué.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S24 / EXCELLENT
  ('4c1f641c-25bf-5cc4-9abf-c2d18389b8d4', '81e1cfc7-9d8f-5e88-a0f6-e4cff1cfd24d', 'EXCELLENT',
   'Cette perceuse ne conviendra pas parce qu''elle n''a pas de percussion. Sur tes murs en béton, la mèche tournera sans avancer, et tu finiras par forcer : c''est comme ça qu''on brûle un moteur. Pour du bois ou du placo elle est très bien, mais pas là.',
   '« C''est comme ça qu''on brûle un moteur » prolonge la raison jusqu''à la conséquence, sans changer d''objet.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S25 / INSUFFICIENT
  ('120f6a28-ddb0-5a93-b9cb-13c1b4c58316', 'df78ea32-10f0-571d-80be-23add7e3e187', 'INSUFFICIENT',
   'Je te le recommande. Son cabinet est au rez-de-chaussée, sans marche, avec un parking juste devant. Il y a rarement de l''attente et on obtient un rendez-vous en une semaine. C''est vraiment pratique pour toi. Le cabinet est neuf, bien chauffé, et la salle d''attente est agréable.',
   'Accès, attente, délais : toutes ces raisons portent sur le cabinet, aucune sur le praticien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S25 / EXPECTED
  ('c88e3326-f76a-560f-9ba7-fbc7d7c9fadf', 'df78ea32-10f0-571d-80be-23add7e3e187', 'EXPECTED',
   'Je te le recommande parce qu''il explique chaque exercice avant de le faire. Il montre à quoi sert le mouvement et ce qu''on doit sentir. On comprend donc pourquoi on répète, et on continue à la maison au lieu d''abandonner après trois séances.',
   'La raison décrit sa manière de travailler, et son effet sur le patient est nommé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S25 / EXCELLENT
  ('ef4d0117-846a-55a9-8eb2-6ff16b4e6e2f', 'df78ea32-10f0-571d-80be-23add7e3e187', 'EXCELLENT',
   'Je te le recommande parce qu''il explique chaque exercice avant de le faire : à quoi il sert, ce qu''on doit sentir, et ce qui doit alerter. On comprend pourquoi on répète, donc on continue à la maison — c''est là que la rééducation se joue, pas pendant la demi-heure de séance.',
   'La raison est menée jusqu''à ce qui compte vraiment en rééducation, sans jamais quitter le praticien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S26 / INSUFFICIENT
  ('7d0c2ea2-bb2a-5af8-b1a6-4fa4768b6fd2', 'cd2b5a48-68f7-503f-b0da-8f2a9d720874', 'INSUFFICIENT',
   'Ce local est insuffisant. Nous demandons depuis deux ans une salle plus grande et un budget pour le matériel. Nos effectifs augmentent chaque année et rien n''est fait. Il faudrait que la commune prenne enfin nos besoins au sérieux. Les autres communes du secteur font beaucoup mieux depuis longtemps.',
   'C''est une revendication. La mairie demandait un avis appuyé sur une raison portant sur le local.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S26 / EXPECTED
  ('2a3ac87d-ffd6-5337-91b1-7a0f6d7e6f48', 'cd2b5a48-68f7-503f-b0da-8f2a9d720874', 'EXPECTED',
   'Ce local est mal adapté parce qu''il n''a qu''une seule pièce. Les cours de chant et l''atelier couture ne peuvent donc jamais avoir lieu en même temps. Nous perdons la moitié des créneaux du soir, alors que la demande existe.',
   'La raison est une caractéristique du local, et sa conséquence est mesurable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S26 / EXCELLENT
  ('517b56ef-5b4d-5815-85cc-da72d971b142', 'cd2b5a48-68f7-503f-b0da-8f2a9d720874', 'EXCELLENT',
   'Ce local est mal adapté parce qu''il n''a qu''une seule pièce, sans cloison possible. Le cours de chant et l''atelier couture ne peuvent jamais se tenir ensemble : sur six créneaux du soir, trois restent inutilisables. La pièce est pourtant assez grande pour accueillir les deux.',
   'La dernière phrase montre que le problème vient de la configuration, pas de la taille : la raison est précise.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S27 / INSUFFICIENT
  ('4170e854-fd91-5cf7-9540-c1391efff539', 'e975598f-0b69-5464-a26a-91accc449cb7', 'INSUFFICIENT',
   'Ce portail est une déception. L''entreprise a mis trois semaines de plus que prévu, les ouvriers laissaient tout en désordre le soir et personne ne répondait au téléphone. Le devis a augmenté deux fois en cours de chantier. Nous avons dû relancer trois fois avant d''obtenir la facture définitive.',
   'Vous jugez l''entreprise et le chantier. La question portait sur le portail.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S27 / EXPECTED
  ('32a59bc0-8866-509a-bdbf-7475a06c16a6', 'e975598f-0b69-5464-a26a-91accc449cb7', 'EXPECTED',
   'Ce portail est une déception parce qu''il met dix-huit secondes à s''ouvrir complètement. En voiture, on attend au milieu de la rue, qui est étroite et passante. L''ancien portail manuel prenait cinq secondes, et personne ne bloquait la circulation. Nous étions plusieurs à préférer l''ancien système.',
   'La raison est une caractéristique chiffrée du portail, et sa conséquence est concrète.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S27 / EXCELLENT
  ('b94b43bb-dd0f-58e1-9424-5df5116537a3', 'e975598f-0b69-5464-a26a-91accc449cb7', 'EXCELLENT',
   'Ce portail est une déception parce qu''il met dix-huit secondes à s''ouvrir complètement. La rue est étroite et passante : on attend au milieu, feux allumés, pendant qu''une file se forme derrière. L''ancien portail manuel prenait cinq secondes, sortie de voiture comprise.',
   '« Sortie de voiture comprise » rend la comparaison honnête, et renforce la raison au lieu de l''exagérer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S28 / INSUFFICIENT
  ('238fb795-fa25-5929-bb97-6e48f58d91a3', '55eca851-ce2f-55aa-a0a1-a44468eeeea7', 'INSUFFICIENT',
   'J''ai quitté ce groupe à cause de Nathalie, qui écrit trente messages par jour et coupe tout le monde. Elle donne son avis sur tout, même quand personne ne lui demande. Franchement, elle rend les échanges impossibles. Plusieurs parents me l''ont dit aussi, ils n''osent simplement pas le lui écrire.',
   'Vous visez une personne. La question portait sur le groupe, et une attaque personnelle ne décrit pas son fonctionnement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S28 / EXPECTED
  ('c472fd7c-8768-5b3b-9af0-35b840b51c3c', '55eca851-ce2f-55aa-a0a1-a44468eeeea7', 'EXPECTED',
   'J''ai quitté ce groupe parce qu''on n''y trouve plus l''information. Les messages pratiques sur les sorties ou les fournitures sont noyés sous les discussions générales. Je remontais cinquante messages pour retrouver une date, donc j''ai fini par demander directement à l''école.',
   'La raison décrit un fonctionnement collectif, et son effet sur vous est concret.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S28 / EXCELLENT
  ('a2124fbc-a8f5-5270-aa24-450f607cc582', '55eca851-ce2f-55aa-a0a1-a44468eeeea7', 'EXCELLENT',
   'J''ai quitté ce groupe parce qu''on n''y trouve plus l''information. Une date de sortie se perd sous cinquante messages en une soirée, et personne ne récapitule. J''ai passé plus de temps à remonter le fil qu''à écrire un mail à l''école, ce qui règle tout en deux minutes.',
   'La comparaison de temps rend la raison mesurable, et rien ne vise personne en particulier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S29 / INSUFFICIENT
  ('bec5c6b5-213f-583b-ba59-8ab8d2163f51', '34b60772-db65-570c-9420-0af846821e84', 'INSUFFICIENT',
   'Cette cantine est trop chère. Le repas est passé de quatre à cinq euros sans que personne ne soit consulté, alors que les salaires n''ont pas bougé. La direction décide seule et communique après coup. C''est cette méthode que je conteste.',
   'Vous contestez une décision tarifaire et une méthode. La question portait sur la cantine elle-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S29 / EXPECTED
  ('b991acba-9971-553d-8e76-d19010f5acba', '34b60772-db65-570c-9420-0af846821e84', 'EXPECTED',
   'Cette cantine est mal conçue parce qu''elle n''a qu''une seule file d''entrée. À midi, cent quatre-vingts personnes arrivent en trente minutes et la queue sort dans le couloir. On passe vingt minutes debout sur une pause d''une heure. Le service, lui, est rapide une fois qu''on est passé.',
   'La raison est une caractéristique du lieu, et son effet est chiffré.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S29 / EXCELLENT
  ('3e60deb2-d5ad-5735-a55c-9c9cb4e1f155', '34b60772-db65-570c-9420-0af846821e84', 'EXCELLENT',
   'Cette cantine est mal conçue parce qu''elle n''a qu''une seule file d''entrée. Cent quatre-vingts personnes s''y présentent en trente minutes : la queue sort dans le couloir et on y passe vingt minutes debout sur une pause d''une heure. La salle, elle, est à moitié vide à treize heures.',
   'La salle à moitié vide prouve que le problème vient de l''entrée, pas de la capacité : la raison est démontrée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S30 / INSUFFICIENT
  ('0e6c5fb7-ad48-5a21-a6d6-af69e8d7cc2e', 'f45c6e1e-fb1d-57da-8671-f06ada14238f', 'INSUFFICIENT',
   'Ce nouvel emplacement est un mauvais choix. Les transports de cette ville sont mal pensés depuis des années, les lignes ne se croisent pas et les correspondances sont absurdes. On sent qu''aucun de ceux qui décident ne prend le tramway.',
   'Vous jugez le réseau entier. La question portait sur cet emplacement précis.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S30 / EXPECTED
  ('2341792f-8c75-5799-94f8-eb948de0c758', 'f45c6e1e-fb1d-57da-8671-f06ada14238f', 'EXPECTED',
   'Ce nouvel emplacement est un mauvais choix parce qu''il se trouve juste après le virage. Le tramway arrive sans qu''on le voie, et l''abri est trop court pour la longueur des rames. Ceux qui montent en queue attendent sous la pluie.',
   'Deux raisons propres à ce lieu, avec leur conséquence directe sur les usagers.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C2-S30 / EXCELLENT
  ('a953ef4b-8e82-5ecd-bf7d-faa055d78842', 'f45c6e1e-fb1d-57da-8671-f06ada14238f', 'EXCELLENT',
   'Ce nouvel emplacement est un mauvais choix parce qu''il tombe juste après le virage. On n''aperçoit la rame qu''à vingt mètres, ce qui laisse à peine le temps de se lever. L''abri, lui, ne couvre que la moitié du quai : ceux qui montent en queue attendent sous la pluie.',
   'Les vingt mètres et la moitié de quai chiffrent les deux raisons, qui restent toutes deux propres à cet arrêt.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S16 / INSUFFICIENT
  ('7e8ed899-6af0-5184-a6f0-1d4a907aeaf6', '8c0fab25-6ccf-57a7-8693-971884562996', 'INSUFFICIENT',
   'Cette piscine est très bien. Les vestiaires sont propres. L''eau est à la bonne température. Il y a plusieurs lignes d''eau. Les horaires sont larges. Le personnel est agréable. Le tarif est correct. La cafétéria est pratique aussi. Le parking est gratuit. Les casiers ferment bien. On y va souvent en famille le dimanche.',
   'Sept raisons sont posées et aucune n''est expliquée : c''est une liste, pas un argument développé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S16 / EXPECTED
  ('7fe63a09-6e35-5abb-99eb-138062b55c54', '8c0fab25-6ccf-57a7-8693-971884562996', 'EXPECTED',
   'Cette piscine est très bien parce qu''une ligne d''eau est réservée aux nageurs lents. On n''est donc pas doublé toutes les vingt secondes par quelqu''un de plus rapide. Résultat, on peut nager à son rythme sans s''arrêter au bout, ce qui change tout quand on débute.',
   'Une seule raison, mais menée jusqu''à son effet : réservation, conséquence, bénéfice pour le nageur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S16 / EXCELLENT
  ('ab8dbbc2-1fb9-5269-9241-755f4b125266', '8c0fab25-6ccf-57a7-8693-971884562996', 'EXCELLENT',
   'Cette piscine est très bien parce qu''une ligne d''eau est réservée aux nageurs lents. On n''y est pas doublé toutes les vingt secondes, donc on ne s''arrête plus au bout pour laisser passer. Or c''est précisément l''arrêt qui coupe la respiration et décourage : en enchaînant les longueurs, on progresse vraiment.',
   'L''enchaînement va jusqu''au bout — la cause du découragement est nommée, puis retournée en bénéfice.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S17 / INSUFFICIENT
  ('48dcc115-6252-5033-8eb9-6a28f48b144d', '54f29ca1-d4d8-52f7-b40f-f2b6ef08a86f', 'INSUFFICIENT',
   'Ce lave-linge convient bien à une colocation. Il est grand. Il a un départ différé. Il est silencieux. Il consomme peu. Il a un cycle rapide. Il est facile à utiliser. Le tambour est solide. Il a coûté un prix raisonnable.',
   'Huit qualités énumérées, aucune expliquée : rien ne dit pourquoi cela compte en colocation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S17 / EXPECTED
  ('c1e8e6bd-c1f9-5695-904c-42ced2313b19', '54f29ca1-d4d8-52f7-b40f-f2b6ef08a86f', 'EXPECTED',
   'Ce lave-linge convient bien parce qu''il a un départ différé. Chacun peut donc lancer sa machine la nuit, quand personne n''attend la salle de bains. Les lessives ne se bousculent plus le dimanche soir, et on ne trouve plus de linge mouillé oublié dans le tambour.',
   'La raison est développée jusqu''à deux effets concrets sur la vie commune.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S17 / EXCELLENT
  ('3e7fa437-b9e9-5560-8735-be90900f777c', '54f29ca1-d4d8-52f7-b40f-f2b6ef08a86f', 'EXCELLENT',
   'Ce lave-linge convient bien parce qu''il a un départ différé. Chacun programme sa machine pour la nuit, si bien que les quatre lessives de la semaine ne se bousculent plus le dimanche soir. Et comme le cycle finit au réveil, personne n''oublie son linge mouillé dans le tambour pendant deux jours.',
   'Le « si bien que » et le « comme » enchaînent deux conséquences distinctes de la même raison.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S18 / INSUFFICIENT
  ('19e985bc-1006-56f1-87db-610ccf07054c', '011a4b0e-e5a3-51f8-bb89-ec54b6180c68', 'INSUFFICIENT',
   'Je la recommande. Elle est douce. Elle est rapide. Elle a le sens du contact. Elle connaît son métier. Elle a de bons produits. Elle est ponctuelle. Elle ne fait jamais attendre. Ses tarifs sont honnêtes. Elle prend sans rendez-vous. Le salon est clair. On ressort toujours content de sa visite.',
   'Huit qualités alignées, aucune développée : on ne sait pas ce qui les prouve.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S18 / EXPECTED
  ('eac3fa59-5402-5b2d-b210-0403c6a731c1', '011a4b0e-e5a3-51f8-bb89-ec54b6180c68', 'EXPECTED',
   'Je la recommande parce qu''elle regarde vos cheveux avant de proposer quoi que ce soit. Elle touche, elle demande comment vous les coiffez le matin, combien de temps vous y passez. Elle propose donc une coupe que vous pouvez refaire seule, au lieu d''une coupe qui ne tient qu''en sortant.',
   'La raison est développée par étapes, jusqu''au bénéfice qui compte : une coupe tenable à la maison.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S18 / EXCELLENT
  ('5d90c7b0-4cbf-5136-8aec-9e9cb3e34f13', '011a4b0e-e5a3-51f8-bb89-ec54b6180c68', 'EXCELLENT',
   'Je la recommande parce qu''elle regarde vos cheveux avant de proposer quoi que ce soit. Elle les touche, demande combien de temps vous y passez le matin, si vous utilisez un sèche-cheveux. La coupe qu''elle propose tient donc chez vous, pas seulement en sortant du salon — c''est là que la plupart échouent.',
   'La dernière proposition situe l''argument par rapport à ce que font les autres, ce qui achève de le développer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S19 / INSUFFICIENT
  ('483d9345-ef8a-50e6-bd91-9ea6102086c7', '9f1c0a82-579b-5032-a005-9ada499f914f', 'INSUFFICIENT',
   'Cette équipe de nuit est excellente. Ils sont souriants. Ils parlent plusieurs langues. Ils sont discrets. Ils connaissent la ville. Ils répondent vite. Ils sont bien organisés. Ils ne dorment jamais à la réception. Ils sont très professionnels. Ils sont polis. Ils connaissent les horaires des trains. On se sent en confiance avec eux.',
   'Huit affirmations, aucune développée : le lecteur doit croire sur parole.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S19 / EXPECTED
  ('abf4cf9d-ecf6-53a5-9f78-46fa0523bcb7', '9f1c0a82-579b-5032-a005-9ada499f914f', 'EXPECTED',
   'Cette équipe de nuit est excellente parce qu''elle anticipe. Quand notre train a été annulé à minuit, ils avaient déjà noté les horaires de remplacement avant qu''on descende demander. Nous avons donc pu réserver un taxi dans la foulée, au lieu de perdre une heure à chercher.',
   'Une raison abstraite — « elle anticipe » — développée par un fait, puis par son effet mesurable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S19 / EXCELLENT
  ('ff380589-00e6-55d3-9a08-f99ff7362945', '9f1c0a82-579b-5032-a005-9ada499f914f', 'EXCELLENT',
   'Cette équipe de nuit est excellente parce qu''elle anticipe. Notre train a été annulé à minuit : quand nous sommes descendus, ils avaient déjà relevé les horaires de remplacement et le numéro d''une compagnie de taxis. Nous avons réservé dans la foulée et dormi trois heures de plus que prévu.',
   'L''effet est chiffré en heures de sommeil : la raison est développée jusqu''au bénéfice réel du client.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S20 / INSUFFICIENT
  ('c73560f5-fd56-53e9-bcb2-96f5bc1d432a', 'cad16a73-8267-5448-9903-d11a09ed4138', 'INSUFFICIENT',
   'Ce parking est mal conçu. Les places sont étroites. Les piliers gênent. L''éclairage est faible. La signalisation manque. Les rampes sont raides. L''ascenseur tombe en panne. Le paiement est compliqué. On s''y perd facilement. Les places handicapées sont mal placées. Les caméras ne couvrent pas tout. La sortie piétonne est étroite. On ne s''y sent pas très rassuré.',
   'Huit griefs alignés : aucun n''est expliqué, donc aucun ne convainc.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S20 / EXPECTED
  ('b40fe156-01b0-51fc-98d0-dfbe8779c0fd', 'cad16a73-8267-5448-9903-d11a09ed4138', 'EXPECTED',
   'Ce parking est mal conçu parce que les places bordent directement les piliers. On ne peut ouvrir la portière que d''un côté, et jamais celui du passager. Les familles doivent donc faire descendre les enfants dans l''allée de circulation, là où les voitures tournent.',
   'Un seul défaut, développé jusqu''à la situation dangereuse qu''il produit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S20 / EXCELLENT
  ('d335798f-8550-5e1f-ae24-0e8dcf37f837', 'cad16a73-8267-5448-9903-d11a09ed4138', 'EXCELLENT',
   'Ce parking est mal conçu parce que les places bordent directement les piliers. La portière ne s''ouvre que d''un côté, jamais celui du passager : les familles font donc descendre les enfants dans l''allée où les voitures tournent. Trente centimètres de plus par place auraient suffi à l''éviter.',
   'La dernière phrase montre que le défaut était évitable, ce qui achève de développer l''argument.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S21 / INSUFFICIENT
  ('e0295074-b41c-5354-91ec-41525558a452', '01c43eca-aafc-51df-8cef-ac1ec44064da', 'INSUFFICIENT',
   'Ce réfrigérateur est un mauvais choix. Il est trop petit. Il fait du bruit. Il n''a pas de congélateur. Les clayettes sont fragiles. Le joint ferme mal. Il consomme beaucoup. Il est difficile à nettoyer. On ne voit rien au fond.',
   'Huit reproches empilés, aucun développé : rien ne montre l''effet sur la vie de l''équipe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S21 / EXPECTED
  ('5da9d79d-2a91-5c07-8990-0090386f2cd1', '01c43eca-aafc-51df-8cef-ac1ec44064da', 'EXPECTED',
   'Ce réfrigérateur est un mauvais choix parce qu''il ne fait que cent litres pour quarante personnes. Les gamelles s''empilent dès dix heures et celles du dessous se renversent quand on fouille. Plusieurs collègues ont renoncé à apporter leur repas, ce qui était pourtant le but de l''achat.',
   'Le défaut est chiffré, développé jusqu''au comportement qu''il provoque, puis relié à l''intention de départ.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S21 / EXCELLENT
  ('e57b07c1-da61-5efd-9935-37027b85f20c', '01c43eca-aafc-51df-8cef-ac1ec44064da', 'EXCELLENT',
   'Ce réfrigérateur est un mauvais choix parce qu''il ne fait que cent litres pour quarante personnes. Dès dix heures les gamelles s''empilent, et celles du dessous se renversent dès qu''on fouille. Quatre collègues ont renoncé à apporter leur repas — exactement ce que l''achat devait encourager.',
   'Le retournement final — l''achat produit l''inverse de son but — est le point où l''argument est pleinement développé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S22 / INSUFFICIENT
  ('4c6b56e2-66d4-5704-9c55-177eafe07aff', '5c753bd2-0a55-5d22-818e-19f7a623b732', 'INSUFFICIENT',
   'Ce remplaçant a fait du bon travail. Ma fille a eu quinze au dernier contrôle, alors qu''elle avait dix avant. Elle a aussi eu seize en expression écrite. Elle est passée de la vingtième à la sixième place de la classe.',
   'Vous donnez des résultats. Rien n''explique ce que le professeur a fait pour les obtenir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S22 / EXPECTED
  ('fc9dbea6-36f3-5cd9-803b-a01c62f3cf98', '5c753bd2-0a55-5d22-818e-19f7a623b732', 'EXPECTED',
   'Ce remplaçant a fait du bon travail parce qu''il corrige devant la classe. Il projette une copie anonyme et montre où le raisonnement se perd, phrase par phrase. Les élèves voient donc leur propre erreur dans celle d''un autre, et ils la reconnaissent la fois suivante.',
   'La méthode est décrite, puis expliquée, puis reliée à son effet sur l''apprentissage.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S22 / EXCELLENT
  ('bd873f9d-79a0-592f-85c2-0d1a97c8a575', '5c753bd2-0a55-5d22-818e-19f7a623b732', 'EXCELLENT',
   'Ce remplaçant a fait du bon travail parce qu''il corrige devant la classe. Il projette une copie anonyme et montre, phrase par phrase, où le raisonnement se perd. Les élèves reconnaissent leur propre erreur dans celle d''un autre, sans être exposés eux-mêmes — c''est ce qui leur permet de la regarder en face.',
   'L''argument est développé jusqu''à la raison psychologique qui le rend efficace : l''anonymat permet de regarder l''erreur.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S23 / INSUFFICIENT
  ('47140e09-5da9-5a81-8add-5a4024bc2892', '1594cf55-e96b-56e7-b109-d60669f9c14b', 'INSUFFICIENT',
   'Cette association est très utile. Elle organise la fête de quartier, un vide-grenier, des cours de soutien, un atelier informatique, une collecte de jouets, des sorties pour les anciens et un tournoi de pétanque. Elle tient aussi la buvette du stade.',
   'C''est un catalogue d''activités. Rien n''explique pourquoi l''association fonctionne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S23 / EXPECTED
  ('5cea48a8-6535-5f48-a10f-401775b6913f', '1594cf55-e96b-56e7-b109-d60669f9c14b', 'EXPECTED',
   'Cette association est très utile parce qu''elle confie une responsabilité précise à chaque bénévole. Personne n''est là « pour aider » : untel tient la caisse, untel gère les clés. Les gens reviennent donc l''année suivante, alors que la plupart des associations perdent leurs bénévoles après un an.',
   'Une seule raison, développée jusqu''à l''effet qui compte : la fidélité des bénévoles.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S23 / EXCELLENT
  ('24b6a78e-c52e-59f8-8413-14682193cd80', '1594cf55-e96b-56e7-b109-d60669f9c14b', 'EXCELLENT',
   'Cette association est très utile parce qu''elle confie une responsabilité précise à chaque bénévole. Personne n''est là « pour aider » : untel tient la caisse, untel garde les clés. On sait donc ce qu''on vient faire, et on se sent attendu — c''est exactement ce qui manque ailleurs, où les volontaires s''épuisent en un an.',
   '« On se sent attendu » nomme le ressort humain de l''argument : c''est le développement le plus fort possible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S24 / INSUFFICIENT
  ('cea38521-6b6a-598b-9671-b718013db4fd', '90288940-9a57-5ce9-ae10-97f3dd115463', 'INSUFFICIENT',
   'Ce jardin est une bonne chose. Il y a douze parcelles. Il y a un composteur. Il y a un point d''eau. Il y a un cabanon à outils. Il y a des tomates, des courgettes et des herbes. Il y a aussi deux bancs.',
   'Un inventaire du jardin, sans un mot sur ce qui le rend bon.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S24 / EXPECTED
  ('e93f187f-9cf0-5da8-9b8b-1aeec20c49a5', '90288940-9a57-5ce9-ae10-97f3dd115463', 'EXPECTED',
   'Ce jardin est une bonne chose parce que les parcelles n''ont pas de clôture entre elles. On voit donc ce que fait le voisin, on demande pourquoi ses tomates tiennent mieux. Des gens qui se croisaient depuis dix ans sans se parler échangent maintenant des plants.',
   'Une caractéristique du lieu développée jusqu''à son effet social, qui est le vrai sujet.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S24 / EXCELLENT
  ('18ffe51c-c85d-55e9-af36-3af35fd67cc7', '90288940-9a57-5ce9-ae10-97f3dd115463', 'EXCELLENT',
   'Ce jardin est une bonne chose parce que les parcelles n''ont aucune clôture entre elles. On voit ce que fait le voisin, donc on lui demande pourquoi ses tomates tiennent mieux que les nôtres. Des gens qui se croisaient depuis dix ans sans un mot s''échangent des plants — et cela ne se serait pas produit derrière un grillage.',
   'La dernière proposition montre que l''effet dépend bien de la caractéristique nommée : l''argument boucle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S25 / INSUFFICIENT
  ('ea0a7337-3034-5473-83be-376844df46fc', '31884a6e-5527-5faf-8e95-5fa0136c2417', 'INSUFFICIENT',
   'Cet abri est mal fait. Il est trop petit. Il n''est pas couvert partout. Les arceaux sont trop serrés. Le sol est en gravier. La porte ferme mal. Il n''y a pas d''éclairage. Il est loin de l''entrée. Personne ne s''en sert.',
   'Neuf griefs, aucun expliqué : le conseil ne saura pas lequel corriger en premier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S25 / EXPECTED
  ('a5cbd658-a7f8-5842-b009-af0ea123a0e5', '31884a6e-5527-5faf-8e95-5fa0136c2417', 'EXPECTED',
   'Cet abri est mal fait parce que les arceaux sont espacés de quarante centimètres. Deux vélos voisins se touchent, et il faut soulever le sien pour le sortir. Les habitants préfèrent donc laisser leur vélo dans le hall, ce que l''abri devait justement éviter.',
   'Un défaut chiffré, développé jusqu''au comportement qu''il produit et à l''échec de l''objectif.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S25 / EXCELLENT
  ('ec64d987-fc04-5362-a7b2-4b883978bda6', '31884a6e-5527-5faf-8e95-5fa0136c2417', 'EXCELLENT',
   'Cet abri est mal fait parce que les arceaux ne sont espacés que de quarante centimètres. Les guidons se chevauchent et il faut soulever son vélo pour le dégager — impossible avec un vélo chargé. Les habitants les laissent donc dans le hall, exactement ce que l''abri devait supprimer.',
   '« Impossible avec un vélo chargé » montre pour qui le défaut est rédhibitoire : le développement est complet.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S26 / INSUFFICIENT
  ('a307e16c-a495-510a-b100-f491b14f6c16', '38b825d4-797c-5ad6-9870-55fd3d90ca08', 'INSUFFICIENT',
   'Cette bibliothécaire est formidable. Elle est patiente. Elle aime les enfants. Elle lit beaucoup. Elle connaît tous les albums. Elle a de la voix. Elle est créative. Elle prépare bien ses animations. Elle sourit toujours. Elle range bien les rayons. Elle décore la salle à chaque saison. Les enfants la reconnaissent dans la rue.',
   'Huit qualités affirmées, aucune démontrée : rien n''explique son effet sur les enfants.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S26 / EXPECTED
  ('46bfd0e6-0e49-516e-a14a-66ed24ec6f02', '38b825d4-797c-5ad6-9870-55fd3d90ca08', 'EXPECTED',
   'Cette bibliothécaire est formidable parce qu''elle demande à l''enfant ce qu''il a aimé dans son dernier livre avant d''en proposer un autre. Elle ne part pas de l''âge mais du goût. Mon fils, qui refusait de lire, a fini par réclamer la suite d''une série.',
   'La méthode est décrite, opposée à la pratique habituelle, puis prouvée par un effet.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S26 / EXCELLENT
  ('c9deb9c0-8fd3-5d99-b274-ca39b0484d3e', '38b825d4-797c-5ad6-9870-55fd3d90ca08', 'EXCELLENT',
   'Cette bibliothécaire est formidable parce qu''elle demande à l''enfant ce qu''il a aimé avant de proposer autre chose. Elle part du goût, pas de l''âge — c''est pour cela qu''elle donne parfois un album à un grand sans que cela vexe personne. Mon fils, qui refusait de lire, réclame la suite d''une série.',
   'L''exemple de l''album donné à un grand montre la conséquence la moins évidente de la méthode.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S27 / INSUFFICIENT
  ('0544098e-eda3-51a3-9720-f6b8cc5d06a8', '8bff745f-ff08-5648-ae99-28fdbb820166', 'INSUFFICIENT',
   'Ce groupe est bien organisé. Il y a un chef de file. Il y a un serre-file. Les parcours sont préparés. Les horaires sont respectés. Le covoiturage est prévu. Le niveau est annoncé. Les pauses sont régulières. Il y a une trousse de secours.',
   'Huit éléments d''organisation listés, aucun expliqué : on ne sait pas ce qu''ils produisent.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S27 / EXPECTED
  ('0d89966b-8475-5f1e-9309-d71627e2846d', '8bff745f-ff08-5648-ae99-28fdbb820166', 'EXPECTED',
   'Ce groupe est bien organisé parce qu''un marcheur ferme toujours la file. Personne ne se retrouve seul derrière, même le plus lent. Les débutants n''ont donc pas à forcer pour rester dans le groupe, et ils ne s''épuisent pas dès la première montée.',
   'Une règle, son effet immédiat, puis son effet sur les plus fragiles du groupe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S27 / EXCELLENT
  ('316f7851-2e1a-5a7a-a86a-fa17211ce87d', '8bff745f-ff08-5648-ae99-28fdbb820166', 'EXCELLENT',
   'Ce groupe est bien organisé parce qu''un marcheur ferme toujours la file. Personne ne reste seul derrière, même le plus lent, qui n''a donc pas à forcer pour rattraper. C''est ce qui évite l''épuisement dès la première montée — et c''est aussi pour cela que les débutants reviennent une deuxième fois.',
   'L''argument est mené jusqu''à ce qui intéresse vraiment quelqu''un qui hésite : est-ce qu''on y revient.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S28 / INSUFFICIENT
  ('f06fcd93-dd1e-51c9-aeaf-8146adf7cb1f', '9a3aa9a9-f48c-5d2b-adac-04e0fb6d7f40', 'INSUFFICIENT',
   'Cette gare routière est désagréable. Il n''y a pas assez de bancs. Les toilettes sont payantes. Il fait froid. Les quais sont mal indiqués. Le café est cher. Le sol est sale. Les annonces sont incompréhensibles. Il n''y a pas de wifi.',
   'Huit reproches alignés : aucun n''est développé, donc aucun ne pèse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S28 / EXPECTED
  ('b9d1f8f0-1b9f-5ac2-aacf-49d091be7852', '9a3aa9a9-f48c-5d2b-adac-04e0fb6d7f40', 'EXPECTED',
   'Cette gare routière est désagréable parce que les quais ne sont annoncés qu''à cinq minutes du départ. Les voyageurs restent donc debout au milieu du hall, valise à la main, à surveiller l''écran. Avec une correspondance serrée, on n''ose même pas s''asseoir.',
   'Un défaut, son effet direct, puis son effet sur les voyageurs les plus contraints.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S28 / EXCELLENT
  ('3b5987da-dba9-5f00-9a33-ff1f4050ecc1', '9a3aa9a9-f48c-5d2b-adac-04e0fb6d7f40', 'EXCELLENT',
   'Cette gare routière est désagréable parce que les quais ne s''affichent que cinq minutes avant le départ. Tout le monde reste debout au centre du hall, valise à la main, les yeux sur l''écran. Ceux qui ont une correspondance n''osent pas s''asseoir, et les bancs restent vides pendant que le hall est bondé.',
   'L''image finale — bancs vides et hall bondé — prouve l''argument mieux qu''une affirmation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S29 / INSUFFICIENT
  ('39181224-48d9-5649-91c0-4efe9cdfb10d', '05a8daf6-ef56-5941-b460-b45c6358c857', 'INSUFFICIENT',
   'Ce tableau est utile. Il est grand. Il affiche des vidéos. On peut écrire dessus. On peut enregistrer. Il se connecte à internet. Il remplace le vidéoprojecteur. Il est tactile. Les élèves aiment bien s''en servir. Il est fixé au mur. Il a une télécommande. Il a remplacé l''ancien tableau noir de la classe.',
   'Neuf fonctions listées : rien n''explique ce que le tableau change pour les élèves.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S29 / EXPECTED
  ('76163544-8b10-5da2-8b6b-e37909ce42c4', '05a8daf6-ef56-5941-b460-b45c6358c857', 'EXPECTED',
   'Ce tableau est utile parce qu''on peut revenir en arrière sur ce qui a été écrit. Quand un élève décroche, la maîtresse rappelle l''étape précédente sans tout réécrire. Les plus lents ne perdent donc plus le fil au milieu d''une démonstration.',
   'Une fonction, son usage réel en classe, puis son effet sur les élèves concernés.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S29 / EXCELLENT
  ('c0d23c22-3d20-5455-a5fe-8b9f0d0e30e0', '05a8daf6-ef56-5941-b460-b45c6358c857', 'EXCELLENT',
   'Ce tableau est utile parce qu''on peut revenir sur ce qui a été effacé. Quand un élève décroche, la maîtresse réaffiche l''étape précédente en deux secondes, sans tout réécrire ni rompre le rythme. Les plus lents rattrapent au lieu d''abandonner — c''est là qu''un cours se perd ou se sauve.',
   '« Sans rompre le rythme » ajoute la raison pour laquelle cela fonctionne, ce qui achève le développement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S30 / INSUFFICIENT
  ('245aad40-29cf-5c10-91b7-668e20d57dd7', '4304cc2d-0ca3-537f-98ac-70ec7534ee9e', 'INSUFFICIENT',
   'On peut compter sur lui. Il est sérieux. Il est honnête. Il est présent. Il est discret. Il est rigoureux. Il n''oublie jamais rien. Il est disponible. Il rend service facilement. Il est ponctuel. Il est poli. Il est là depuis longtemps. Il rend service à plusieurs personnes de l''immeuble, pas seulement à moi.',
   'Huit qualités affirmées : rien ne permet à votre amie de vérifier ou de se décider.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S30 / EXPECTED
  ('1e15bba2-6b76-5739-942f-e1afab8689e2', '4304cc2d-0ca3-537f-98ac-70ec7534ee9e', 'EXPECTED',
   'On peut compter sur lui parce qu''il écrit tout. Quand il garde les plantes, il note le jour et la quantité d''eau sur un carnet posé à côté. Au retour, on sait exactement ce qui a été fait, et on voit tout de suite laquelle a eu trop ou pas assez.',
   'Une habitude concrète, développée jusqu''à ce qu''elle permet de vérifier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C3-S30 / EXCELLENT
  ('ea5a104e-c2ee-5910-b984-98745fe08560', '4304cc2d-0ca3-537f-98ac-70ec7534ee9e', 'EXCELLENT',
   'On peut compter sur lui parce qu''il écrit tout. En gardant mes plantes, il a noté le jour et la quantité d''eau sur un carnet laissé sur la table. Au retour, j''ai su lesquelles avaient trop bu — et surtout, il l''avait écrit lui-même, sans que je le lui demande.',
   '« Sans que je le lui demande » est ce qui transforme une habitude en preuve de fiabilité.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S16 / INSUFFICIENT
  ('2fd566ad-fa43-5c86-9a37-dcec399bda01', '80c4adc9-46ce-5d81-8269-102a1cf557e9', 'INSUFFICIENT',
   'Ce café compte vraiment ici. Un café de quartier est toujours un lieu de rencontre, un endroit où les habitants se retrouvent et où le lien social se fabrique naturellement. Sans ces commerces, les quartiers deviennent des dortoirs et les gens ne se parlent plus du tout.',
   'C''est une vérité générale sur les cafés. Rien ne s''est passé, nulle part, et ce café-ci n''apparaît jamais.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S16 / EXPECTED
  ('85794038-6435-5bc4-be92-79968e44bb55', '80c4adc9-46ce-5d81-8269-102a1cf557e9', 'EXPECTED',
   'Ce café compte vraiment ici. Un jour de janvier, ma voisine de quatre-vingts ans est tombée devant l''entrée. Le patron est sorti, l''a installée à l''intérieur et a appelé sa fille, dont il avait le numéro. Elle est restée au chaud une heure en attendant.',
   'Un fait daté, situé, avec des personnes réelles : l''exemple illustre l''avis au lieu de le répéter.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S16 / EXCELLENT
  ('8cebc93e-b89b-5c4e-868e-6039378bb70f', '80c4adc9-46ce-5d81-8269-102a1cf557e9', 'EXCELLENT',
   'Ce café compte vraiment ici. Un matin de janvier, ma voisine de quatre-vingts ans est tombée sur le trottoir devant l''entrée. Le patron est sorti sans son manteau, l''a installée près du radiateur et a appelé sa fille — il avait son numéro dans un carnet derrière le comptoir. Elle a attendu une heure au chaud.',
   'Le carnet derrière le comptoir est le détail qui prouve l''argument : ce café connaît ses habitués.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S17 / INSUFFICIENT
  ('01a2c90b-ed84-5902-8ec6-bc10a13b2368', 'b0ca0390-85f6-5e3b-b816-a718658a0d1a', 'INSUFFICIENT',
   'Ce robot m''a vraiment changé la vie. Il fait gagner énormément de temps sur la préparation, il simplifie les recettes compliquées et il évite de salir dix ustensiles. C''est un appareil vraiment utile au quotidien pour une famille qui cuisine régulièrement.',
   'Trois affirmations générales sur l''appareil. Aucune scène, aucun jour, aucun plat.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S17 / EXPECTED
  ('3cbf767e-d192-54eb-9880-ee32fa9ff4e1', 'b0ca0390-85f6-5e3b-b816-a718658a0d1a', 'EXPECTED',
   'Ce robot m''a vraiment changé la vie. Mardi dernier, je suis rentrée à dix-neuf heures quinze avec les enfants affamés. J''ai mis les légumes et le riz dedans, lancé le programme, et le repas était prêt à dix-neuf heures cinquante pendant que je faisais les devoirs.',
   'Un jour, une heure, une situation : l''exemple montre le bénéfice au lieu de l''annoncer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S17 / EXCELLENT
  ('e005c1d2-ca3c-5f29-8833-f5b2e3b7c414', 'b0ca0390-85f6-5e3b-b816-a718658a0d1a', 'EXCELLENT',
   'Ce robot m''a vraiment changé la vie. Mardi, je suis rentrée à dix-neuf heures quinze avec deux enfants affamés et rien de prêt. J''ai jeté les légumes et le riz dedans, lancé le programme, et je me suis assise aux devoirs. À vingt heures on mangeait — avant, ce soir-là, c''était pâtes.',
   '« Avant, ce soir-là, c''était pâtes » ajoute le point de comparaison qui donne sa mesure à l''exemple.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S18 / INSUFFICIENT
  ('7792b4be-58c7-585a-9c74-51407001d3b8', '6f3d129d-9c7b-5d79-9f2e-d123c192f5ad', 'INSUFFICIENT',
   'Notre facteur est remarquable. Il est toujours ponctuel, très aimable avec tout le monde et il connaît parfaitement sa tournée. Il fait attention aux colis et il prend le temps de saluer les gens. C''est vraiment un professionnel comme on en voit peu.',
   'Quatre qualités affirmées, aucune scène. La poste ne saura pas ce qui les fonde.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S18 / EXPECTED
  ('a716c1c2-6699-5b96-95bb-a82315c4529b', '6f3d129d-9c7b-5d79-9f2e-d123c192f5ad', 'EXPECTED',
   'Notre facteur est remarquable. La semaine dernière, il a remarqué que le courrier de Madame Roux, au troisième, s''accumulait depuis quatre jours. Il a sonné chez la gardienne pour le signaler. Elle est montée : Madame Roux était tombée et ne pouvait plus se relever.',
   'Une situation datée, avec des personnes nommées et une conséquence réelle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S18 / EXCELLENT
  ('b53c3c84-296c-5d52-ad62-969f6d7a3a9e', '6f3d129d-9c7b-5d79-9f2e-d123c192f5ad', 'EXCELLENT',
   'Notre facteur est remarquable. La semaine dernière, il a vu que le courrier de Madame Roux, au troisième, s''accumulait depuis quatre jours alors qu''elle le relève chaque matin. Il a sonné chez la gardienne au lieu de continuer sa tournée. Elle était tombée la veille et ne pouvait plus se relever.',
   '« Alors qu''elle le relève chaque matin » explique comment il a su : l''exemple montre l''attention, pas seulement le geste.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S19 / INSUFFICIENT
  ('01cf509e-aa79-532c-a633-68f300e3084d', 'afc77bf9-3c8e-57f4-bb88-79c3ed6a8d8b', 'INSUFFICIENT',
   'Cette équipe a été remarquable. Le personnel hospitalier fait un travail très difficile dans des conditions compliquées, avec des moyens insuffisants et des horaires épuisants. Il faut vraiment saluer leur engagement, car sans eux le système ne tiendrait pas. On leur demande beaucoup et ils tiennent quand même, ce qui force le respect.',
   'Un hommage général au personnel hospitalier. Rien de ce qui s''est passé cette nuit-là n''apparaît.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S19 / EXPECTED
  ('4b37394b-b0a1-524a-8992-63b84d85248a', 'afc77bf9-3c8e-57f4-bb88-79c3ed6a8d8b', 'EXPECTED',
   'Cette équipe a été remarquable. Vers deux heures du matin, une infirmière est revenue me voir alors que je n''avais rien demandé. Elle a remarqué que je grelottais et m''a apporté une couverture chauffée. Elle est repassée deux fois avant que le médecin arrive.',
   'Une heure, un geste observé, une répétition : l''exemple montre l''attention de l''équipe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S19 / EXCELLENT
  ('2b58acf0-25d4-5207-88cd-65da564a0d67', 'afc77bf9-3c8e-57f4-bb88-79c3ed6a8d8b', 'EXCELLENT',
   'Cette équipe a été remarquable. Vers deux heures du matin, une infirmière est revenue alors que je n''avais rien demandé : elle avait vu que je grelottais en passant dans le couloir. Elle m''a apporté une couverture chauffée, puis est repassée deux fois avant l''arrivée du médecin, sans que je sonne.',
   '« En passant dans le couloir » et « sans que je sonne » montrent que l''attention était spontanée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S20 / INSUFFICIENT
  ('1826fb88-8462-5aab-b1df-8152e843992b', 'bf9a2b40-0332-5c1d-823f-6f05cc5503b3', 'INSUFFICIENT',
   'Cette salle est vraiment différente. Les grandes chaînes cherchent le volume et traitent les gens comme des numéros, alors qu''une petite structure privilégie la relation et l''accompagnement. C''est une question de modèle économique, et cela se ressent partout. On le sent dès qu''on pousse la porte, et cela n''a rien à voir avec le prix de l''abonnement.',
   'Une analyse des modèles économiques. Aucune scène ne se passe dans cette salle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S20 / EXPECTED
  ('4fc02889-0c8d-5124-82c9-e78e532b3af1', 'bf9a2b40-0332-5c1d-823f-6f05cc5503b3', 'EXPECTED',
   'Cette salle est vraiment différente. Le mois dernier, je n''étais pas venue depuis trois semaines à cause d''une grippe. En entrant, le gérant m''a demandé si j''allais mieux et il a baissé les charges de ma première séance sans que je demande quoi que ce soit.',
   'Une absence, une reprise, un geste précis : l''exemple porte sur cette salle et sur personne d''autre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S20 / EXCELLENT
  ('9dcc6535-8744-5a33-81ad-0ce5582c37b3', 'bf9a2b40-0332-5c1d-823f-6f05cc5503b3', 'EXCELLENT',
   'Cette salle est vraiment différente. Le mois dernier, après trois semaines d''absence pour une grippe, le gérant m''a arrêtée à l''entrée pour demander si j''allais mieux. Il a lui-même allégé les charges de ma première séance et m''a dit de revenir le lendemain plutôt que de forcer. Je n''avais rien demandé.',
   'Le conseil de revenir le lendemain ajoute une seconde preuve dans la même scène, sans en changer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S21 / INSUFFICIENT
  ('49b46f0d-f4ca-5e49-9f94-d1be4148d778', 'cb4fac48-803e-557e-b4ce-cdf4c72b1dec', 'INSUFFICIENT',
   'Ce manteau est excellent. Les vêtements d''occasion sont souvent de meilleure qualité que le neuf bon marché, parce qu''ils ont été fabriqués à une époque où l''on soignait les finitions. Acheter d''occasion, c''est aussi un geste utile pour la planète.',
   'Deux idées générales sur la seconde main. Ce manteau précis n''est jamais mis à l''épreuve.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S21 / EXPECTED
  ('5b3a4bfe-a2f3-5601-b1cf-9cee439ba246', 'cb4fac48-803e-557e-b4ce-cdf4c72b1dec', 'EXPECTED',
   'Ce manteau est excellent. En février, je suis restée une heure sur le quai de la gare de Lille sous une pluie battante, avec du vent. Je suis rentrée sèche, y compris les épaules. Mon ancien manteau, acheté neuf, prenait l''eau au bout de dix minutes.',
   'Une épreuve datée, située, avec un point de comparaison : l''exemple prouve la qualité du vêtement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S21 / EXCELLENT
  ('db66bcbd-44ef-5b07-9c68-eb8dc4166faa', 'cb4fac48-803e-557e-b4ce-cdf4c72b1dec', 'EXCELLENT',
   'Ce manteau est excellent. En février, j''ai attendu une heure sur le quai de la gare de Lille sous une pluie battante et du vent de côté. Je suis rentrée parfaitement sèche, épaules comprises. Mon précédent, acheté neuf soixante euros, prenait l''eau au bout de dix minutes dans les mêmes conditions.',
   '« Dans les mêmes conditions » rend la comparaison rigoureuse au lieu d''être une impression.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S22 / INSUFFICIENT
  ('fe615c12-da0f-5b55-96c6-c96fa78a608f', '6375fa17-1961-55ce-aeb5-733de691707b', 'INSUFFICIENT',
   'Madame Colin m''a beaucoup aidé. Un bon accompagnement fait toute la différence dans une recherche d''emploi : on se sent moins seul, on garde le rythme et on évite de se décourager. C''est ce qui manque souvent aux personnes qui cherchent longtemps.',
   'Un discours sur l''accompagnement en général. Rien de ce que Madame Colin a fait n''apparaît.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S22 / EXPECTED
  ('e057f211-2b7d-53c8-a8d7-32f71b03dddf', '6375fa17-1961-55ce-aeb5-733de691707b', 'EXPECTED',
   'Madame Colin m''a beaucoup aidé. Au troisième rendez-vous, elle a relu mon CV ligne par ligne et a remarqué que je ne mentionnais nulle part mes six ans comme chef d''équipe. Elle m''a fait réécrire cette partie. J''ai eu trois convocations dans le mois qui a suivi.',
   'Un rendez-vous précis, une action précise, un résultat mesurable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S22 / EXCELLENT
  ('0232e905-e182-54cb-9dca-ae5b11c3e53d', '6375fa17-1961-55ce-aeb5-733de691707b', 'EXCELLENT',
   'Madame Colin m''a beaucoup aidé. Au troisième rendez-vous, elle a relu mon CV ligne par ligne et s''est arrêtée : mes six ans comme chef d''équipe n''y figuraient nulle part, je les trouvais évidents. Elle m''a fait réécrire toute la section. Trois convocations dans le mois qui a suivi.',
   '« Je les trouvais évidents » explique pourquoi l''omission existait : l''exemple montre ce qu''elle a vu et que l''on ne voyait pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S23 / INSUFFICIENT
  ('2188a9f6-ddd5-5237-9e6f-36e02c4c3841', '1957f5a2-91cc-51e6-b4cf-8d197101a7b4', 'INSUFFICIENT',
   'Ce groupe fonctionne vraiment. Parler à d''autres personnes qui vivent la même chose fait beaucoup de bien, on se sent compris et on relativise. C''est important de ne pas rester seul avec ses difficultés, tout le monde devrait avoir accès à ce genre d''espace.',
   'Des généralités sur les groupes de parole, et même une préconisation universelle. Aucun moment vécu.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S23 / EXPECTED
  ('c7228c5a-b154-5513-a6a6-35a919ff0183', '1957f5a2-91cc-51e6-b4cf-8d197101a7b4', 'EXPECTED',
   'Ce groupe fonctionne vraiment. Un jeudi, quelqu''un a fondu en larmes au milieu d''une phrase. Personne n''a rien dit et personne n''est intervenu. On a attendu. Cinq minutes plus tard, la personne a repris là où elle s''était arrêtée, et la séance a continué.',
   'Un moment précis qui montre une règle implicite du groupe, sans identifier personne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S23 / EXCELLENT
  ('d6f1fa4d-10da-54df-bbc6-5cca4d66a42c', '1957f5a2-91cc-51e6-b4cf-8d197101a7b4', 'EXCELLENT',
   'Ce groupe fonctionne vraiment. Un jeudi, quelqu''un a fondu en larmes au milieu d''une phrase. Personne n''a rien dit, personne n''a tendu un mouchoir, personne n''a changé de sujet. On a simplement attendu. Cinq minutes après, la phrase a repris exactement là où elle s''était arrêtée.',
   'L''énumération de ce que personne n''a fait rend visible la règle tacite : c''est l''illustration la plus précise possible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S24 / INSUFFICIENT
  ('b0360d55-10de-5376-9a38-82a40933d70b', 'e089927e-c359-5824-9f3e-a0a1d4553923', 'INSUFFICIENT',
   'Cette restauration est réussie. Sauver un lavoir, c''est préserver la mémoire d''un village et rappeler comment vivaient les générations précédentes. Ce sont des lieux qui disparaissent partout et qu''il faut absolument défendre avant qu''il ne soit trop tard. Chaque commune devrait se poser la question avant que ses bâtiments anciens ne tombent en ruine.',
   'Un plaidoyer sur le patrimoine en général. Le lavoir du chemin des Prés n''apparaît jamais.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S24 / EXPECTED
  ('decd27fc-e557-5a2f-a0b8-481a8f70496c', 'e089927e-c359-5824-9f3e-a0a1d4553923', 'EXPECTED',
   'Cette restauration est réussie. Dimanche dernier, j''ai vu trois familles pique-niquer sur les bancs de pierre pendant que les enfants trempaient les pieds dans le bassin. Un monsieur âgé expliquait à sa petite-fille comment sa mère y lavait les draps. L''endroit était vivant.',
   'Une scène datée, observée, avec plusieurs plans : le lieu est montré en usage.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S24 / EXCELLENT
  ('32375995-310d-55f5-96ed-df96dfdb9eda', 'e089927e-c359-5824-9f3e-a0a1d4553923', 'EXCELLENT',
   'Cette restauration est réussie. Dimanche dernier, trois familles pique-niquaient sur les bancs de pierre pendant que les enfants trempaient les pieds dans le bassin. Un peu à l''écart, un monsieur âgé montrait à sa petite-fille l''endroit exact où sa mère battait les draps. Personne n''était là par hasard.',
   '« L''endroit exact » et « personne n''était là par hasard » transforment l''observation en démonstration.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S25 / INSUFFICIENT
  ('eac600fb-faeb-51ed-9c14-d2a786dd3507', '093ba14c-d0e9-5512-93b0-5afbe379b858', 'INSUFFICIENT',
   'Mon voisin du premier est quelqu''un de rare. Il est serviable, généreux de son temps, toujours prêt à donner un coup de main et il ne demande jamais rien en retour. Ce sont des qualités qu''on ne trouve plus beaucoup aujourd''hui.',
   'Quatre qualités et une lamentation générale. Aucun fait ne les soutient.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S25 / EXPECTED
  ('7c6f58a2-6bf9-5cf8-a9d4-bb8c23b3bfa6', '093ba14c-d0e9-5512-93b0-5afbe379b858', 'EXPECTED',
   'Mon voisin du premier est quelqu''un de rare. Un soir d''hiver, mon chauffe-eau a lâché à vingt-deux heures. Il est monté avec sa caisse à outils, a démonté la résistance et a trouvé la panne. Il est reparti à minuit en refusant que je le paie.',
   'Une soirée, une panne, une intervention, un refus : l''exemple prouve tout ce qui était affirmé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S25 / EXCELLENT
  ('98f3b6de-ab05-5f7a-8e79-41716acca8e2', '093ba14c-d0e9-5512-93b0-5afbe379b858', 'EXCELLENT',
   'Mon voisin du premier est quelqu''un de rare. Un soir d''hiver, mon chauffe-eau a lâché à vingt-deux heures. Il est monté avec sa caisse à outils, a démonté la résistance et trouvé la panne. Il est reparti à minuit, a refusé que je le paie, et n''en a jamais reparlé depuis.',
   '« N''en a jamais reparlé » est le détail qui distingue la vraie générosité de celle qu''on se fait rappeler.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S26 / INSUFFICIENT
  ('c2cd5537-47d1-521f-b36c-8b634b2554d8', '4232e29d-1c51-5f0e-95ea-48ac4c8942da', 'INSUFFICIENT',
   'Cette équipe est excellente. Les professionnels de la petite enfance font un métier essentiel et trop peu reconnu. Il faudrait davantage de places et de meilleures conditions de travail, car c''est là que tout se joue pour les premières années d''un enfant.',
   'Un propos sur le secteur de la petite enfance. Cette équipe-ci n''est jamais évoquée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S26 / EXPECTED
  ('c0dd47b7-82b2-50b2-b124-a8e66f72d1e8', '4232e29d-1c51-5f0e-95ea-48ac4c8942da', 'EXPECTED',
   'Cette équipe est excellente. En septembre, mon fils hurlait chaque matin à la séparation. Une auxiliaire a proposé qu''il apporte le foulard de sa grand-mère. Elle le lui gardait dans sa poche et le lui rendait au moindre chagrin. En trois semaines, les pleurs avaient cessé.',
   'Une difficulté, une initiative, un protocole tenu, un résultat daté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S26 / EXCELLENT
  ('09ebc678-6503-5c1c-aff6-8fd48745f706', '4232e29d-1c51-5f0e-95ea-48ac4c8942da', 'EXCELLENT',
   'Cette équipe est excellente. En septembre, mon fils hurlait chaque matin à la séparation. Une auxiliaire a proposé qu''il apporte le foulard de sa grand-mère : elle le gardait dans sa poche et le lui rendait au moindre chagrin, sans qu''il ait à le réclamer. En trois semaines, les pleurs avaient cessé.',
   '« Sans qu''il ait à le réclamer » montre que l''équipe a pensé à ce que l''enfant ne pouvait pas demander.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S27 / INSUFFICIENT
  ('4830e567-3868-5059-83f3-b49873c0cc2c', '88b9fb5c-c902-5dee-b956-032445b20dcf', 'INSUFFICIENT',
   'Cette médiathèque est un lieu précieux. La lecture développe l''imagination, enrichit le vocabulaire et permet de mieux comprendre le monde. Dans une époque où les écrans prennent toute la place, il est essentiel de maintenir des lieux consacrés au livre.',
   'Un éloge de la lecture. La médiathèque, comme lieu, n''apparaît nulle part.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S27 / EXPECTED
  ('145e1d13-a56c-564b-92e6-40e265b097ed', '88b9fb5c-c902-5dee-b956-032445b20dcf', 'EXPECTED',
   'Cette médiathèque est un lieu précieux. Samedi dernier vers onze heures, la salle du fond était pleine : quatre lycéens révisaient à une table, deux retraités lisaient le journal, et un père aidait sa fille à choisir des albums. Personne ne gênait personne.',
   'Une heure, trois usages simultanés observés : le lieu est montré dans sa fonction réelle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S27 / EXCELLENT
  ('475274e5-9b3f-575e-9b28-4f6a047fdd4c', '88b9fb5c-c902-5dee-b956-032445b20dcf', 'EXCELLENT',
   'Cette médiathèque est un lieu précieux. Samedi dernier vers onze heures, la salle du fond réunissait quatre lycéens qui révisaient, deux retraités devant les journaux et un père accroupi au rayon albums avec sa fille. Aucun des trois groupes ne gênait les autres — c''est plus rare qu''il n''y paraît.',
   '« Plus rare qu''il n''y paraît » désigne ce que la scène démontre, sans jamais quitter la scène.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S28 / INSUFFICIENT
  ('ff1d19d5-ef87-5ac1-986a-bfbff2ca9b25', '37d7bb41-b253-596c-9479-6015dcfb432c', 'INSUFFICIENT',
   'Ce vélo a résolu mon problème. Combiner plusieurs modes de transport est la seule solution réaliste dans les grandes agglomérations, où les trajets domicile-travail sont de plus en plus longs. Le vélo pliant répond bien à ce besoin de flexibilité.',
   'Une analyse de la mobilité urbaine. Aucun trajet réel, aucun jour, aucun incident.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S28 / EXPECTED
  ('33a32962-b19a-5efd-8130-31f91b69889e', '37d7bb41-b253-596c-9479-6015dcfb432c', 'EXPECTED',
   'Ce vélo a résolu mon problème. Un lundi, mon train a été supprimé à sept heures dix. Avant, j''aurais attendu quarante minutes le suivant. J''ai déplié le vélo sur le quai, fait les six kilomètres restants et je suis arrivé au bureau avec dix minutes d''avance.',
   'Un incident daté, une alternative chiffrée, un résultat : l''objet est mis à l''épreuve.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S28 / EXCELLENT
  ('478a87bc-f18e-5b1a-af50-53474ffd350a', '37d7bb41-b253-596c-9479-6015dcfb432c', 'EXCELLENT',
   'Ce vélo a résolu mon problème. Un lundi, mon train a été supprimé à sept heures dix, le suivant annoncé quarante minutes plus tard. J''ai déplié le vélo sur le quai en une minute et fait les six kilomètres restants. Je suis arrivé avec dix minutes d''avance, pendant que les autres attendaient encore.',
   'La dernière proposition donne la mesure du bénéfice par comparaison, sans quitter la scène racontée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S29 / INSUFFICIENT
  ('47d7ad5f-afbc-575e-ab32-0e18290353bf', '034a4165-6b2d-5e87-97e4-06c8f658aa22', 'INSUFFICIENT',
   'Ce médecin a été très bon. Les gardes du dimanche sont indispensables, surtout pour les familles avec de jeunes enfants qui ne peuvent pas attendre le lundi. Sans ce dispositif, tout le monde se retrouverait aux urgences pour des motifs bénins.',
   'Un propos sur l''utilité des gardes. Le praticien consulté n''apparaît pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S29 / EXPECTED
  ('e337a064-6dd8-56e3-a1d2-21c7bf625a87', '034a4165-6b2d-5e87-97e4-06c8f658aa22', 'EXPECTED',
   'Ce médecin a été très bon. Pendant la consultation, il a demandé à ma fille de sept ans de décrire elle-même sa douleur, au lieu de s''adresser uniquement à moi. Elle a montré un endroit que je n''aurais pas indiqué. Cela a changé son diagnostic.',
   'Un geste précis, une conséquence médicale : l''exemple montre la qualité du praticien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S29 / EXCELLENT
  ('91440295-00dd-55ab-87f1-1f64b47edb1a', '034a4165-6b2d-5e87-97e4-06c8f658aa22', 'EXCELLENT',
   'Ce médecin a été très bon. Pendant la consultation, il s''est accroupi et a demandé à ma fille de sept ans de montrer elle-même où elle avait mal, au lieu de m''interroger. Elle a désigné un endroit que je n''aurais pas indiqué — et c''est ce point-là qui a orienté le diagnostic.',
   'L''accroupissement et l''insistance sur l''écart entre les deux indications rendent l''exemple décisif.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S30 / INSUFFICIENT
  ('52e95919-baa7-595d-99c2-52ae22e798dd', '7b01eaa0-01e8-510d-ac0a-929cf8d6bdfa', 'INSUFFICIENT',
   'Ce club est très vivant. Échanger sur un livre permet de le comprendre autrement, de découvrir des lectures qu''on n''aurait jamais ouvertes et de sortir de ses habitudes. C''est toujours enrichissant de confronter son point de vue à celui des autres.',
   'Trois généralités sur les clubs de lecture. Aucune séance, aucun livre, aucun échange réel.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S30 / EXPECTED
  ('24d08199-4e66-59a5-a5e6-65d4d3f9213a', '7b01eaa0-01e8-510d-ac0a-929cf8d6bdfa', 'EXPECTED',
   'Ce club est très vivant. À la séance de mars, deux membres n''étaient pas du tout d''accord sur la fin du roman. La discussion a duré quarante minutes. Personne n''a haussé le ton et chacun a fini par relire le passage à voix haute pour appuyer sa lecture.',
   'Une séance datée, un désaccord, une durée, une manière de le traiter.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C4-S30 / EXCELLENT
  ('06425713-045d-5dc2-9f78-bcb5272a4938', '7b01eaa0-01e8-510d-ac0a-929cf8d6bdfa', 'EXCELLENT',
   'Ce club est très vivant. À la séance de mars, deux membres se sont opposés sur la fin du roman pendant quarante minutes. Personne n''a haussé le ton : chacune a fini par relire son passage à voix haute pour montrer d''où venait sa lecture. Aucune n''a changé d''avis, et c''était très bien ainsi.',
   'La dernière phrase montre ce que le groupe valorise, ce qu''aucune généralité n''aurait pu dire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S16 / INSUFFICIENT
  ('5dac40ad-949d-5697-b52f-99f788dae155', 'e348d0be-c85f-5d43-aa7a-71669371bdde', 'INSUFFICIENT',
   'Ce parc est un endroit très calme. On y est vraiment tranquille, loin du bruit. C''est un lieu paisible où l''on se repose. Le silence y est agréable et reposant. Franchement, on s''y sent au calme, ce qui est rare en ville aujourd''hui.',
   'Cinq phrases disent la même chose : calme, tranquille, paisible, silencieux. Le propos n''avance pas d''un mot.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S16 / EXPECTED
  ('2af21ff3-d7c1-550b-bb6c-775ca5bcbe86', 'e348d0be-c85f-5d43-aa7a-71669371bdde', 'EXPECTED',
   'Ce parc est un endroit très calme. Les arbres sont assez vieux pour donner une vraie ombre en juillet. Les allées sont larges, on peut y courir sans gêner les promeneurs. Et comme il longe la rivière, l''air y est plus frais qu''ailleurs en pleine chaleur.',
   'Quatre phrases, quatre idées différentes : calme, ombre, allées, fraîcheur. Rien ne se répète.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S16 / EXCELLENT
  ('22c0da41-6739-5888-a191-dbc906f17325', 'e348d0be-c85f-5d43-aa7a-71669371bdde', 'EXCELLENT',
   'Ce parc est un endroit très calme. Ses arbres sont assez vieux pour donner une ombre continue en juillet, ce qui manque aux parcs récents. Les allées, larges, permettent de courir sans slalomer entre les poussettes. Et le long de la rivière, il fait toujours deux ou trois degrés de moins.',
   'Chaque idée est non seulement nouvelle mais précisée, et l''avant-dernière se compare aux parcs récents sans revenir en arrière.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S17 / INSUFFICIENT
  ('4ac01f1a-118b-512c-9bba-3506a8c68e11', '09e2836a-88c9-5f47-8782-801c50d55f85', 'INSUFFICIENT',
   'Cet aspirateur est très pratique. Il est vraiment commode à utiliser au quotidien. Son maniement est simple et il ne demande aucun effort. C''est un appareil facile, qui rend service tous les jours sans jamais compliquer les choses. Bref, il est très pratique.',
   'Pratique, commode, simple, facile : cinq façons de dire la même chose, et la dernière phrase boucle sur la première.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S17 / EXPECTED
  ('7af1035c-1ee4-543a-a483-45e05c0efe32', '09e2836a-88c9-5f47-8782-801c50d55f85', 'EXPECTED',
   'Cet aspirateur est très pratique. Il se décroche en deux secondes pour aspirer la voiture ou les escaliers. La batterie tient vingt-cinq minutes, assez pour tout l''appartement. Le bac se vide au-dessus de la poubelle sans qu''on touche la poussière. Il se range debout dans un placard.',
   'Cinq idées distinctes : modularité, autonomie, vidage, rangement. Aucune ne redit la précédente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S17 / EXCELLENT
  ('28d824d5-56fe-54d7-865c-d782de17e85f', '09e2836a-88c9-5f47-8782-801c50d55f85', 'EXCELLENT',
   'Cet aspirateur est très pratique. Il se décroche en deux secondes pour la voiture ou les escaliers, là où un traîneau ne monte pas. La batterie tient vingt-cinq minutes, soit tout l''appartement d''une traite. Le bac se vide sans qu''on touche la poussière, ce qui compte quand on est allergique.',
   'Chaque idée nouvelle porte en plus la raison de son importance, sans jamais revenir à la précédente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S18 / INSUFFICIENT
  ('34a00852-5282-531f-b426-10a0cf779005', '6c74cd98-f776-55c3-a3ee-c98f74209ec5', 'INSUFFICIENT',
   'Cette maîtresse est très bien. Elle est patiente avec les enfants. Elle ne s''énerve jamais. Elle reste calme en toute circonstance. Elle est douce dans sa façon de parler. Elle ne hausse jamais le ton. C''est quelqu''un de très posé.',
   'Six phrases pour une seule qualité : le calme. Le lecteur n''apprend rien après la deuxième.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S18 / EXPECTED
  ('ae4a94b2-60cf-5cbb-b88c-dfc94d5b2e1b', '6c74cd98-f776-55c3-a3ee-c98f74209ec5', 'EXPECTED',
   'Cette maîtresse est très bien. Elle ne s''énerve jamais, même en fin de journée. Elle envoie chaque vendredi un mot sur ce qui a été travaillé. Elle repère très vite les enfants en difficulté et prévient les parents avant que cela s''installe. Elle fait sortir la classe dehors dès qu''il fait beau.',
   'Quatre idées entièrement différentes : tempérament, communication, vigilance, pédagogie.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S18 / EXCELLENT
  ('58bb16cb-332d-53f1-b2bd-f9a7efdfe077', '6c74cd98-f776-55c3-a3ee-c98f74209ec5', 'EXCELLENT',
   'Cette maîtresse est très bien. Elle ne s''énerve jamais, même en fin de journée. Chaque vendredi, un mot dans le cahier dit ce qui a été travaillé et ce qui coince. Elle repère les difficultés avant nous, et prévient sans attendre le trimestre. Elle sort la classe dès qu''il fait beau, même quinze minutes.',
   'Les quatre idées restent distinctes et chacune gagne une précision qui n''était pas dans la précédente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S19 / INSUFFICIENT
  ('51bfe234-b1ab-5147-a76e-27ac04cb5139', 'edc39a2c-925f-5263-845b-70442b13b728', 'INSUFFICIENT',
   'Cette équipe a été très sérieuse. Ils sont vraiment professionnels. Leur travail est soigné. On sent qu''ils connaissent leur métier. C''est du sérieux du début à la fin. Vraiment, des gens rigoureux comme on aimerait en trouver plus souvent. Du bon travail, vraiment, il n''y a rien à redire là-dessus.',
   'Sérieux, professionnels, soignés, rigoureux : la même idée répétée six fois.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S19 / EXPECTED
  ('2f0a6f67-9244-522a-980c-61c39ddb1274', 'edc39a2c-925f-5263-845b-70442b13b728', 'EXPECTED',
   'Cette équipe a été très sérieuse. Ils sont arrivés à sept heures chaque matin, sans exception. Ils protégeaient le couloir avec des bâches avant de commencer. Le devis n''a pas bougé d''un euro. Et ils ont emporté tous les gravats le dernier jour, sans qu''on ait à demander.',
   'Quatre faits différents : ponctualité, protection, devis, fin de chantier. Aucun ne répète l''autre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S19 / EXCELLENT
  ('9041e8d8-be50-515b-b207-16f6b657e2e6', 'edc39a2c-925f-5263-845b-70442b13b728', 'EXCELLENT',
   'Cette équipe a été très sérieuse. Sept heures chaque matin, sans exception, y compris le lendemain du jour férié. Ils bâchaient le couloir avant de poser le premier outil. Le devis n''a pas bougé d''un euro malgré deux imprévus. Et les gravats sont partis le dernier soir, sans qu''on demande.',
   'Chaque idée nouvelle s''accompagne de ce qui la rend remarquable, sans jamais recycler la précédente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S20 / INSUFFICIENT
  ('dd43c3a9-c6dd-5eaa-bbb4-2c834a33f2a0', '5f92abb3-064b-5411-8f86-23ce5051bb96', 'INSUFFICIENT',
   'Ce camping est une bonne adresse. C''est un endroit vraiment agréable. On y passe un bon séjour. L''ensemble est très plaisant. C''est un lieu où l''on se sent bien. Je le recommande, c''est une adresse à retenir pour les vacances.',
   'Bonne adresse, agréable, plaisant, on s''y sent bien : rien n''est dit, six fois.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S20 / EXPECTED
  ('86ae3b53-08bb-5c54-8efe-3964226e0d71', '5f92abb3-064b-5411-8f86-23ce5051bb96', 'EXPECTED',
   'Ce camping est une bonne adresse. Les emplacements sont séparés par des haies, on n''entend pas les voisins. Les sanitaires sont nettoyés deux fois par jour. L''accès au lac se fait par un sentier de deux minutes. Et le pain est livré chaque matin à l''accueil.',
   'Quatre informations différentes, toutes utiles à quelqu''un qui choisit un camping.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S20 / EXCELLENT
  ('156cbaa1-8973-51b3-bd27-a843ff6a6824', '5f92abb3-064b-5411-8f86-23ce5051bb96', 'EXCELLENT',
   'Ce camping est une bonne adresse. Les emplacements sont séparés par de vraies haies, pas des piquets : on n''entend pas les voisins. Les sanitaires sont nettoyés deux fois par jour, même en août. Le lac est à deux minutes par un sentier ombragé. Le pain arrive à l''accueil avant huit heures.',
   'Les quatre idées restent distinctes, et chacune anticipe la question que le lecteur allait poser.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S21 / INSUFFICIENT
  ('2a2afada-bd83-52a3-92e0-52e3140c60db', 'e8b25f6b-465e-5916-9985-798d7d175334', 'INSUFFICIENT',
   'Ce matelas est un bon achat. Il est vraiment confortable. On y dort très bien. Le confort est au rendez-vous. C''est agréable de s''y allonger. Franchement, question confort, il n''y a rien à redire, on s''y sent très bien. Le confort est excellent, je le redis, c''est un matelas confortable.',
   'Confort, confortable, on y dort bien, agréable : une seule idée, six formulations.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S21 / EXPECTED
  ('60345e60-a84f-5819-bea5-eea9dc4b9eb7', 'e8b25f6b-465e-5916-9985-798d7d175334', 'EXPECTED',
   'Ce matelas est un bon achat. Il est assez ferme pour qu''on ne s''enfonce pas au milieu. Il ne renvoie pas la chaleur, ce qui compte l''été. On ne sent pas l''autre bouger pendant la nuit. Et après un an, il n''a pas creusé aux endroits d''appui.',
   'Quatre critères différents : fermeté, température, indépendance de couchage, tenue dans le temps.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S21 / EXCELLENT
  ('8dfa7192-c94b-58f0-bf59-f8962322c736', 'e8b25f6b-465e-5916-9985-798d7d175334', 'EXCELLENT',
   'Ce matelas est un bon achat. Assez ferme pour qu''on ne s''enfonce pas au milieu, même à deux. Il ne renvoie pas la chaleur, ce qui a changé mes nuits de juillet. On ne sent pas l''autre se retourner. Et après un an, aucune cuvette là où on dort — c''est là qu''on juge un matelas.',
   '« C''est là qu''on juge un matelas » clôt en désignant le critère décisif, sans répéter les précédents.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S22 / INSUFFICIENT
  ('ffeed26e-9c86-5531-97d6-57a4079f86d2', 'd7292682-4774-5b86-935c-4a139b9e9c87', 'INSUFFICIENT',
   'Ce kiné est très bon. Il est à l''écoute de ses patients. Il fait attention à ce qu''on lui dit. Il prend le temps d''écouter. Il est attentif et disponible. On sent qu''il s''intéresse vraiment à nous et qu''il nous écoute sincèrement.',
   'À l''écoute, attentif, il écoute, il s''intéresse : six phrases pour une seule qualité.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S22 / EXPECTED
  ('a690d74f-49c3-519b-ad9a-8312c98dd3c7', 'd7292682-4774-5b86-935c-4a139b9e9c87', 'EXPECTED',
   'Ce kiné est très bon. Il commence par vous faire marcher avant de toucher quoi que ce soit. Il donne trois exercices maximum à faire chez soi, jamais dix. Il dit clairement combien de séances il prévoit. Et il arrête le traitement quand ça va mieux, sans prolonger.',
   'Quatre idées distinctes, dont la dernière est celle qu''on n''attendait pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S22 / EXCELLENT
  ('b5641d4e-c02c-5813-88da-c9f1017cd42e', 'd7292682-4774-5b86-935c-4a139b9e9c87', 'EXCELLENT',
   'Ce kiné est très bon. Il vous fait marcher avant de toucher quoi que ce soit. Il donne trois exercices maximum pour la maison, parce qu''au-delà personne ne les fait. Il annonce dès la première séance combien il en prévoit. Et il arrête quand ça va mieux, sans étirer l''ordonnance.',
   'Chaque idée nouvelle porte sa justification, et la dernière touche à l''honnêteté — un registre qu''aucune autre n''occupait.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S23 / INSUFFICIENT
  ('2b5635ab-c008-5b54-aece-13f5b20fa757', '02e3beae-25e3-57d4-b0b3-f5197c380d36', 'INSUFFICIENT',
   'Les gens de l''allée sont très bien. Ils sont sympathiques. Ils sont gentils avec tout le monde. Ce sont des gens agréables. Ils sont aimables quand on les croise. Bref, une allée où les voisins sont vraiment sympas, ça change tout.',
   'Sympathiques, gentils, agréables, aimables, sympas : la même idée, cinq fois, et un bouclage final.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S23 / EXPECTED
  ('a891fa85-0555-5b72-97f2-2cea0c95fe6f', '02e3beae-25e3-57d4-b0b3-f5197c380d36', 'EXPECTED',
   'Les gens de l''allée sont très bien. On se garde les colis sans que personne l''ait organisé. Il y a un groupe de messages où l''on prévient quand un camion bloque le passage. Les enfants jouent ensemble le mercredi. Et personne n''a jamais fait de remarque sur le bruit d''un déménagement.',
   'Quatre faits différents, qui montrent quatre aspects distincts de la vie de l''allée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S23 / EXCELLENT
  ('abdfc574-c443-5340-9c78-9ce2514c03bc', '02e3beae-25e3-57d4-b0b3-f5197c380d36', 'EXCELLENT',
   'Les gens de l''allée sont très bien. On se garde les colis sans que personne ne l''ait décidé. Un groupe de messages sert à prévenir quand un camion bloque le passage, et à rien d''autre. Les enfants jouent ensemble le mercredi. Personne n''a jamais râlé pour le bruit d''un déménagement.',
   '« Et à rien d''autre » est le genre de précision qui distingue une allée d''une autre : l''idée progresse encore.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S24 / INSUFFICIENT
  ('beaa6a9f-3916-568e-a9d2-6f859d582398', 'c6c57b0a-9654-5d42-b841-ea4790917cf7', 'INSUFFICIENT',
   'La halle aux grains mérite le détour. C''est un très beau bâtiment. L''architecture est magnifique. C''est vraiment superbe à voir. On reste impressionné devant une telle beauté. Franchement, c''est splendide, il faut absolument aller le voir quand on passe par là.',
   'Beau, magnifique, superbe, splendide : cinq synonymes, aucune information.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S24 / EXPECTED
  ('469e0b1d-c966-59a3-9ff9-086f232e37d2', 'c6c57b0a-9654-5d42-b841-ea4790917cf7', 'EXPECTED',
   'La halle aux grains mérite le détour. Sa charpente en bois tient sans un seul pilier au centre, sur trente mètres. Les murs de brique gardent la fraîcheur même en août. Elle sert aujourd''hui de salle de concert, et l''acoustique y est réputée. L''entrée est libre en semaine.',
   'Quatre idées différentes : structure, thermique, usage actuel, accès.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S24 / EXCELLENT
  ('9b816eed-f4f5-52a1-b279-02a3f21d29d8', 'c6c57b0a-9654-5d42-b841-ea4790917cf7', 'EXCELLENT',
   'La halle aux grains mérite le détour. Sa charpente couvre trente mètres sans un seul pilier central, ce qui se voit dès qu''on entre. Les murs de brique gardent la fraîcheur en plein août. Elle sert de salle de concert, et les musiciens viennent pour l''acoustique. Entrée libre en semaine.',
   'Chaque idée reste distincte et gagne une preuve — « les musiciens viennent pour » vaut mieux que « réputée ».', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S25 / INSUFFICIENT
  ('76a9bcc6-ebbf-5764-a3a6-c812934d40e3', 'fd422e0f-4820-5668-87d5-cc8f9b788bb5', 'INSUFFICIENT',
   'Ce sèche-linge est décevant. Il ne sèche pas bien. Le linge sort encore humide. On doit souvent relancer un cycle. Le séchage est insuffisant. Bref, il ne fait pas correctement ce pour quoi il est là, c''est vraiment décevant. Le résultat n''est pas à la hauteur, on est déçus du séchage.',
   'Un seul défaut — le séchage insuffisant — reformulé cinq fois, avec un retour à la première phrase.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S25 / EXPECTED
  ('cdf5da03-78d8-54dc-8ca1-001a1553850a', 'fd422e0f-4820-5668-87d5-cc8f9b788bb5', 'EXPECTED',
   'Ce sèche-linge est décevant. Le linge sort encore humide au bout du cycle complet. Le filtre se sature en deux utilisations et personne ne le nettoie. Le tambour marque le linge clair. Et le minuteur affiche quarante minutes quand il en reste soixante.',
   'Quatre défauts indépendants : séchage, filtre, tambour, affichage.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S25 / EXCELLENT
  ('fccfd5ae-5613-5dea-a01b-237df30c8cb9', 'fd422e0f-4820-5668-87d5-cc8f9b788bb5', 'EXCELLENT',
   'Ce sèche-linge est décevant. Le linge sort humide au bout d''un cycle complet, donc chacun en lance deux. Le filtre sature en deux utilisations, et personne ne le nettoie entre les passages. Le tambour laisse des traces grises sur le linge clair. Quant au minuteur, il ment d''un bon quart d''heure.',
   'Le premier défaut explique une conséquence collective, puis trois autres défauts sans lien entre eux : rien ne tourne en rond.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S26 / INSUFFICIENT
  ('3c560631-aee1-5ea1-91ef-352782fb342d', '64789f7e-8a90-5aea-a860-eb3ca078c027', 'INSUFFICIENT',
   'Ce gérant tient très bien son magasin. Il s''en occupe vraiment bien. On voit qu''il y consacre du temps. Sa gestion est sérieuse. Il fait tourner son commerce correctement. C''est quelqu''un qui tient bien sa boutique, ça se remarque tout de suite.',
   'Six phrases qui disent « il tient bien son magasin » : le propos revient à son point de départ.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S26 / EXPECTED
  ('96a06d31-0b72-5bd1-a616-f72d73a8f0ca', '64789f7e-8a90-5aea-a860-eb3ca078c027', 'EXPECTED',
   'Ce gérant tient très bien son magasin. Il commande à la demande : si on cherche un produit deux fois, il le prend. Il baisse les prix des fruits la veille plutôt que de les jeter. Il connaît les habitudes des personnes âgées et leur met de côté. Il ouvre le dimanche matin.',
   'Quatre pratiques différentes, chacune révélant un aspect distinct de sa manière de travailler.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S26 / EXCELLENT
  ('05143b8c-72d3-5dec-b757-d6a217cba411', '64789f7e-8a90-5aea-a860-eb3ca078c027', 'EXCELLENT',
   'Ce gérant tient très bien son magasin. Si on demande un produit deux fois, il le commande la semaine suivante. Il solde les fruits la veille plutôt que de les jeter. Il met de côté pour les personnes âgées qui viennent tard. Et il n''a jamais fermé un dimanche matin depuis six ans.',
   'Les quatre idées progressent, et la dernière ajoute une durée qui donne du poids à tout ce qui précède.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S27 / INSUFFICIENT
  ('e734a129-9719-5c15-bb75-8e5c6ba9d5db', 'a3dc8151-d024-5d60-b0f0-a52871076ca1', 'INSUFFICIENT',
   'Ce groupe est très accueillant. On s''y sent bien reçu. Les gens sont ouverts aux nouveaux. L''ambiance est chaleureuse. On est bien accueilli dès le premier jour. C''est vraiment un groupe où l''on se sent tout de suite le bienvenu.',
   'Accueillant, bien reçu, ouvert, chaleureux, bienvenu : une seule idée, six habillages.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S27 / EXPECTED
  ('8ab14924-abe7-52b3-9f47-9e9e96e78c25', 'a3dc8151-d024-5d60-b0f0-a52871076ca1', 'EXPECTED',
   'Ce groupe est très accueillant. Chacun peut refuser un rôle sans avoir à se justifier. Les textes sont choisis à la majorité, jamais imposés. Les timides commencent par des scènes courtes. Et personne ne commente le jeu des autres en dehors du temps prévu pour ça.',
   'Quatre règles implicites du groupe, toutes différentes, toutes vérifiables.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S27 / EXCELLENT
  ('25fbaf35-659d-5f7e-83e1-d25f40ecffec', 'a3dc8151-d024-5d60-b0f0-a52871076ca1', 'EXCELLENT',
   'Ce groupe est très accueillant. On peut refuser un rôle sans se justifier, et personne ne revient dessus. Les textes se choisissent à la majorité. Les timides commencent par des scènes à deux répliques. Et les remarques sur le jeu ne se font qu''au moment prévu — jamais dans le couloir.',
   '« Jamais dans le couloir » précise la quatrième règle d''une manière que les trois autres n''avaient pas occupée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S28 / INSUFFICIENT
  ('b4f8cb75-098a-5f81-8bad-7ed40befe42f', 'a1b2241c-be3b-5a3a-bfcd-274eba147c4c', 'INSUFFICIENT',
   'Ce sentier est exigeant. Il est vraiment difficile. C''est une randonnée éprouvante. Le parcours est costaud. Il ne faut pas le sous-estimer, c''est dur. Vraiment, il vaut mieux être en forme, parce que c''est une marche exigeante. C''est vraiment une marche difficile, il ne faut pas y aller sans être prêt physiquement.',
   'Exigeant, difficile, éprouvant, costaud, dur : le mot change, l''information non.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S28 / EXPECTED
  ('32fd2a6c-8845-5932-9b58-aa734c348d02', 'a1b2241c-be3b-5a3a-bfcd-274eba147c4c', 'EXPECTED',
   'Ce sentier est exigeant. Les six cents mètres de dénivelé se font en trois kilomètres. Le sol est en pierres roulantes sur la moitié du parcours. Il n''y a aucune source après le premier tiers. En revanche, le plateau du sommet est plat et se marche très facilement.',
   'Quatre informations distinctes, dont la dernière nuance sans revenir en arrière.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S28 / EXCELLENT
  ('25acf2f9-4fbe-58eb-adb6-c5a55c358551', 'a1b2241c-be3b-5a3a-bfcd-274eba147c4c', 'EXCELLENT',
   'Ce sentier est exigeant. Six cents mètres de dénivelé en trois kilomètres seulement, donc ça monte tout le temps. La moitié du parcours est en pierres roulantes, éprouvantes à la descente plus qu''à la montée. Aucune source après le premier tiers. Le plateau, lui, se marche les mains dans les poches.',
   'La remarque sur la descente est une idée nouvelle tirée du même fait, et la dernière image referme sans répéter.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S29 / INSUFFICIENT
  ('c67be97e-1c73-5126-859a-2ac94073d2ce', 'bfff318c-19c2-5e04-8175-b7cc093a8ee1', 'INSUFFICIENT',
   'Cette cafetière est un bon choix. C''est un bon achat. Elle est bien. Le choix était le bon. On est satisfaits. Vraiment, c''est une réussite, tout le monde au bureau trouve que c''était un bon choix de l''acheter. Une bonne machine, en somme, et un bon investissement pour le service.',
   'Bon choix, bon achat, bien, satisfaits, réussite : rien n''est dit sur la machine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S29 / EXPECTED
  ('087d7a02-0be1-55e9-b8f7-60c1c38a5cb0', 'bfff318c-19c2-5e04-8175-b7cc093a8ee1', 'EXPECTED',
   'Cette cafetière est un bon choix. Elle sert quatre tasses en moins d''une minute, donc plus de file d''attente à dix heures. Le bac à marc se vide sans outil. Elle s''éteint seule au bout d''une heure. Et elle accepte le café moulu, pas seulement les capsules.',
   'Quatre qualités indépendantes, toutes vérifiables, aucune répétée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S29 / EXCELLENT
  ('6b9253f7-4a0f-54f1-8e40-19c4007640e3', 'bfff318c-19c2-5e04-8175-b7cc093a8ee1', 'EXCELLENT',
   'Cette cafetière est un bon choix. Quatre tasses en moins d''une minute : la file de dix heures a disparu. Le bac à marc se vide sans outil ni notice. Elle s''éteint seule au bout d''une heure, ce que l''ancienne ne faisait pas. Et elle prend du moulu, donc on n''est plus liés aux capsules.',
   'Chaque idée neuve porte sa conséquence, et la dernière touche à un enjeu que les autres n''abordaient pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S30 / INSUFFICIENT
  ('9e53672a-ca03-5202-b99f-7a2f2762b5ad', '284e22e8-7a28-542e-a121-b756c2e8b711', 'INSUFFICIENT',
   'Cet entraîneur est excellent. Il fait un travail remarquable. C''est vraiment quelqu''un de très bien. Son travail est de grande qualité. Il est parfait dans son rôle. On ne pourrait pas trouver mieux, c''est un excellent entraîneur pour ces jeunes.',
   'Excellent, remarquable, très bien, de qualité, parfait : six phrases sans un seul fait.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S30 / EXPECTED
  ('8085767d-9298-5fa7-b183-d70c52f71f47', '284e22e8-7a28-542e-a121-b756c2e8b711', 'EXPECTED',
   'Cet entraîneur est excellent. Il fait jouer tout le monde au moins une mi-temps, même quand le match est serré. Il explique les erreurs à l''entraînement suivant, jamais sur le terrain. Il félicite les passes autant que les buts. Et il parle aux parents qui crient trop.',
   'Quatre principes distincts, qui décrivent une manière d''entraîner et non des qualités abstraites.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C5-S30 / EXCELLENT
  ('3adef7df-d401-57a9-9a08-16b8c72ef22d', '284e22e8-7a28-542e-a121-b756c2e8b711', 'EXCELLENT',
   'Cet entraîneur est excellent. Tout le monde joue au moins une mi-temps, y compris en finale de coupe. Les erreurs se corrigent à l''entraînement suivant, jamais devant les autres au bord du terrain. Il félicite les passes autant que les buts. Et il va voir les parents qui crient, au lieu de laisser faire.',
   '« Y compris en finale de coupe » et « au lieu de laisser faire » poussent chaque idée jusqu''à son cas difficile.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S1 / INSUFFICIENT
  ('3f9c2b72-e54d-5c4e-b0fc-1af7b4fdf626', '6d1e7071-6125-528d-a284-e0279349587d', 'INSUFFICIENT',
   'Madame, je me permets de vous faire part de mon appréciation concernant cet établissement. La qualité des mets proposés s''est révélée satisfaisante et le service diligent. Je vous prie de bien vouloir agréer l''expression de mes salutations distinguées. Dans l''attente de votre retour, je demeure à votre entière disposition.',
   'L''avis est correct, mais ce registre administratif est absurde entre sœurs : il éteint complètement l''échange.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S1 / EXPECTED
  ('3a324f2d-202b-5cf0-850b-2620f277efda', '6d1e7071-6125-528d-a284-e0279349587d', 'EXPECTED',
   'Franchement, on a bien mangé. Les plats arrivent vite et les portions sont généreuses. Le poisson était parfait, vraiment. Par contre c''est bruyant, on a dû répéter deux fois chaque phrase. Si tu y vas, demande la petite salle du fond, c''est plus calme.',
   'Tutoiement, exclamations, conseil direct : le registre convient, et l''avis y tient entièrement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S1 / EXCELLENT
  ('9b026618-ddca-5501-8f27-a59bc11edece', '6d1e7071-6125-528d-a284-e0279349587d', 'EXCELLENT',
   'Franchement, on a bien mangé. Les plats arrivent vite, les portions sont généreuses, et le poisson était parfait. Par contre c''est bruyant à en répéter chaque phrase deux fois. Si tu y vas, demande la petite salle du fond — c''est là qu''on aurait dû se mettre.',
   'Même registre, mieux tenu : les phrases se resserrent et le conseil final sonne comme un aveu, pas comme une recommandation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S2 / INSUFFICIENT
  ('a21710a0-76c1-560d-abd2-87e8f1d15cf4', 'e7656b98-0545-5909-bed7-1879c15c7833', 'INSUFFICIENT',
   'Salut ! Alors franchement la salle est nickel, on a passé une super soirée. Le seul truc chiant c''est le chauffage, on se gelait au début. Sinon rien à dire, on reviendra c''est sûr. Merci les gars ! Allez, à la prochaine, et encore merci pour le coup de main sur les tables !',
   '« Nickel », « chiant », « les gars » : ce registre ne convient pas à un service municipal, même si l''avis est juste.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S2 / EXPECTED
  ('b6c3614c-8641-514a-8fd5-35c3854cff2f', 'e7656b98-0545-5909-bed7-1879c15c7833', 'EXPECTED',
   'Madame, Monsieur, cette salle nous a donné entière satisfaction. L''espace est suffisant pour cinquante personnes et la cuisine attenante nous a beaucoup servi. Le chauffage met en revanche près d''une heure à monter en température. Nous la réserverons de nouveau. Bien cordialement.',
   'Vouvoiement, formule d''appel reprise, réserve exprimée sans agressivité : le registre convient.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S2 / EXCELLENT
  ('f1af1286-263b-5183-9c32-dc969c48797f', 'e7656b98-0545-5909-bed7-1879c15c7833', 'EXCELLENT',
   'Madame, Monsieur, cette salle nous a donné entière satisfaction. L''espace convient à cinquante personnes et la cuisine attenante nous a beaucoup servi. Le chauffage met près d''une heure à monter, ce qui mérite d''être signalé aux prochains utilisateurs. Nous la réserverons de nouveau. Bien cordialement.',
   'La réserve est tournée comme un service rendu aux suivants : même registre, meilleure maîtrise.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S3 / INSUFFICIENT
  ('d4e6f62c-9b1b-58d1-9ddf-ffc8b5cadc51', '5d42eb8c-cae3-59f5-85a8-e90cd2e04fe7', 'INSUFFICIENT',
   'Salut ! Ouais on l''a eu, il est plutôt sympa le gars. Bon il est pas donné hein, faut pas se leurrer. Mais il bosse bien et il traîne pas. Appelle-le de ma part, il te fera peut-être un geste ! Bon courage avec tes tuyaux, tiens-moi au jus de ce que ça donne chez toi.',
   'Le tutoiement et « ouais », « le gars », « il bosse » sont trop familiers pour un voisin qu''on connaît à peine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S3 / EXPECTED
  ('e99af465-8f94-54d2-bdff-9ae42067904c', '5d42eb8c-cae3-59f5-85a8-e90cd2e04fe7', 'EXPECTED',
   'Bonjour, oui, nous l''avons fait venir en mars. Il est arrivé à l''heure annoncée et a trouvé la fuite en vingt minutes. Le devis correspondait exactement à la facture. Ses tarifs ne sont pas les plus bas, mais il n''y a eu aucune mauvaise surprise. Je le recommande.',
   'Vouvoiement simple, sans formule administrative : exactement le registre d''un échange entre voisins.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S3 / EXCELLENT
  ('ffdd07e5-751c-5306-8f6a-1d7aa36b2be4', '5d42eb8c-cae3-59f5-85a8-e90cd2e04fe7', 'EXCELLENT',
   'Bonjour, oui, nous l''avons fait venir en mars. Il est arrivé à l''heure annoncée et a trouvé la fuite en vingt minutes, là où un autre avait cherché une heure. Le devis correspondait à la facture au centime près. Ses tarifs ne sont pas les plus bas, mais je le rappellerai sans hésiter.',
   'Le registre ne bouge pas ; c''est la précision des faits qui distingue cette réponse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S4 / INSUFFICIENT
  ('3c99751d-6160-5464-85ae-b3da7729700a', 'c86a9424-5612-5bc3-aac5-14e009353c26', 'INSUFFICIENT',
   'Comme d''habitude on a retrouvé la bande, et comme l''an dernier c''était nickel. Bon, sauf l''histoire du barbecue, mais ceux qui étaient là savent de quoi je parle ! Vivement l''an prochain, et Jean-Mi si tu lis ça, ramène la grande table.',
   'Les allusions et l''adresse à un ami rendent ce commentaire inutilisable pour un lecteur inconnu.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S4 / EXPECTED
  ('9e11c45f-25b2-530b-9e42-3134b5a065fc', 'c86a9424-5612-5bc3-aac5-14e009353c26', 'EXPECTED',
   'Séjour de cinq nuits en août. Les emplacements sont ombragés et bien séparés par des haies. Les sanitaires étaient propres à chaque passage. L''accès au lac prend deux minutes à pied. Le seul point faible est le wifi, qui ne fonctionne qu''à l''accueil.',
   'Ton neutre, informations vérifiables : un inconnu peut décider sur cette base.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S4 / EXCELLENT
  ('1d5ed48a-4a04-554f-9bbf-43214eb0e2ca', 'c86a9424-5612-5bc3-aac5-14e009353c26', 'EXCELLENT',
   'Séjour de cinq nuits en août, en famille. Emplacements ombragés et séparés par de vraies haies : on n''entend pas les voisins. Sanitaires propres à chaque passage, même en pleine saison. Lac à deux minutes à pied. Wifi uniquement à l''accueil, à prévoir si vous télétravaillez.',
   'Le contexte du séjour et le conseil final rendent l''avis directement exploitable, sans changer de registre.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S5 / INSUFFICIENT
  ('3187f504-7647-5c19-8536-1ff86d21e3b8', '0a8b180e-6419-51c6-8b66-371e8196ea0e', 'INSUFFICIENT',
   'Ton vélo présente un excellent rapport qualité-prix. Le cadre en aluminium offre une rigidité appréciable et la transmission à six vitesses conviendra parfaitement à un usage urbain. Les freins à disque constituent un atout sécuritaire non négligeable pour une utilisatrice débutante.',
   'Rapport qualité-prix, rigidité, transmission : aucun de ces mots ne parle à une enfant de huit ans.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S5 / EXPECTED
  ('309f1db9-cf1c-5fb3-94af-d4be5f7e27a8', '0a8b180e-6419-51c6-8b66-371e8196ea0e', 'EXPECTED',
   'Oui, je l''ai vu, et je le trouve super. La couleur bleue est vraiment belle au soleil. Il a l''air léger, tu vas pouvoir monter la côte sans t''arrêter. Et les freins marchent bien, j''ai essayé. Tu as bien choisi.',
   'Mots simples, phrases courtes, et un avis qui la prend au sérieux : le registre est juste.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S5 / EXCELLENT
  ('7f27f89e-3592-5fc2-9002-ce0dbca6b86b', '0a8b180e-6419-51c6-8b66-371e8196ea0e', 'EXCELLENT',
   'Oui, je l''ai vu, et je le trouve super. Le bleu est magnifique au soleil. Il est léger : tu vas monter la côte du parc sans mettre pied à terre, tu verras. Les freins mordent bien, j''ai essayé dans l''allée. Tu as vraiment bien choisi toute seule.',
   '« Tu as bien choisi toute seule » reconnaît son autonomie : c''est l''adaptation la plus fine au destinataire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S6 / INSUFFICIENT
  ('6bfae1cc-b836-5f53-869d-318c043809b4', 'a2b19181-4dec-5daa-9203-f5f484383eb2', 'INSUFFICIENT',
   'Bonjour, franchement ce truc est une catastrophe, je ne sais pas qui a eu cette idée mais il faut vraiment arrêter les frais. On perd un temps fou et tout le monde râle. Si on déploie ça jeudi, je vous garantis que ça va très mal se passer.',
   'L''avis est peut-être fondé, mais « ce truc », « arrêter les frais » et la menace finale ne conviennent pas à ce destinataire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S6 / EXPECTED
  ('93f19c94-c3b0-5e10-a79d-f7d5c21effaf', 'a2b19181-4dec-5daa-9203-f5f484383eb2', 'EXPECTED',
   'Bonjour, voici mon retour après trois semaines d''essai. La saisie des commandes est plus rapide qu''avant, environ deux minutes gagnées par dossier. En revanche, l''export comptable ne fonctionne pas encore et nous devons ressaisir à la main. Je recommande de reporter le déploiement d''un mois.',
   'Ton professionnel, faits chiffrés, recommandation claire : la franchise passe sans que le registre glisse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S6 / EXCELLENT
  ('01804dbb-7643-514d-96f8-cad268e15328', 'a2b19181-4dec-5daa-9203-f5f484383eb2', 'EXCELLENT',
   'Bonjour, voici mon retour après trois semaines d''essai. La saisie des commandes gagne environ deux minutes par dossier, ce qui est réel. En revanche, l''export comptable ne fonctionne pas et nous ressaisissons à la main — le gain est donc annulé. Je recommande de reporter d''un mois.',
   '« Le gain est donc annulé » rend l''argument imparable sans hausser d''un ton : c''est la maîtrise du registre qui fait la force.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S7 / INSUFFICIENT
  ('69f4bdf8-95aa-5a24-b262-29b722b3fc0e', '2a829c82-50ff-5af1-9373-5f143b100dc3', 'INSUFFICIENT',
   'Coucou les copines ! Alors nous c''est validé à 200 %, les animateurs sont des amours, franchement on est fans. Y a juste la grande blonde qui est un peu speed mais bon, ça va, on fait avec. Bisous à toutes ! Allez, on se fait un café un de ces quatre pour en reparler entre nous !',
   '« Les copines », « bisous à toutes » excluent la moitié du groupe, et la remarque sur « la grande blonde » désigne quelqu''un sans le nommer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S7 / EXPECTED
  ('3a61e7b7-fab9-5c26-937a-59ccb5cf7f54', '2a829c82-50ff-5af1-9373-5f143b100dc3', 'EXPECTED',
   'Bonjour à tous, nous y allons depuis septembre. L''équipe est stable, ce sont les mêmes animateurs toute l''année, et les enfants les connaissent par leur prénom. Les activités changent chaque semaine. Le seul point à savoir : il faut inscrire avant le vendredi, sinon c''est complet.',
   'Salutation qui inclut tout le monde, ton cordial, information utile : le registre du groupe est respecté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S7 / EXCELLENT
  ('06eb8c21-a251-5a45-bfc6-b7be161c51c8', '2a829c82-50ff-5af1-9373-5f143b100dc3', 'EXCELLENT',
   'Bonjour à tous, nous y allons depuis septembre. L''équipe est stable toute l''année, et les enfants appellent les animateurs par leur prénom dès octobre. Les activités changent chaque semaine sans se répéter. À savoir : les inscriptions ferment le vendredi, et c''est souvent complet dès le jeudi soir.',
   'Le registre reste cordial et l''information gagne en précision, sans qu''aucune personne ne soit visée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S8 / INSUFFICIENT
  ('aad3cb04-288a-5d48-ac2d-b84458d18c6f', '24eed41d-9cc6-50e2-8703-c63027ebc687', 'INSUFFICIENT',
   'Salut ! Trop content de te lire. Alors la nana qui faisait la visite, franchement elle assurait grave, elle connaît son truc. Par contre elle parlait vite, j''ai galéré sur la fin. Merci du tuyau en tout cas, c''était top ! Faudra qu''on se capte un de ces quatre pour en discuter.',
   'Le tutoiement rompt l''usage installé entre vous, et « la nana », « elle assurait grave », « j''ai galéré » détonnent complètement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S8 / EXPECTED
  ('ca75d9d8-62be-5d3d-ae6d-237c6e2aa87e', '24eed41d-9cc6-50e2-8703-c63027ebc687', 'EXPECTED',
   'Bonjour Madame, j''ai suivi sa visite samedi et je vous remercie de me l''avoir conseillée. Elle connaît remarquablement son sujet et répond à toutes les questions sans jamais se dérober. Elle parle un peu vite dans la dernière salle, mais l''ensemble était passionnant.',
   'Vouvoiement chaleureux, avis argumenté, réserve exprimée sans dureté : le registre est parfaitement tenu.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S8 / EXCELLENT
  ('0a070eaf-63c4-5640-bed3-2581716954f1', '24eed41d-9cc6-50e2-8703-c63027ebc687', 'EXCELLENT',
   'Bonjour Madame, j''ai suivi sa visite samedi et je vous remercie de me l''avoir conseillée. Elle connaît remarquablement son sujet et n''esquive aucune question, même celles qui sortent du parcours. Elle accélère un peu dans la dernière salle — sans doute l''horaire. J''y retournerais volontiers.',
   'La réserve est nuancée par une explication bienveillante, et le registre ne varie pas d''un mot.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S9 / INSUFFICIENT
  ('2699811c-8c0e-5a98-a706-563ecc4f4be2', '1225841e-2b62-5068-b97e-a5924042f43b', 'INSUFFICIENT',
   'Ça fait dix ans qu''on demande et rien ne bouge ! Le square est dans un état lamentable, les bancs sont cassés et personne ne fait rien. Si vous voulez mon avis, il serait temps de vous réveiller avant qu''un enfant se blesse. C''est scandaleux.',
   'Le fond est peut-être juste, mais ce ton de reproche a peu de poids dans un dossier d''enquête publique.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S9 / EXPECTED
  ('174424b9-0775-52fe-9f7b-5b95276021f2', '1225841e-2b62-5068-b97e-a5924042f43b', 'EXPECTED',
   'Madame, Monsieur, je souhaite formuler un avis favorable à ce projet. Le square est aujourd''hui le seul espace vert accessible à pied depuis les immeubles de la rue Dubois. Les bancs actuels sont hors d''usage. L''ajout d''une aire ombragée répondrait à un besoin réel des familles.',
   'Registre formel, avis annoncé, arguments vérifiables : le dossier peut en tenir compte.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S9 / EXCELLENT
  ('a9074988-ff80-5075-9ef8-ebc2f246b6db', '1225841e-2b62-5068-b97e-a5924042f43b', 'EXCELLENT',
   'Madame, Monsieur, je souhaite formuler un avis favorable à ce projet. Le square est le seul espace vert accessible à pied depuis les immeubles de la rue Dubois, soit environ deux cents logements. Quatre des six bancs sont hors d''usage. Une aire ombragée y répondrait à un besoin quotidien.',
   'Les deux chiffres transforment l''avis en contribution utilisable, sans que le registre varie d''un mot.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S10 / INSUFFICIENT
  ('a9e90671-9d99-5895-b512-a0e37734ff88', '2d4c695a-1713-54da-86d6-f02c250484e4', 'INSUFFICIENT',
   'Merci beaucoup, il est magnifique, exactement ce qu''il nous fallait ! La couleur est parfaite, la taille aussi, et il va très bien avec le reste. Vraiment, vous avez eu un goût sûr, on ne pouvait pas rêver mieux pour ce salon.',
   'Elle demande votre avis franc. Cet enthousiasme sans réserve ne répond pas à sa question — et sonne faux.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S10 / EXPECTED
  ('7e1aee5d-9488-5653-92e5-b18f9bab8b7a', '2d4c695a-1713-54da-86d6-f02c250484e4', 'EXPECTED',
   'Merci beaucoup, il est arrivé hier. Le tissu est très agréable et la couleur s''accorde bien avec les rideaux. Il est honnêtement un peu grand pour la pièce, nous avons dû déplacer la table basse. Mais nous sommes très touchés d''y avoir pensé.',
   'La réserve est dite clairement, encadrée par deux appréciations sincères : franchise et ménagement tiennent ensemble.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S10 / EXCELLENT
  ('82854488-fcd2-59f2-bbf7-0018d5f78025', '2d4c695a-1713-54da-86d6-f02c250484e4', 'EXCELLENT',
   'Merci beaucoup, il est arrivé hier. Le tissu est très agréable et la couleur s''accorde parfaitement aux rideaux. Il est honnêtement un peu grand : nous avons déplacé la table basse, et finalement le salon est mieux ainsi. Nous sommes vraiment touchés que vous y ayez pensé.',
   'La réserve est maintenue mais suivie de sa résolution : rien n''est caché, et rien n''est blessant.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S11 / INSUFFICIENT
  ('a2419a18-d2ba-50fa-80e4-051f051dce90', '1b6afc3a-33d0-5db6-8142-75268ed578fd', 'INSUFFICIENT',
   'Bonjour ! Alors évitez le gros René, c''est plus ce que c''était depuis que Josiane est partie. Allez plutôt chez les Martin au bout, ceux qui ont repris après l''affaire du parking. Et si vous voyez Dédé, dites-lui que je passerai jeudi !',
   'Les prénoms et les allusions au passé du quartier sont incompréhensibles pour quelqu''un qui vient d''arriver.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S11 / EXPECTED
  ('73322e23-8967-5273-b894-32a85524c717', '1b6afc3a-33d0-5db6-8142-75268ed578fd', 'EXPECTED',
   'Bonjour et bienvenue ! Les commerçants du mardi sont pour la plupart des producteurs, pas des revendeurs. Ils acceptent qu''on goûte et ils disent franchement ce qui n''est pas encore de saison. Plusieurs se connaissent depuis des années et vous orientent vers le stand voisin sans problème.',
   'Ton accueillant, vouvoiement, et une description du groupe utilisable par quelqu''un qui n''y a aucun repère.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S11 / EXCELLENT
  ('36c27bfb-a78f-51be-8c2d-8112b10976a8', '1b6afc3a-33d0-5db6-8142-75268ed578fd', 'EXCELLENT',
   'Bonjour et bienvenue ! Les commerçants du mardi sont pour la plupart des producteurs, pas des revendeurs. Ils font goûter sans qu''on demande et vous disent franchement quand un produit n''est pas encore de saison. Ils s''envoient les clients d''un stand à l''autre — c''est ce qui m''a frappé en arrivant.',
   '« Ce qui m''a frappé en arrivant » se met à la place du nouveau venu : l''adaptation au destinataire va jusque-là.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S12 / INSUFFICIENT
  ('4013cfc2-04e1-507e-a9ba-a082ca441172', 'd9de56ca-ad99-52cf-871e-231c2136ddb8', 'INSUFFICIENT',
   'C''est une honte ! Ces gens ne font absolument rien, ils passent dix minutes et repartent. On paie une fortune pour un hall dégoûtant. Franchement, changez de prestataire ou remboursez-nous, parce que là c''est du vol pur et simple. J''attends une réponse rapide.',
   'Le reproche est peut-être fondé, mais ce ton le rend facile à écarter : rien n''y est vérifiable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S12 / EXPECTED
  ('03e371d7-2fcf-5e5f-be61-227ece829772', 'd9de56ca-ad99-52cf-871e-231c2136ddb8', 'EXPECTED',
   'Madame, Monsieur, mon avis sur cette équipe est réservé. Leur passage dure environ dix minutes pour six étages. Les vitres du hall n''ont pas été faites depuis janvier et l''ascenseur n''est jamais nettoyé. Le contrat prévoit pourtant deux passages complets par semaine. Bien cordialement.',
   'Registre mesuré, faits datés, référence au contrat : la réserve devient opposable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S12 / EXCELLENT
  ('3153158b-0c1f-5772-b557-fc9ec998808e', 'd9de56ca-ad99-52cf-871e-231c2136ddb8', 'EXCELLENT',
   'Madame, Monsieur, mon avis sur cette équipe est réservé. Leur passage dure une dizaine de minutes pour six étages. Les vitres du hall n''ont pas été faites depuis janvier, la cabine d''ascenseur jamais. Le contrat prévoyant deux passages complets par semaine, l''écart me semble important. Bien cordialement.',
   '« L''écart me semble important » laisse la conclusion au destinataire : c''est plus fort qu''une accusation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S13 / INSUFFICIENT
  ('518c287e-d7a6-5bfb-8016-7da9b59ebb50', 'b3895052-d0b0-5b7a-8e58-9baeca7a0b55', 'INSUFFICIENT',
   'Franchement ? Je l''aurais jamais prise. Le coffre est minuscule, la consommation est délirante et la revente sera catastrophique dans trois ans. Tu aurais dû m''écouter quand je te disais de regarder l''autre modèle. Enfin bon, c''est fait, on n''en parle plus.',
   'L''honnêteté tourne au reproche sur un achat déjà fait : le ton ne tient pas compte de la situation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S13 / EXPECTED
  ('3a04a2ee-e7e9-50e6-8f32-870207b87b91', 'b3895052-d0b0-5b7a-8e58-9baeca7a0b55', 'EXPECTED',
   'Je l''ai vue hier soir. La position de conduite est vraiment confortable et le coffre est plus grand qu''il n''en a l''air. La finition intérieure est soignée. Elle consomme un peu plus que ce que tu espérais, mais pour tes trajets courts cela ne changera pas grand-chose.',
   'La réserve est dite, puis remise à sa juste place au regard de son usage réel : honnête sans blesser.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S13 / EXCELLENT
  ('9a948ed1-7bdd-5e54-8836-fe7d465a714e', 'b3895052-d0b0-5b7a-8e58-9baeca7a0b55', 'EXCELLENT',
   'Je l''ai vue hier soir. La position de conduite est vraiment confortable et le coffre plus grand qu''il n''en a l''air. La finition m''a surpris en bien. Elle consomme un peu plus que tu ne l''espérais — mais sur tes quinze kilomètres par jour, on parle de quelques euros par mois.',
   'Le chiffrage désamorce la réserve sans la nier : c''est exactement l''adaptation au fait que l''achat est déjà fait.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S14 / INSUFFICIENT
  ('6432dd3c-034b-59ea-80e9-39b64cdc13d7', '10b994a8-831e-5ab6-9f42-08ea13e00d19', 'INSUFFICIENT',
   'Bonjour, personnellement je déteste ces nouveaux bureaux. Je ne supporte pas l''open space, je n''arrive pas à me concentrer et j''ai mal au dos depuis qu''on a changé de chaises. J''espère qu''on va revenir en arrière rapidement, c''était mieux avant.',
   'Vous parlez au nom de l''équipe et ne donnez que votre ressenti : le registre du mandat n''est pas tenu.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S14 / EXPECTED
  ('757f7a66-c6eb-5835-b8a0-c51474072a7f', '10b994a8-831e-5ab6-9f42-08ea13e00d19', 'EXPECTED',
   'Bonjour, voici l''avis recueilli auprès de l''équipe. La lumière naturelle et l''espace de circulation font l''unanimité. En revanche, huit personnes sur douze signalent des difficultés de concentration liées au bruit. Deux demandent des cloisons acoustiques. Personne ne souhaite revenir aux anciens locaux.',
   'Chiffres, nuances, et une conclusion qui rend compte du groupe entier : le mandat est respecté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S14 / EXCELLENT
  ('783e0988-7708-5a56-95c1-95c7e0c404a4', '10b994a8-831e-5ab6-9f42-08ea13e00d19', 'EXCELLENT',
   'Bonjour, voici l''avis recueilli auprès de l''équipe. La lumière et l''espace de circulation font l''unanimité. Huit personnes sur douze signalent des difficultés de concentration liées au bruit, dont deux demandent des cloisons acoustiques. Personne ne souhaite revenir aux anciens locaux, y compris parmi les plus critiques.',
   '« Y compris parmi les plus critiques » rend compte de la position du groupe avec une honnêteté que le registre exige.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S15 / INSUFFICIENT
  ('353038f1-e0e9-5777-9807-51369d2dfdaf', 'dfd36fe8-9f69-5225-b8ca-bf94b741d9d5', 'INSUFFICIENT',
   'Bonjour, c''est quelqu''un de très bien, prenez-le les yeux fermés. Enfin, disons qu''il a eu quelques soucis avec l''ancienne direction mais bon, chacun sait ce qu''il en était vraiment. En tout cas moi je le recommande, il ne vous décevra pas.',
   'L''allusion aux « soucis » sans rien préciser est plus nuisible qu''un reproche clair : ce registre ne convient pas à une décision.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S15 / EXPECTED
  ('93a48059-1f0a-58ed-b5c4-7647d1a637fd', 'dfd36fe8-9f69-5225-b8ca-bf94b741d9d5', 'EXPECTED',
   'Bonjour, j''ai travaillé six mois avec lui sur le même projet. Il tient ses délais et signale les difficultés tôt plutôt que de les laisser s''installer. Il est moins à l''aise à l''oral devant un groupe. Sur un poste technique, je le recommande sans réserve.',
   'Faits, limite énoncée franchement, recommandation circonscrite : le registre convient à une parole qui engage.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9-S15 / EXCELLENT
  ('a9b4fa71-08cd-5527-907a-27e678d2f310', 'dfd36fe8-9f69-5225-b8ca-bf94b741d9d5', 'EXCELLENT',
   'Bonjour, j''ai travaillé six mois avec lui sur le même projet. Il tient ses délais et signale les difficultés tôt, avant qu''elles ne coûtent cher. Il est moins à l''aise à l''oral devant un groupe, ce qui n''a jamais gêné notre travail. Sur un poste technique, je le recommande sans réserve.',
   'La limite est située dans son contexte au lieu d''être laissée nue : l''avis engage sans desservir.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S16 / INSUFFICIENT
  ('036ce5ad-6402-58ef-98d1-9c5a4f1f4bf5', '0c27c9b6-255b-5487-a61f-8401ac94c0a6', 'INSUFFICIENT',
   'Cette bibliothèque est un vrai atout. Les collections sont riches et l''espace de travail est agréable. Cela dit, les horaires sont vraiment impossibles et la fermeture du lundi est absurde. Finalement je comprends ceux qui n''y vont plus, c''est peut-être eux qui ont raison.',
   'La concession emporte tout : la position de départ est abandonnée à la dernière phrase.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S16 / EXPECTED
  ('5eea428b-2981-58b1-a2f7-db00ecf8b3cc', '0c27c9b6-255b-5487-a61f-8401ac94c0a6', 'EXPECTED',
   'Cette bibliothèque est un vrai atout. Les collections sont riches et l''espace de travail reste calme même le samedi. Il est vrai que la fermeture du lundi gêne beaucoup de gens. Cela reste pour moi le meilleur endroit du quartier pour travailler.',
   'La limite est reconnue franchement, et la position tient jusqu''à la dernière phrase.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S16 / EXCELLENT
  ('cbc6b714-76fa-54fe-81bd-4327fd1cf259', '0c27c9b6-255b-5487-a61f-8401ac94c0a6', 'EXCELLENT',
   'Cette bibliothèque est un vrai atout. Les collections sont riches et l''espace de travail reste calme même le samedi après-midi. Il est vrai que la fermeture du lundi gêne ceux qui travaillent le week-end — c''est un vrai manque. Elle reste malgré tout le seul endroit du quartier où l''on peut travailler des heures.',
   'La concession est prise au sérieux (« c''est un vrai manque ») et la position n''en est que plus solide.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S17 / INSUFFICIENT
  ('2809833c-2804-52ac-8e8c-3bb41cbcd883', 'ec9b7221-c7e2-5977-b1f3-3ac02d996ebe', 'INSUFFICIENT',
   'Ce téléphone est un très bon achat. Il fonctionne parfaitement et l''écran est impeccable. Après, c''est vrai que la batterie est fatiguée, il faut le recharger deux fois par jour, et l''appareil photo est moyen. Bon, honnêtement, mieux vaut peut-être acheter neuf.',
   'Deux concessions s''accumulent et la position se retourne : le candidat finit par recommander le contraire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S17 / EXPECTED
  ('86747f83-d6e4-5fdc-8233-c8e0106cb8df', 'ec9b7221-c7e2-5977-b1f3-3ac02d996ebe', 'EXPECTED',
   'Ce téléphone est un très bon achat. Il fonctionne parfaitement, l''écran est impeccable et il m''a coûté trois fois moins cher qu''un neuf. Il est vrai que la batterie tient moins bien en fin de journée. Cela ne m''empêche pas de le recommander.',
   'Une seule concession, exacte, encadrée par des arguments : la position reste nette.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S17 / EXCELLENT
  ('0019e524-6b70-51df-b6e4-ad74781a3dee', 'ec9b7221-c7e2-5977-b1f3-3ac02d996ebe', 'EXCELLENT',
   'Ce téléphone est un très bon achat. Il fonctionne parfaitement, l''écran est impeccable, et il m''a coûté trois fois moins cher qu''un neuf. La batterie tient effectivement moins bien en fin de journée — j''ai pris un chargeur pour le bureau. Pour cet écart de prix, je referais le même choix.',
   'La concession est suivie de ce que le candidat en fait, ce qui montre qu''elle a été réellement pesée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S18 / INSUFFICIENT
  ('4e6cf9d6-7a31-5ce8-b7da-8a348665f8c1', 'edeaff78-eb68-594b-a0c0-79f92aa86ef4', 'INSUFFICIENT',
   'Ce coach est excellent. Il connaît son métier et les résultats sont là. Bon après c''est vrai qu''il est dur, il ne lâche rien et certains abandonnent au bout de trois séances. Franchement, si tu es débutante, tu devrais peut-être aller voir ailleurs.',
   'La concession se transforme en déconseil : la position initiale ne survit pas à la dernière phrase.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S18 / EXPECTED
  ('e82c173d-b375-517b-9b9f-8675eae09ba0', 'edeaff78-eb68-594b-a0c0-79f92aa86ef4', 'EXPECTED',
   'Ce coach est excellent. Il adapte chaque séance et il explique pourquoi on fait chaque mouvement. Il est effectivement exigeant : il ne laisse pas terminer une série à moitié. Cela demande de s''accrocher les premières semaines, mais c''est exactement ce qui m''a fait progresser.',
   'La limite est décrite précisément, puis reliée au bénéfice : la position sort renforcée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S18 / EXCELLENT
  ('707b7593-cf5a-5c8b-9ad6-7e31b5ac085b', 'edeaff78-eb68-594b-a0c0-79f92aa86ef4', 'EXCELLENT',
   'Ce coach est excellent. Il adapte chaque séance et explique le pourquoi de chaque mouvement. Il est effectivement exigeant — il ne laisse jamais terminer une série à moitié, et j''ai détesté cela les trois premières semaines. C''est pourtant précisément là que j''ai commencé à progresser.',
   'Le candidat reconnaît son propre agacement passé : la concession est sincère et la position n''en bouge pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S19 / INSUFFICIENT
  ('27dc43d5-b580-5d7e-acb7-a5bd0f213563', '167752eb-1a1f-5e22-a78c-b7d33403edd4', 'INSUFFICIENT',
   'Cette équipe fait un travail essentiel. Ils servent cent repas par jour avec très peu de moyens. Cela dit, c''est vrai que l''accueil est sec et que certains bénévoles parlent mal aux gens. Au fond, je comprends les plaintes, il faudrait peut-être revoir toute l''équipe.',
   'La concession va jusqu''à proposer de remplacer l''équipe : la position de départ a disparu.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S19 / EXPECTED
  ('5dba5de5-5048-5ae6-9396-2c63f5478740', '167752eb-1a1f-5e22-a78c-b7d33403edd4', 'EXPECTED',
   'Cette équipe fait un travail essentiel. Ils servent cent repas par jour avec très peu de moyens et n''ont jamais refusé personne. Il est vrai que l''accueil peut sembler brusque aux heures de pointe. Cela ne retire rien à ce qu''ils accomplissent chaque midi.',
   'La limite est reconnue et située dans son contexte, sans que la position s''affaisse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S19 / EXCELLENT
  ('d0a04a7d-b811-5ef3-a6b8-c3283bfdd5a4', '167752eb-1a1f-5e22-a78c-b7d33403edd4', 'EXCELLENT',
   'Cette équipe fait un travail essentiel. Cent repas par jour avec très peu de moyens, et personne n''est jamais refusé. Il est vrai que l''accueil paraît brusque entre midi et treize heures — je l''ai trouvé sec la première fois. En connaissant la charge, mon avis n''a pas changé d''un mot.',
   'Le candidat reconnaît avoir partagé le reproche, puis explique ce qui l''a fait tenir sa position.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S20 / INSUFFICIENT
  ('f3916f70-c589-5aca-85d1-c88e2f20635a', '59d5d273-7015-52b1-9fe2-4cb9e289ed11', 'INSUFFICIENT',
   'Ce camping est un endroit rare. La vue est magnifique et le silence total. Après, il faut reconnaître qu''il n''y a ni électricité ni eau chaude, que les sanitaires sont sommaires et qu''il faut vingt minutes de piste. Franchement, pour des vacances en famille, ce n''est pas raisonnable.',
   'Trois concessions s''empilent et la conclusion déconseille le lieu : la position initiale est renversée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S20 / EXPECTED
  ('8b809b13-2350-5543-ab9e-3824656801b0', '59d5d273-7015-52b1-9fe2-4cb9e289ed11', 'EXPECTED',
   'Ce camping est un endroit rare. La vue sur la vallée et le silence n''existent nulle part ailleurs dans la région. Il est vrai que les sanitaires sont sommaires et qu''il n''y a pas d''eau chaude. Pour trois nuits, cela ne m''a jamais posé de problème.',
   'La concession est nette et la position se maintient, précisée par une durée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S20 / EXCELLENT
  ('1cb1ed10-fb20-54c3-8805-cf308d089611', '59d5d273-7015-52b1-9fe2-4cb9e289ed11', 'EXCELLENT',
   'Ce camping est un endroit rare. La vue sur la vallée et le silence n''existent nulle part ailleurs ici. Les sanitaires sont effectivement sommaires et il n''y a pas d''eau chaude — c''est d''ailleurs pour cela qu''on n''y croise jamais plus de dix tentes. Pour trois nuits, c''est un échange que je referai.',
   'La limite devient l''explication de la qualité louée : la concession renforce la position au lieu de la fragiliser.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S21 / INSUFFICIENT
  ('5925cbad-e665-55b8-925b-385c5e115865', '6aa23cad-fe3f-544e-a6e1-0da7f1d4fcd3', 'INSUFFICIENT',
   'Je le recommande vraiment. Il est parfaitement imperméable et les coutures sont impeccables. Enfin, il est lourd, il prend de la place dans un sac, et il ne respire pas du tout. En fait, maintenant que j''y pense, prends plutôt un modèle plus léger.',
   'Le candidat finit par conseiller autre chose : sa position s''est inversée en cinq lignes.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S21 / EXPECTED
  ('a3a64db9-3ca1-5b0c-9778-eb0b80781f98', '6aa23cad-fe3f-544e-a6e1-0da7f1d4fcd3', 'EXPECTED',
   'Je le recommande vraiment. Il m''a gardée au sec pendant une heure de pluie battante, épaules comprises, et les coutures sont étanches. Il est vrai qu''il est lourd, environ un kilo. Pour les jours où il pleut sérieusement, c''est un poids que j''accepte volontiers.',
   'Le défaut est chiffré et assumé, puis remis à sa place : la position ne bouge pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S21 / EXCELLENT
  ('52120c3c-c87b-5737-96c5-e524b157d1c8', '6aa23cad-fe3f-544e-a6e1-0da7f1d4fcd3', 'EXCELLENT',
   'Je le recommande vraiment. Une heure sous une pluie battante et je suis rentrée sèche, épaules comprises. Il est vrai qu''il pèse près d''un kilo — c''est le prix d''un tissu qui tient vraiment. Les jours de bruine je prends autre chose, mais pour les vraies averses je ne changerais pas.',
   'Le candidat délimite précisément le domaine de validité de son avis : c''est la nuance la mieux maîtrisée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S22 / INSUFFICIENT
  ('a7884c83-5d9d-5a63-a14e-b709f17f8934', 'aacc409f-e7c3-5d53-973b-b6b23234bcaa', 'INSUFFICIENT',
   'Je le conseille sans hésiter. Il est très compétent et prend le temps d''écouter. Après, c''est vrai que sans rendez-vous on attend parfois deux heures, que la salle est bondée et qu''on ne sait jamais quand on passera. À bien y réfléchir, c''est peut-être trop contraignant.',
   'Trois concessions puis un revirement : « c''est peut-être trop contraignant » annule la recommandation.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S22 / EXPECTED
  ('403cadfd-bf82-569a-b173-e53d9905f158', 'aacc409f-e7c3-5d53-973b-b6b23234bcaa', 'EXPECTED',
   'Je le conseille sans hésiter. Il prend vraiment le temps et n''expédie jamais une consultation. Il est vrai que l''absence de rendez-vous oblige parfois à attendre longtemps. C''est aussi ce qui permet d''être vu le jour même quand on en a besoin, et cela compte beaucoup.',
   'La limite est reconnue et retournée en contrepartie réelle, sans que la position varie.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S22 / EXCELLENT
  ('a6be3c32-11e3-57c7-a301-80dc8c7a3083', 'aacc409f-e7c3-5d53-973b-b6b23234bcaa', 'EXCELLENT',
   'Je le conseille sans hésiter. Il prend le temps et n''expédie jamais personne — c''est d''ailleurs pour cela que la salle est pleine. L''attente peut atteindre deux heures, je ne le cache pas. Mais on est vu le jour même, ce qu''aucun cabinet sur rendez-vous ne propose ici.',
   'La cause du défaut est la qualité louée : le candidat le montre explicitement, et sa position devient inattaquable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S23 / INSUFFICIENT
  ('7ea63412-38e5-5de8-aebf-1e0792083cf5', '3c353f7c-cf9d-535f-93c7-83055fe04a4e', 'INSUFFICIENT',
   'Ce groupe vaut vraiment le coup. Ils sont accueillants et personne n''est laissé derrière. Bon, ils partent à sept heures le dimanche, ce qui est très tôt, et il faut être à l''heure sinon ils ne t''attendent pas. Honnêtement, à ta place, je n''irais pas.',
   'La conclusion contredit l''ouverture : « à ta place, je n''irais pas » efface toute la position.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S23 / EXPECTED
  ('35be7cf2-e2a7-5dfc-ba62-5051d55630a6', '3c353f7c-cf9d-535f-93c7-83055fe04a4e', 'EXPECTED',
   'Ce groupe vaut vraiment le coup. Ils sont accueillants et un coureur ferme toujours la file. Il est vrai que le départ à sept heures est difficile le dimanche. C''est aussi ce qui fait qu''on court au frais et qu''on rentre avant que la journée commence.',
   'La contrainte est reconnue, puis reliée à ce qu''elle permet : la position tient.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S23 / EXCELLENT
  ('3e1ca28c-56c3-5330-9699-cb5b53ddcf67', '3c353f7c-cf9d-535f-93c7-83055fe04a4e', 'EXCELLENT',
   'Ce groupe vaut vraiment le coup. Ils sont accueillants et un coureur ferme toujours la file. Le départ à sept heures est difficile, je ne vais pas prétendre le contraire — les trois premiers dimanches ont été durs. On court au frais et on rentre à neuf heures avec la journée devant soi.',
   'L''aveu de la difficulté vécue rend la concession crédible, et le bénéfice final n''en est que plus convaincant.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S24 / INSUFFICIENT
  ('04aeaf3c-2c01-5cb9-b5fb-ce216854259a', '7748002a-bfac-55da-aada-414b2ea1c2a9', 'INSUFFICIENT',
   'Cette salle est la meilleure de la ville. L''acoustique est exceptionnelle et on voit la scène de partout. Bon après, l''escalier est raide, il n''y a pas d''ascenseur et c''est inaccessible en fauteuil. Du coup non, en fait, on ne peut pas vraiment la recommander à tout le monde.',
   'La concession retourne l''avis : « on ne peut pas vraiment la recommander » annule la première phrase.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S24 / EXPECTED
  ('17cf5ff0-ba1f-5420-8d2c-0294f980df44', '7748002a-bfac-55da-aada-414b2ea1c2a9', 'EXPECTED',
   'Cette salle est la meilleure de la ville. L''acoustique est exceptionnelle et la scène se voit depuis n''importe quel point. Il est vrai que l''escalier raide la rend inaccessible aux personnes à mobilité réduite, et c''est un vrai défaut que rien ne compense. Pour qui peut y descendre, elle reste sans équivalent.',
   'La limite est reconnue sans être minimisée, et la position est explicitement bornée à qui elle s''applique.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S24 / EXCELLENT
  ('1cd6f37d-750a-5f27-a0ae-0122a0723f2d', '7748002a-bfac-55da-aada-414b2ea1c2a9', 'EXCELLENT',
   'Cette salle est la meilleure de la ville. L''acoustique est exceptionnelle et la scène se voit de partout. L''escalier raide la rend inaccessible en fauteuil : c''est un défaut réel, que l''acoustique ne rachète pas. Pour ceux qui peuvent descendre, elle reste sans équivalent dans la région.',
   '« Que l''acoustique ne rachète pas » refuse la fausse compensation : c''est la forme la plus honnête de la concession.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S25 / INSUFFICIENT
  ('208eecb8-14df-50cc-956e-90e24131a26d', '27ed707b-7e56-5496-bac1-eee9d3033a6f', 'INSUFFICIENT',
   'Ce vélo a changé mes trajets. Je fais quinze kilomètres sans transpirer et les côtes ne comptent plus. Mais bon, il pèse une tonne, impossible de le monter chez moi, et si la batterie lâche c''est fini. Réflexion faite, ce n''est pas si pratique que ça.',
   'Le revirement final — « pas si pratique que ça » — annule l''argument d''ouverture.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S25 / EXPECTED
  ('ef07a795-afbb-5627-a537-be8fddc905e6', '27ed707b-7e56-5496-bac1-eee9d3033a6f', 'EXPECTED',
   'Ce vélo a changé mes trajets. Je fais quinze kilomètres sans transpirer et les côtes ne comptent plus. Il est vrai qu''il pèse vingt-trois kilos, ce qui rend impossible de le monter à l''étage. Un local à vélos au rez-de-chaussée résout le problème, et je ne reviendrais pas en arrière.',
   'La limite est chiffrée, sa condition de contournement donnée, et la position réaffirmée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S25 / EXCELLENT
  ('267c1785-662c-5087-84f5-9b9d3057f0ab', '27ed707b-7e56-5496-bac1-eee9d3033a6f', 'EXCELLENT',
   'Ce vélo a changé mes trajets : quinze kilomètres sans transpirer et les côtes ne comptent plus. Il pèse vingt-trois kilos, donc le monter à l''étage est exclu — c''est éliminatoire si on n''a pas de local au rez-de-chaussée. J''en ai un, et je ne reviendrais pour rien au monde en arrière.',
   'Le candidat dit franchement pour qui sa recommandation ne vaut pas, sans renoncer à la sienne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S26 / INSUFFICIENT
  ('4c6e7426-01dd-5d18-b543-586e9b00bd44', '7c627567-c965-513f-a7c8-4480326b74cc', 'INSUFFICIENT',
   'Je maintiens tout à fait. Elle est très compétente et elle connaît parfaitement les dossiers. Ceci dit, c''est vrai qu''elle ne répond jamais au téléphone, qu''elle met une semaine à rappeler et qu''on ne sait jamais où elle est. Au fond, je comprends qu''on s''en plaigne.',
   '« Je comprends qu''on s''en plaigne » finit par donner raison au reproche : la position ne tient plus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S26 / EXPECTED
  ('b57b4705-59c2-54d7-aefc-d0b4cfae5b15', '7c627567-c965-513f-a7c8-4480326b74cc', 'EXPECTED',
   'Je maintiens tout à fait. Elle connaît les dossiers dans le détail et n''a jamais laissé passer une échéance. Il est vrai qu''elle répond rarement du premier coup. Elle rappelle toujours dans les deux jours, et quand elle rappelle, tout est déjà réglé.',
   'La limite est reconnue, mais précisée d''une façon qui la relativise sans la nier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S26 / EXCELLENT
  ('591ccfed-128e-5c5e-b8dc-b5917e32a8c4', '7c627567-c965-513f-a7c8-4480326b74cc', 'EXCELLENT',
   'Je maintiens tout à fait. Elle connaît les dossiers dans le détail et n''a jamais laissé passer une échéance. Elle répond rarement du premier coup, c''est exact, et cela peut agacer. Mais quand elle rappelle, deux jours plus tard, le dossier est traité — je préfère cela à dix appels sans résultat.',
   'Le candidat reconnaît même l''agacement légitime, puis oppose une comparaison qui soutient sa position.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S27 / INSUFFICIENT
  ('ff4f87b1-a3c1-581f-a7e9-b3c05ce63074', '4864a4a8-4d3a-5076-9de0-20aa519affaa', 'INSUFFICIENT',
   'Cette équipe mérite d''être soutenue. Ils récupèrent des tonnes d''objets et les remettent en état. Mais c''est vrai que rien n''est rangé, qu''on ne sait jamais qui fait quoi et que les horaires changent sans prévenir. Franchement, tant que ça ne sera pas structuré, je ne sais pas si ça vaut la peine.',
   'La position se dissout : le soutien annoncé devient un doute sur l''intérêt même de l''activité.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S27 / EXPECTED
  ('14f3d6eb-2e46-54a9-bd0a-3aee147d91ac', '4864a4a8-4d3a-5076-9de0-20aa519affaa', 'EXPECTED',
   'Cette équipe mérite d''être soutenue. Ils ont remis en état six cents objets l''an dernier, tous revendus à petit prix. Il est vrai que l''organisation est approximative et que les horaires varient. Cela n''enlève rien à ce qu''ils sortent de la benne chaque semaine.',
   'Un chiffre ancre la position, la concession est franche, et la conclusion revient au résultat.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S27 / EXCELLENT
  ('8913f007-eff5-57ac-bf88-c021e1747cde', '4864a4a8-4d3a-5076-9de0-20aa519affaa', 'EXCELLENT',
   'Cette équipe mérite d''être soutenue. Six cents objets remis en état l''an dernier, tous revendus à petit prix. L''organisation est effectivement approximative et les horaires varient — c''est le prix d''une équipe entièrement bénévole. Rien de tout cela ne sortirait de la benne sans eux.',
   'La limite est expliquée par la nature du groupe, puis dépassée par une conclusion qui ne se discute pas.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S28 / INSUFFICIENT
  ('3641e291-64a4-55db-821c-569d1dcc072b', 'e540ed23-0644-5b0a-ae0e-37bf2d95a9e5', 'INSUFFICIENT',
   'Ce sentier est à faire absolument. Les vues sur la mer sont magnifiques du début à la fin. Après, il n''y a pas un arbre, le vent souffle en permanence et en été c''est irrespirable. Tout bien pesé, il vaut mieux aller marcher en forêt.',
   'La conclusion envoie ailleurs : l''avis initial ne survit pas à la concession.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S28 / EXPECTED
  ('08707ec8-4c09-501a-97d5-6195afe16862', 'e540ed23-0644-5b0a-ae0e-37bf2d95a9e5', 'EXPECTED',
   'Ce sentier est à faire absolument. Les vues sur la mer sont continues, ce qui est rare sur ce littoral. Il est vrai qu''il n''offre aucune ombre et que le vent y souffle presque toujours. En mai ou en septembre, cela devient au contraire très agréable.',
   'La limite est reconnue, puis désamorcée par une condition précise, sans que l''avis change.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S28 / EXCELLENT
  ('c8cac6c3-bd8f-5869-9eef-8a07c4e1c34f', 'e540ed23-0644-5b0a-ae0e-37bf2d95a9e5', 'EXCELLENT',
   'Ce sentier est à faire absolument. Les vues sur la mer sont continues, ce qui est rare sur ce littoral. Il n''y a pas un arbre et le vent souffle presque toujours — en juillet, c''est effectivement à déconseiller. En mai ou en septembre, ce même vent devient la meilleure raison d''y aller.',
   'Le candidat concède un cas où il déconseille, puis retourne la limite en qualité : la nuance est complète.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S29 / INSUFFICIENT
  ('80222c10-d221-594e-9698-dc86ded576eb', '539773f4-4a92-54ff-aaa4-7a361ea55e72', 'INSUFFICIENT',
   'Je la reprendrais sans hésiter. Le bois est magnifique et elle est très solide. Cela dit, elle marque au moindre verre, il faut la huiler deux fois par an et les traces ne partent jamais complètement. Avec des enfants, honnêtement, je te la déconseille.',
   'La dernière phrase déconseille l''achat : la position d''ouverture est abandonnée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S29 / EXPECTED
  ('846fa8f9-6135-5ebc-86f0-59c7f1b7fb55', '539773f4-4a92-54ff-aaa4-7a361ea55e72', 'EXPECTED',
   'Je la reprendrais sans hésiter. Le bois est magnifique et le plateau n''a pas bougé en cinq ans. Il est vrai qu''elle marque : un verre humide laisse un rond. Ces traces finissent par former une patine que je trouve plus belle que le neuf.',
   'La limite est décrite précisément, puis réinterprétée sans être niée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S29 / EXCELLENT
  ('b042d9c2-4efe-59fa-8548-e5ab0036bb68', '539773f4-4a92-54ff-aaa4-7a361ea55e72', 'EXCELLENT',
   'Je la reprendrais sans hésiter. Le bois est magnifique et le plateau n''a pas bougé en cinq ans. Elle marque, c''est vrai : un verre humide laisse un rond, et il reste. Si tu veux une table qui garde l''air neuf, prends autre chose. Si les traces ne te dérangent pas, elle vieillira très bien.',
   'Le candidat dit clairement pour qui son avis ne vaut pas, sans renoncer une seconde au sien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S30 / INSUFFICIENT
  ('c851df8e-b772-591f-942f-6d12641d0fd3', 'b1e9ac7c-84bb-53b9-9c32-b85861416295', 'INSUFFICIENT',
   'C''est vrai, et je le conseille quand même. Il est très compétent. Mais effectivement il ne touche pas au vélo, il te regarde faire pendant une heure et il faut tout démonter soi-même. Si tu es pressé, va plutôt chez un réparateur, ce sera plus simple.',
   'La conclusion redirige vers un réparateur : le conseil initial est retiré.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S30 / EXPECTED
  ('adf77609-1d57-5c60-8ad3-0f858f007a65', 'b1e9ac7c-84bb-53b9-9c32-b85861416295', 'EXPECTED',
   'C''est vrai, et je le conseille quand même. Il ne prend jamais l''outil à votre place : il explique, montre une fois, puis vous laisse faire. Cela prend deux fois plus de temps qu''une réparation classique. En revanche, on sait refaire seul la fois suivante.',
   'La limite est confirmée sans détour, puis reliée au bénéfice qui la justifie.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C7-S30 / EXCELLENT
  ('cf1459cb-1f2a-5568-8465-669f4b153d8d', 'b1e9ac7c-84bb-53b9-9c32-b85861416295', 'EXCELLENT',
   'C''est vrai, et je le conseille quand même. Il ne prend jamais l''outil à votre place : il explique, montre une fois, puis regarde. Cela prend deux heures là où un réparateur en met vingt minutes. Mais j''ai changé ma chaîne seul le mois dernier — et c''est exactement ce que j''étais venu chercher.',
   'La concession est chiffrée et le bénéfice prouvé par un fait : la position devient impossible à contester.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S16 / INSUFFICIENT
  ('1876343a-7fc9-5c4c-8e92-734cd4de40fb', 'd13dee17-9e2e-545e-951b-f470dc2efc4e', 'INSUFFICIENT',
   'Ce gymnase est bien tenu. Le sol est refait. Les vestiaires sont propres. Le chauffage fonctionne. Les horaires sont larges. Le parking est suffisant. Les paniers sont réglables. Pour conclure, en conclusion finale, je dirais que ce gymnase est bien tenu au total.',
   'Six phrases juxtaposées, puis une conclusion lourde et redondante qui ne fait que répéter la première phrase.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S16 / EXPECTED
  ('41fc18de-6932-555c-a090-f17a549fdd39', 'd13dee17-9e2e-545e-951b-f470dc2efc4e', 'EXPECTED',
   'Ce gymnase est bien tenu. Le sol a été refait l''an dernier, ce qui a supprimé les glissades dans l''angle nord. Les vestiaires suivent : ils sont nettoyés après chaque créneau. Et comme le chauffage fonctionne enfin, on n''arrive plus une heure avant pour s''échauffer.',
   '« Ce qui », « suivent », « et comme » : chaque idée s''accroche à la précédente, et rien ne conclut artificiellement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S16 / EXCELLENT
  ('f408c761-7e37-52b3-9569-cfc29e2a0a28', 'd13dee17-9e2e-545e-951b-f470dc2efc4e', 'EXCELLENT',
   'Ce gymnase est bien tenu. Le sol refait l''an dernier a supprimé les glissades de l''angle nord, où deux joueurs s''étaient blessés. Les vestiaires suivent la même logique : nettoyage après chaque créneau, sans exception. Et depuis que le chauffage fonctionne, plus personne n''arrive une heure avant pour s''échauffer.',
   '« La même logique » relie deux idées par un principe commun, ce qui est l''enchaînement le plus fort.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S17 / INSUFFICIENT
  ('9cb5e860-541d-52eb-b175-8673e649e9cb', 'f0d5ec61-3a43-5cb7-808c-961fb3049e20', 'INSUFFICIENT',
   'Je le garde parce qu''il marche encore. Il est en métal. Le fil est intact. Les ressorts fonctionnent. Il grille bien. Il est facile à nettoyer. Il a vingt ans. En conclusion pour finir, voilà pourquoi je le garde, en conclusion.',
   'Six phrases sans lien, puis une conclusion doublement redondante : « en conclusion pour finir… en conclusion ».', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S17 / EXPECTED
  ('cea5fafc-e7a1-5fef-bfed-f25abcf7328b', 'f0d5ec61-3a43-5cb7-808c-961fb3049e20', 'EXPECTED',
   'Je le garde parce qu''il marche encore. Son boîtier est en métal, donc rien ne s''est déformé avec la chaleur. Les ressorts tiennent toujours, contrairement aux modèles récents que j''ai vus casser en deux ans. Et comme il se démonte, je peux le nettoyer vraiment.',
   '« Donc », « contrairement à », « et comme » : les idées se répondent et le texte s''arrête là où il a fini.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S17 / EXCELLENT
  ('eb7c0bb0-43ec-57ff-a2ac-9a920f608142', 'f0d5ec61-3a43-5cb7-808c-961fb3049e20', 'EXCELLENT',
   'Je le garde parce qu''il marche encore. Son boîtier en métal n''a pas bougé, là où le plastique se déforme en quelques années. Les ressorts tiennent toujours — j''ai vu deux modèles récents casser en moins de deux ans chez ma sœur. Et il se démonte, donc il se nettoie vraiment.',
   'Chaque idée s''appuie sur la précédente par opposition ou par conséquence, et la dernière referme sans l''annoncer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S18 / INSUFFICIENT
  ('647466b2-278d-5e28-b7d8-909cfab7333e', '0c569c16-eeaf-5680-beb6-55896d624f2a', 'INSUFFICIENT',
   'Cette infirmière est excellente. Elle arrive à l''heure. Elle prévient si elle a du retard. Elle explique les soins. Elle note tout dans le carnet. Elle est douce. Elle parle à ma mère. Pour finir en conclusion, elle est excellente comme je l''ai dit.',
   'Six affirmations empilées et une conclusion qui recopie la première phrase : le texte tourne en rond.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S18 / EXPECTED
  ('b91f3b1c-2960-58df-a266-b8f74c28905f', '0c569c16-eeaf-5680-beb6-55896d624f2a', 'EXPECTED',
   'Cette infirmière est excellente. Elle arrive toujours à l''heure, et quand ce n''est pas possible elle prévient la veille. Elle explique chaque soin à ma mère plutôt qu''à moi, ce qui change tout pour elle. Elle note ensuite le déroulé dans le carnet, si bien que sa remplaçante sait exactement où en est le traitement.',
   '« Et quand », « ce qui », « ensuite », « si bien que » : chaque idée découle de la précédente.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S18 / EXCELLENT
  ('956e3a3a-0b0a-5309-830e-07b7e406e53e', '0c569c16-eeaf-5680-beb6-55896d624f2a', 'EXCELLENT',
   'Cette infirmière est excellente. Elle arrive à l''heure, et si ce n''est pas possible elle prévient la veille au soir. Elle explique chaque soin à ma mère plutôt qu''à moi — c''est ce qui lui a rendu confiance. Elle note ensuite tout dans le carnet, si bien que sa remplaçante n''a jamais eu à me poser une question.',
   'La chaîne va jusqu''à un effet inattendu — la remplaçante n''a rien à demander — sans aucune formule de clôture.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S19 / INSUFFICIENT
  ('1914bf70-37b5-5563-b3fa-46019208ad69', '58779e16-bab6-5d6e-8895-591eac7b01cc', 'INSUFFICIENT',
   'Cette équipe est très bien. Ils sont nombreux. Ils sont jeunes. Ils préparent des activités. Ils notent les allergies. Ils appellent en cas de souci. Ils font des photos. Pour conclure cette réponse, en résumé, cette équipe est vraiment très bien.',
   'Six éléments alignés, puis une double formule de clôture qui n''ajoute rien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S19 / EXPECTED
  ('c65372f8-addf-506b-8ecf-4c04a4064e70', '58779e16-bab6-5d6e-8895-591eac7b01cc', 'EXPECTED',
   'Cette équipe est très bien. Ils sont assez nombreux pour qu''aucun enfant ne reste seul dans un coin, et cela se voit dès le premier jour. Comme ils préparent les activités à l''avance, il n''y a jamais de temps mort. Ils appellent aussi dès qu''un enfant s''est fait mal, même légèrement.',
   '« Pour que », « comme », « aussi » : les idées s''articulent et le texte se referme sans l''annoncer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S19 / EXCELLENT
  ('56e44ad8-f5b0-5bf4-a7d3-4c073b16e4e1', '58779e16-bab6-5d6e-8895-591eac7b01cc', 'EXCELLENT',
   'Cette équipe est très bien. Ils sont assez nombreux pour qu''aucun enfant ne reste seul dans un coin — mon fils, qui est timide, n''a jamais mangé à l''écart. Comme les activités sont préparées la veille, il n''y a pas de temps mort après le repas, l''heure la plus difficile. Ils appellent au moindre bobo.',
   'Chaque lien est justifié par un fait, et « l''heure la plus difficile » montre que le candidat sait pourquoi cela compte.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S20 / INSUFFICIENT
  ('84f89239-fd2b-5f67-9c29-d71683e9989b', '904ccad9-82ce-5440-b2ef-b47feb08f961', 'INSUFFICIENT',
   'Ce refuge est une bonne étape. Les dortoirs sont petits. Le repas est copieux. L''eau est potable. Le gardien est présent. Le départ se fait tôt. Les couvertures sont fournies. Le gardien cuisine lui-même. La vue est belle. On paie en liquide. En conclusion finale pour terminer, c''est une bonne étape.',
   'Six phrases sans lien et une clôture à trois formules empilées, qui ne dit rien de neuf.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S20 / EXPECTED
  ('6cad1cfa-f6a0-5cf6-afcf-7edc2e92838d', '904ccad9-82ce-5440-b2ef-b47feb08f961', 'EXPECTED',
   'Ce refuge est une bonne étape. Les dortoirs ne comptent que six places, si bien qu''on dort vraiment, contrairement aux grandes salles de quarante. Le repas du soir est copieux, ce qui compte quand on repart à cinq heures. Et comme les couvertures sont fournies, on porte un sac plus léger.',
   '« Si bien que », « ce qui », « et comme » : chaque information découle de la précédente ou l''explique.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S20 / EXCELLENT
  ('f3a80fc9-15d0-56fa-8205-652f86fe7e56', '904ccad9-82ce-5440-b2ef-b47feb08f961', 'EXCELLENT',
   'Ce refuge est une bonne étape. Les dortoirs ne comptent que six places, si bien qu''on dort réellement — ce qui n''arrive jamais dans les salles de quarante. Le repas du soir est copieux, et il le faut quand on repart à cinq heures. Les couvertures étant fournies, on monte avec deux kilos de moins.',
   'Le participe et les chiffres resserrent l''enchaînement, et le texte s''arrête sur l''information la plus concrète.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S21 / INSUFFICIENT
  ('e2d11bd5-4738-5ce4-9e8c-226ee9efc4a8', '62b20725-2a99-5c45-9667-698b53279bdf', 'INSUFFICIENT',
   'Ce casque me convient très bien. Il est léger. La batterie tient. Le son est bon. Il réduit le bruit. Les coussinets sont doux. Il se plie. Pour résumer en conclusion, il me convient très bien, comme je viens de le dire.',
   'Six qualités juxtaposées et une clôture qui répète explicitement la première phrase.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S21 / EXPECTED
  ('217ab0c5-665d-515f-b5ae-16757134672a', '62b20725-2a99-5c45-9667-698b53279bdf', 'EXPECTED',
   'Ce casque me convient très bien. Il est assez léger pour que je l''oublie au bout d''une heure, alors que l''ancien me serrait les tempes. La réduction de bruit couvre les conversations de l''open space, donc je n''ai plus besoin de monter le volume. La batterie tient deux journées entières.',
   '« Alors que », « donc » : chaque qualité est reliée à un usage ou à une comparaison.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S21 / EXCELLENT
  ('7d6120fb-feeb-5b3a-8a09-9b9927ec0642', '62b20725-2a99-5c45-9667-698b53279bdf', 'EXCELLENT',
   'Ce casque me convient très bien. Il est assez léger pour que je l''oublie au bout d''une heure, là où l''ancien me serrait les tempes dès la deuxième réunion. La réduction de bruit couvre les conversations de l''open space, donc je n''ai plus à monter le volume — mes oreilles s''en portent mieux.',
   'La dernière proposition tire la conséquence de la précédente : le texte finit sur un enchaînement, pas sur une formule.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S22 / INSUFFICIENT
  ('85e7b98d-6b47-5055-9f39-819104a7aa04', '8b9de2c7-88b6-5f9a-be14-e7f6d35c7a1a', 'INSUFFICIENT',
   'Cette libraire est précieuse. Elle lit beaucoup. Elle conseille bien. Elle commande vite. Elle connaît ses clients. Elle organise des rencontres. Elle n''impose rien. Elle emballe les cadeaux. Elle ouvre le lundi. Elle a un chat dans la vitrine. Pour finir et pour conclure, je redis qu''elle est précieuse pour le quartier.',
   'Six phrases sans liaison, et une clôture qui empile deux formules pour redire la première ligne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S22 / EXPECTED
  ('c85195a5-aeae-5830-a060-949a70616758', '8b9de2c7-88b6-5f9a-be14-e7f6d35c7a1a', 'EXPECTED',
   'Cette libraire est précieuse. Elle lit vraiment ce qu''elle vend, donc ses conseils tombent juste au lieu de suivre les listes de nouveautés. Comme elle retient ce que chacun a aimé, elle propose des choses qu''on n''aurait jamais ouvertes. Et si le livre ne plaît pas, elle le reprend.',
   '« Donc », « comme », « et si » : le texte avance par conséquences, sans avoir besoin de conclure.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S22 / EXCELLENT
  ('0e16e5b3-9d52-529a-a7e4-4ad0d0c5a30c', '8b9de2c7-88b6-5f9a-be14-e7f6d35c7a1a', 'EXCELLENT',
   'Cette libraire est précieuse. Elle lit ce qu''elle vend, donc ses conseils tombent juste au lieu de suivre les piles de nouveautés. Comme elle retient ce que chacun a aimé, elle propose des livres qu''on n''aurait jamais ouverts — c''est ainsi que j''ai découvert trois auteurs cette année. Et si cela ne plaît pas, elle reprend le livre.',
   'L''enchaînement produit une preuve au milieu du texte, ce qui vaut mieux que n''importe quelle conclusion.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S23 / INSUFFICIENT
  ('d510ea5b-1ab6-5ff0-a989-218fb95f2ae1', 'd823bff7-4779-5bd4-b714-7b7050497ded', 'INSUFFICIENT',
   'Ce collectif fonctionne bien. Ils sont six. Ils ont fait un planning. Ils ont acheté des outils. Ils ont posé des étiquettes. Ils font une réunion par trimestre. Ils tiennent un cahier. En conclusion pour terminer ma réponse, ce collectif fonctionne bien.',
   'Six actions listées et une clôture redondante : rien ne montre pourquoi cela fonctionne.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S23 / EXPECTED
  ('b1277b27-03c6-5ef5-9373-46288a895a9e', 'd823bff7-4779-5bd4-b714-7b7050497ded', 'EXPECTED',
   'Ce collectif fonctionne bien. Ils ont d''abord étiqueté chaque vélo, ce qui a permis de sortir huit épaves abandonnées depuis des années. La place ainsi libérée a suffi pour tout le monde, et personne n''a eu besoin de payer un agrandissement. Ils tiennent maintenant un cahier des entrées.',
   '« Ce qui a permis », « ainsi libérée » : chaque étape rend la suivante possible, et le texte s''arrête naturellement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S23 / EXCELLENT
  ('e63c8e46-4c16-59f5-9e0a-1cf0df6c80fd', 'd823bff7-4779-5bd4-b714-7b7050497ded', 'EXCELLENT',
   'Ce collectif fonctionne bien. Ils ont commencé par étiqueter chaque vélo, ce qui a permis d''identifier huit épaves abandonnées depuis des années. Une fois celles-ci évacuées, la place a suffi pour tout le monde — l''agrandissement voté l''an dernier est devenu inutile, et son budget est resté à la copropriété.',
   'La chaîne va d''une petite action jusqu''à une conséquence financière : l''enchaînement porte tout l''argument.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S24 / INSUFFICIENT
  ('2459ac3d-1304-57f5-b3ff-2570a6261709', '6810fbb7-24c2-5b68-9a3e-b9365abc0617', 'INSUFFICIENT',
   'Cette halte-garderie est bien pensée. La salle est grande. Il y a une baie vitrée. Le sol est souple. Les jouets sont rangés bas. Il y a un coin calme. Les toilettes sont adaptées. Pour conclure, en conclusion, elle est bien pensée.',
   'Six caractéristiques posées côte à côte, puis une clôture qui répète l''ouverture mot pour mot.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S24 / EXPECTED
  ('a44320be-4924-533e-93fd-b09a7e4dc8b2', '6810fbb7-24c2-5b68-9a3e-b9365abc0617', 'EXPECTED',
   'Cette halte-garderie est bien pensée. La grande baie vitrée donne sur la cour, si bien que les enfants voient partir leurs parents jusqu''au bout. Comme les jouets sont rangés à leur hauteur, ils vont les chercher seuls dès le premier jour. Le coin calme permet ensuite de récupérer sans sortir de la salle.',
   'Chaque élément du lieu est relié à ce qu''il permet, et l''ordre suit le déroulé d''une matinée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S24 / EXCELLENT
  ('a894d2f0-1cc1-5933-ada9-532e2c92ae39', '6810fbb7-24c2-5b68-9a3e-b9365abc0617', 'EXCELLENT',
   'Cette halte-garderie est bien pensée. La baie vitrée donne sur la cour, si bien que les enfants voient leurs parents jusqu''au portail — chez nous, cela a supprimé les pleurs en trois jours. Les jouets étant à leur hauteur, ils s''occupent seuls tout de suite. Et le coin calme permet de souffler sans quitter la salle.',
   'L''enchaînement suit le vécu de l''enfant, du départ des parents au moment de fatigue : c''est une progression, pas une liste.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S25 / INSUFFICIENT
  ('3e6f0d74-e812-502b-ba10-72dff5a35972', 'bfa69a55-f1c4-571a-a566-6171fc8a3a46', 'INSUFFICIENT',
   'La remise en service du four est une réussite. Il chauffe bien. La voûte a été refaite. Le bois est fourni. Il y a un planning. Les gens viennent. On fait du pain. Pour finir ma réponse en conclusion, c''est une réussite.',
   'Six phrases sans lien, une clôture qui recopie l''ouverture : rien ne démontre la réussite annoncée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S25 / EXPECTED
  ('6201b7b9-6bb1-54e1-811f-bae911dcee0a', 'bfa69a55-f1c4-571a-a566-6171fc8a3a46', 'EXPECTED',
   'La remise en service du four est une réussite. La voûte refaite tient enfin la chaleur, si bien qu''une flambée suffit pour douze fournées. Comme le bois est fourni par la commune, personne n''a d''avance à faire. Le planning affiché à la mairie s''est rempli sur trois mois dès la première semaine.',
   'Technique, organisation, résultat : trois idées liées qui démontrent la réussite sans la proclamer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S25 / EXCELLENT
  ('56db05b2-e896-58aa-9111-2137adb0883d', 'bfa69a55-f1c4-571a-a566-6171fc8a3a46', 'EXCELLENT',
   'La remise en service du four est une réussite. La voûte refaite tient la chaleur, si bien qu''une seule flambée suffit à douze fournées — avant, il en fallait trois. Le bois étant fourni par la commune, personne n''avance d''argent. Le planning s''est rempli sur trois mois dès la première semaine d''ouverture.',
   'L''enchaînement va du technique au social, et chaque maillon rend le suivant possible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S26 / INSUFFICIENT
  ('b9a1610e-19c9-5f23-b9ae-d57926422eb2', '97cb8e65-d231-59f5-a53a-628a1813786d', 'INSUFFICIENT',
   'Ce vendeur a été très bon. Il m''a écouté. Il a posé des questions. Il a mesuré mon pied. Il a proposé trois modèles. Il n''a pas insisté. Il a expliqué la différence. En conclusion et pour terminer, il a été très bon.',
   'Six actions alignées dans le désordre, et une clôture doublée qui n''apporte rien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S26 / EXPECTED
  ('0cc8d799-f99d-56f8-ab81-253600f13503', '97cb8e65-d231-59f5-a53a-628a1813786d', 'EXPECTED',
   'Ce vendeur a été très bon. Il a commencé par demander combien de kilomètres je courais par semaine, puis il a mesuré mon pied avant de sortir quoi que ce soit. Il m''a ensuite proposé trois modèles en expliquant ce qui les distinguait. Comme j''hésitais, il m''a laissé marcher dix minutes dans le magasin.',
   '« Par », « puis », « ensuite », « comme » : le déroulé de l''échange fournit un enchaînement naturel.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S26 / EXCELLENT
  ('84989638-8539-5d9b-b0eb-d782a31e979a', '97cb8e65-d231-59f5-a53a-628a1813786d', 'EXCELLENT',
   'Ce vendeur a été très bon. Il a d''abord demandé combien de kilomètres je courais, puis mesuré mon pied avant de sortir la moindre boîte. Les trois modèles qu''il a proposés venaient de ces deux réponses, et il a dit lequel il déconseillait. Comme j''hésitais encore, il m''a laissé marcher dix minutes.',
   '« Venaient de ces deux réponses » relie explicitement la fin de la chaîne à son début : c''est la cohérence démontrée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S27 / INSUFFICIENT
  ('32fbcd37-2a2b-5d9a-9ed6-a876e4f35416', 'fb0b5e53-2c73-594f-bf66-e7f9dd1973e3', 'INSUFFICIENT',
   'Cette équipe est efficace. L''accueil est rapide. Les prises de sang sont indolores. Les résultats arrivent vite. Le hall est propre. Les horaires sont larges. Le personnel est aimable. Pour conclure en résumé, cette équipe est efficace comme je l''ai dit.',
   'Six phrases juxtaposées et une clôture doublement redondante.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S27 / EXPECTED
  ('2639b6fd-909e-5471-85ca-5453852909e6', 'fb0b5e53-2c73-594f-bf66-e7f9dd1973e3', 'EXPECTED',
   'Cette équipe est efficace. L''accueil enregistre le dossier pendant qu''on s''assoit, si bien qu''on entre en salle sans attendre. La préleveuse prévient avant chaque geste, ce qui change tout pour les personnes qui redoutent l''aiguille. Les résultats arrivent ensuite par messagerie le soir même.',
   'L''ordre suit le parcours du patient, et chaque étape explique la suivante.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S27 / EXCELLENT
  ('bb955c1f-bc2a-5e8a-980b-64c355546013', 'fb0b5e53-2c73-594f-bf66-e7f9dd1973e3', 'EXCELLENT',
   'Cette équipe est efficace. L''accueil enregistre le dossier pendant qu''on s''assoit, si bien qu''on entre en salle sans même avoir ouvert un magazine. La préleveuse prévient avant chaque geste — ma fille, qui refusait les prises de sang, n''a pas bronché. Les résultats arrivent le soir même par messagerie.',
   'Chaque maillon porte une preuve, et l''enchaînement épouse exactement le déroulé de la visite.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S28 / INSUFFICIENT
  ('82b63f36-3f1a-5a31-928c-b9e570ccb823', '41e83856-7107-528d-b4cf-b3a20840d65b', 'INSUFFICIENT',
   'Cette cour est transformée. Le sol est en gravier. Il y a des bancs. Les poubelles sont cachées. Un arbre a été planté. Les vélos ont un abri. L''éclairage est neuf. Le portail est repeint. Les murs sont propres. Il y a un robinet. En conclusion pour finir, cette cour est transformée.',
   'Six éléments listés et une clôture qui ne fait que redire l''ouverture.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S28 / EXPECTED
  ('0b31bfc3-e9e5-5dda-a42e-71da11da850e', '41e83856-7107-528d-b4cf-b3a20840d65b', 'EXPECTED',
   'Cette cour est transformée. Les poubelles ont été déplacées derrière un muret, ce qui a libéré tout le fond. C''est là qu''on a pu installer les bancs et planter l''arbre. Comme l''éclairage a été refait en même temps, les habitants y descendent maintenant le soir.',
   'Chaque aménagement rend le suivant possible : l''enchaînement raconte la transformation au lieu de l''inventorier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S28 / EXCELLENT
  ('1c72cd53-3c47-5efa-9c51-851b8c3b9d02', '41e83856-7107-528d-b4cf-b3a20840d65b', 'EXCELLENT',
   'Cette cour est transformée. Les poubelles ont été déplacées derrière un muret, ce qui a libéré tout le fond — c''est là qu''on a mis les bancs et planté le tilleul. L''éclairage refait en même temps a fait le reste : depuis septembre, il y a du monde en bas tous les soirs, ce qui n''était jamais arrivé.',
   'La chaîne de causes aboutit à un fait social daté, et le texte se referme dessus sans formule.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S29 / INSUFFICIENT
  ('53ceae7b-2e04-5063-83f0-a75fd87aac5f', '624006d7-448a-595e-9778-cc562a82ac6b', 'INSUFFICIENT',
   'Je suis très contente de cet achat. Elle est en métal. Elle coud le jean. Elle a huit points. La pédale répond bien. Elle était révisée. Elle a coûté quatre-vingts euros. Pour conclure, en conclusion finale, je suis très contente.',
   'Six caractéristiques dans le désordre et une clôture à deux formules qui redit l''ouverture.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S29 / EXPECTED
  ('fc3a96c1-75a2-5eb9-b849-d3fb5293a7e7', '624006d7-448a-595e-9778-cc562a82ac6b', 'EXPECTED',
   'Je suis très contente de cet achat. Le bâti est en métal et non en plastique, si bien qu''elle ne saute pas sur la table quand j''accélère. Elle traverse donc le jean sans forcer, ce que ma précédente ne faisait pas. Elle avait en plus été révisée avant la vente.',
   '« Si bien que », « donc », « en plus » : les qualités s''enchaînent, chacune expliquant la suivante.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S29 / EXCELLENT
  ('d3ba93f6-23ca-51c1-9b28-70c41d568f95', '624006d7-448a-595e-9778-cc562a82ac6b', 'EXCELLENT',
   'Je suis très contente de cet achat. Le bâti est en métal, pas en plastique, si bien qu''elle ne saute pas sur la table quand j''accélère. Elle traverse donc quatre épaisseurs de jean sans forcer — ma précédente cassait une aiguille sur deux. Elle avait été révisée avant la vente, pour quatre-vingts euros.',
   'La chaîne matière → stabilité → puissance est complète, et le prix arrive en dernier comme une évidence.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S30 / INSUFFICIENT
  ('123e4622-56cd-5366-bad5-1adf9bcc66f5', 'c25252b9-dab6-5f7f-8714-37def5303b66', 'INSUFFICIENT',
   'Ce conducteur est très bien. Il est ponctuel. Il connaît les enfants. Il conduit doucement. Il attend les retardataires. Il dit bonjour. Il fait respecter le calme. Il range le bus. Il porte un gilet. Il klaxonne en partant. En conclusion pour terminer cette réponse, il est très bien.',
   'Six affirmations sans lien et une clôture qui répète l''ouverture : rien ne montre comment cela tient ensemble.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S30 / EXPECTED
  ('54957ac9-ee5a-5e58-911d-4cb7f28776af', 'c25252b9-dab6-5f7f-8714-37def5303b66', 'EXPECTED',
   'Ce conducteur est très bien. Il connaît le prénom de chaque enfant, si bien qu''il repère tout de suite celui qui manque. Comme il attend une minute avant de partir, les petits qui courent ne restent jamais sur le trottoir. Et il ne démarre pas tant que tout le monde n''est pas assis.',
   'Chaque pratique explique une conséquence pour les enfants : l''enchaînement porte l''avis.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C8-S30 / EXCELLENT
  ('8b61a5b5-4fb9-572e-849b-5cb5a99668a9', 'c25252b9-dab6-5f7f-8714-37def5303b66', 'EXCELLENT',
   'Ce conducteur est très bien. Il connaît le prénom de chaque enfant, si bien qu''il voit immédiatement qui manque — il a attendu ma fille deux minutes le jour où elle s''était trompée d''arrêt. Comme il patiente avant de partir, personne ne court après le bus. Et il ne démarre jamais debout.',
   'Un fait vécu s''insère au milieu de la chaîne sans la rompre, et la dernière phrase la referme d''un trait.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S1 / INSUFFICIENT
  ('3a305228-1423-5837-9ad0-74c813b8b4f1', '1a9b5fd7-0094-5c39-a157-caa945e9a71e', 'INSUFFICIENT',
   'Ah d''accord, six semaines. Bon, tant pis alors, je vais voir ailleurs. Merci quand même, madame, au revoir.',
   'L''échange s''arrête au premier refus : rien n''est tenté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S1 / EXPECTED
  ('1cad39e9-0a55-5913-980f-dd6681ed2e16', '1a9b5fd7-0094-5c39-a157-caa945e9a71e', 'EXPECTED',
   'Je comprends, mais est-ce que vous avez une liste d''annulation ? Si quelqu''un se décommande, je peux venir dans l''heure, j''habite juste à côté.',
   'La relance est polie et donne une raison de rappeler : l''échange continue.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S1 / EXCELLENT
  ('5dad9cac-4544-5036-ab0c-fb04139f18de', '1a9b5fd7-0094-5c39-a157-caa945e9a71e', 'EXCELLENT',
   'Je comprends, six semaines, c''est ce que vous avez. Est-ce que vous notez les annulations quelque part ? Je suis disponible tous les jours et j''habite à cinq minutes. Et sinon, le docteur garde-t-il des créneaux pour les urgences du matin ?',
   'Deux relances différentes suivent le refus, sans jamais le contester.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S2 / INSUFFICIENT
  ('e4214e15-37b3-5ef3-bace-8fce95cc736b', 'f8572ebc-0c53-526a-97c6-b79432c9dd38', 'INSUFFICIENT',
   'Ah, c''est complet ? D''accord, ce n''est pas grave, on essaiera l''année prochaine. Merci beaucoup, bonne journée à vous.',
   'Le refus est accepté tel quel : rien n''est tenté.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S2 / EXPECTED
  ('e9fa6a47-4d60-5f52-b95c-ad34ba1f04c1', 'f8572ebc-0c53-526a-97c6-b79432c9dd38', 'EXPECTED',
   'D''accord, et est-ce qu''il y a une liste d''attente ? Je peux laisser mon numéro, au cas où une place se libère pendant le trimestre.',
   'La relance est polie et laisse une porte ouverte.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S2 / EXCELLENT
  ('fe52656a-3327-5ffa-9a23-2b78441ed388', 'f8572ebc-0c53-526a-97c6-b79432c9dd38', 'EXCELLENT',
   'D''accord, la liste du samedi est complète. Est-ce qu''il existe une liste d''attente où je peux laisser mon numéro ? Et est-ce que les créneaux du mercredi après-midi sont pleins aussi, ou seulement celui du samedi ?',
   'Le refus est reformulé puis contourné par deux relances utiles.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S3 / INSUFFICIENT
  ('7fd7ca44-92ed-5d1c-b773-a6c6f1743438', '3b7dbcca-501b-51cc-a59c-e330aee12d3c', 'INSUFFICIENT',
   'Ah, il n''est plus fabriqué. Bon, d''accord, je vais devoir racheter un aspirateur alors. Merci monsieur, au revoir.',
   'Le refus met fin à l''échange sans qu''une seule question soit posée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S3 / EXPECTED
  ('cd5931ac-a36f-5c74-9c4a-95c82d9bdb71', '3b7dbcca-501b-51cc-a59c-e330aee12d3c', 'EXPECTED',
   'Je vois. Et est-ce qu''une pièce d''un autre modèle peut s''adapter ? Ou est-ce que vous connaissez un réparateur qui garde des pièces anciennes ?',
   'Deux relances polies prolongent l''échange au lieu de le clore.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S3 / EXCELLENT
  ('26e10758-8e6d-58b5-89d2-31a82026414a', '3b7dbcca-501b-51cc-a59c-e330aee12d3c', 'EXCELLENT',
   'Je vois, le modèle est arrêté. Est-ce qu''une pièce équivalente d''une autre série peut s''adapter ? Sinon, connaissez-vous un réparateur du coin qui garde des stocks anciens ? J''aimerais éviter de racheter une machine qui marche.',
   'Le refus est accepté, puis contourné par deux pistes concrètes.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S4 / INSUFFICIENT
  ('c95ddf06-aa67-53c2-9559-042915bce21d', '688a2862-7b89-5d45-ab7c-7b9034b75b10', 'INSUFFICIENT',
   'Cinq minutes, ça devrait suffire quand même, non ? J''ai fait tout le trajet pour venir et je ne vais pas repartir comme ça, franchement.',
   'La relance existe, mais elle pousse : l''échange se tend au lieu d''avancer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S4 / EXPECTED
  ('6716b19e-6e06-521f-a837-db9048d8d115', '688a2862-7b89-5d45-ab7c-7b9034b75b10', 'EXPECTED',
   'Je sais qu''il est tard, mais ma demande tient en une minute : je viens juste retirer un document déjà prêt. Sinon je reviens demain matin sans problème.',
   'La relance est brève, justifiée, et laisse le choix à l''agent.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S4 / EXCELLENT
  ('53f22e4b-e91a-5fb1-89cf-bf3cb14933b4', '688a2862-7b89-5d45-ab7c-7b9034b75b10', 'EXCELLENT',
   'Je sais qu''il est tard et je ne veux pas vous retarder. Je viens seulement retirer un acte déjà préparé, c''est l''affaire d''une minute. Si ce n''est pas possible, dites-moi à quelle heure ouvre le guichet demain, je serai là à l''ouverture.',
   'La relance est polie, courte, et prévoit déjà l''échec sans se braquer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S5 / INSUFFICIENT
  ('348e1993-4f14-5663-94d5-133264833acb', '8ebc8b95-8bb5-5089-b665-a8ad58d750bf', 'INSUFFICIENT',
   'Ah, seulement la carte ? Bon, tant pis, je laisse tout alors. Désolé du dérangement, au revoir monsieur.',
   'La contrainte met fin à l''échange sans qu''une solution soit cherchée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S5 / EXPECTED
  ('36650092-5e0f-56e4-be15-16354d6b7844', '8ebc8b95-8bb5-5089-b665-a8ad58d750bf', 'EXPECTED',
   'Ah, je n''ai que des espèces. Est-ce qu''il y a un distributeur à côté ? Ou est-ce que vous pouvez me garder les articles dix minutes, le temps que j''aille en chercher ?',
   'Deux relances concrètes gardent l''échange ouvert.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S5 / EXCELLENT
  ('297662fd-7b54-5945-b4d0-5cd2615417c3', '8ebc8b95-8bb5-5089-b665-a8ad58d750bf', 'EXCELLENT',
   'Ah, je n''ai que des espèces sur moi. Est-ce qu''il y a un distributeur dans la rue ? Si oui, pouvez-vous me mettre les articles de côté dix minutes ? Et s''il est loin, est-ce que le paiement par téléphone fonctionne chez vous ?',
   'Chaque relance prépare la suivante : l''échange ne retombe jamais.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S6 / INSUFFICIENT
  ('2dd98d5e-164d-5c4c-bfbd-ae90c222d146', '0f3596e3-cf44-5798-82c6-6a35f92ab335', 'INSUFFICIENT',
   'Ah, je ne l''ai pas. Il faut vraiment ce document ? Bon, je reviendrai un autre jour alors, quand je l''aurai retrouvé chez moi.',
   'La contrainte est subie : aucune solution n''est proposée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S6 / EXPECTED
  ('25480758-5889-57df-ba87-0ca084fbf6b7', '0f3596e3-cf44-5798-82c6-6a35f92ab335', 'EXPECTED',
   'Je ne l''ai pas sur moi. Est-ce que je peux vous l''envoyer ce soir depuis mon espace en ligne ? Ou est-ce que je peux vous montrer la version sur mon téléphone maintenant ?',
   'Deux solutions concrètes sont proposées et l''échange avance.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S6 / EXCELLENT
  ('9be9e549-85de-5407-87d0-1d7071a7aecd', '0f3596e3-cf44-5798-82c6-6a35f92ab335', 'EXCELLENT',
   'Je ne l''ai pas sur moi, je comprends que vous ne puissiez pas traiter le dossier. Je peux le télécharger depuis mon espace en ligne et vous l''envoyer ce soir. Est-ce que cela suffit pour que le reste parte dès demain, ou faut-il que je repasse au guichet ?',
   'La solution est proposée puis vérifiée : c''est l''échange qui avance, pas seulement le dossier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S7 / INSUFFICIENT
  ('d0568bca-fc8c-56a0-ab31-b0a4c3da4e82', 'c1c520ea-4960-575f-a58a-31458bf3d0cf', 'INSUFFICIENT',
   'Ah, seulement en semaine. C''est embêtant parce que je travaille. Je vais réfléchir et je reviendrai vous voir plus tard dans la semaine.',
   'La contrainte est constatée, aucune solution n''est cherchée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S7 / EXPECTED
  ('d988ba68-c2d1-5423-a1c7-0c05b4fb0957', 'c1c520ea-4960-575f-a58a-31458bf3d0cf', 'EXPECTED',
   'Je travaille à ces heures-là. Est-ce que la livraison peut se faire chez ma voisine, au rez-de-chaussée ? Elle est chez elle la journée et je peux vous laisser son nom.',
   'Une solution précise est proposée, avec ce qu''il faut pour l''appliquer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S7 / EXCELLENT
  ('0f1a240d-a8b7-538d-86f9-70f39a1444c7', 'c1c520ea-4960-575f-a58a-31458bf3d0cf', 'EXCELLENT',
   'Je travaille de neuf heures à dix-huit heures, donc aucun créneau ne me convient. Deux possibilités : la livraison chez ma voisine du rez-de-chaussée, qui accepte de signer, ou un samedi si vous en faites parfois. Laquelle est la plus simple pour vous ?',
   'Deux solutions sont posées et le choix est renvoyé au vendeur : l''échange reste vivant.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S8 / INSUFFICIENT
  ('69061c8e-d3f5-5888-b3dd-7315360aca71', 'c239daa0-0703-536e-83bc-64520095b098', 'INSUFFICIENT',
   'Trois semaines ? C''est vraiment très long, l''eau coule tous les jours. Bon, je vais appeler quelqu''un d''autre alors. Merci monsieur.',
   'Le délai est contesté, mais rien n''est proposé pour avancer.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S8 / EXPECTED
  ('1a1ab698-2ac8-5cc2-b195-0cd1fc27f1f9', 'c239daa0-0703-536e-83bc-64520095b098', 'EXPECTED',
   'Trois semaines, c''est long avec une fuite. Est-ce que vous pouvez m''expliquer au téléphone comment couper l''arrivée d''eau sous l''évier ? Et je garde le rendez-vous dans trois semaines.',
   'Une solution d''attente est proposée et le rendez-vous est préservé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S8 / EXCELLENT
  ('38d3d96d-0cdc-59c3-953f-e3c9c7bc269e', 'c239daa0-0703-536e-83bc-64520095b098', 'EXCELLENT',
   'Trois semaines, c''est long, mais je préfère attendre quelqu''un de sérieux. Deux choses : pouvez-vous m''indiquer comment couper l''eau sous l''évier en attendant, et est-ce que vous me rappelez si un client annule ? Je suis disponible du jour au lendemain.',
   'L''attente est acceptée, aménagée, et une porte reste ouverte.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S9 / INSUFFICIENT
  ('e0dc510b-2ccd-5256-8dcb-1869632a04c0', '74420700-58b6-5edb-aeef-adb103c330ec', 'INSUFFICIENT',
   'Le mardi soir, je travaille. C''est dommage parce que j''avais vraiment besoin de ces cours. Je verrai si je peux m''arranger plus tard dans l''année.',
   'La contrainte ferme l''échange : rien n''est proposé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S9 / EXPECTED
  ('40aa7fb1-5b1e-5aee-a57a-baf6042cf22d', '74420700-58b6-5edb-aeef-adb103c330ec', 'EXPECTED',
   'Je travaille le mardi soir. Est-ce que je peux suivre les cours un mardi sur deux, quand je finis plus tôt ? Ou est-ce qu''un bénévole donne parfois des cours le samedi ?',
   'Deux solutions sont proposées et l''échange reste ouvert.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S9 / EXCELLENT
  ('3148ae37-5fc7-5b9e-83df-90bcecbbbdc1', '74420700-58b6-5edb-aeef-adb103c330ec', 'EXCELLENT',
   'Je travaille le mardi jusqu''à vingt heures, donc je ne peux pas être là au début du cours. Est-ce que je peux arriver en cours de séance, ou venir un mardi sur deux ? Et si un groupe du samedi ouvre un jour, pouvez-vous me prévenir ?',
   'Trois pistes se suivent, de la plus simple à la plus lointaine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S10 / INSUFFICIENT
  ('c4fa021d-3834-5ae8-8189-68bb434718d1', '02e541d6-4221-5dc9-8dd8-ed3b27b9f3f0', 'INSUFFICIENT',
   'Trois mois de caution, c''est beaucoup trop pour moi. Je ne peux pas payer ça. Je vais continuer à chercher ailleurs, merci pour la visite.',
   'La contrainte fait abandonner : aucune solution n''est envisagée.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S10 / EXPECTED
  ('f7a7ade9-8944-5f06-874d-ecd4309a9327', '02e541d6-4221-5dc9-8dd8-ed3b27b9f3f0', 'EXPECTED',
   'Trois mois, je ne peux pas les avancer d''un coup. Est-ce que le propriétaire accepterait une garantie d''organisme, ou un paiement en deux fois sur deux mois ?',
   'Deux solutions concrètes sont proposées, adaptées à la contrainte.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S10 / EXCELLENT
  ('946d92cd-7ee0-5097-8aae-e2dee5425e49', '02e541d6-4221-5dc9-8dd8-ed3b27b9f3f0', 'EXCELLENT',
   'Trois mois d''un coup, je ne peux pas. Je peux en revanche présenter une garantie d''organisme, qui couvre le propriétaire mieux qu''une caution, ou fournir un garant avec ses fiches de paie. Laquelle des deux le rassurerait le plus ?',
   'Les solutions répondent à l''intérêt du propriétaire, pas seulement au sien.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S11 / INSUFFICIENT
  ('d56fc288-fe81-5c54-ac25-5ace28d46f1a', '5560a686-085d-5d3b-834c-7135af4f03b2', 'INSUFFICIENT',
   'Deux jours, ce n''est rien du tout. Vous pourriez faire un geste quand même, je suis client ici depuis des années. Ce n''est vraiment pas normal.',
   'La même demande est répétée plus fort : l''échange se bloque.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S11 / EXPECTED
  ('594ba18b-74cb-5b08-9050-b2187bf7e56b', '5560a686-085d-5d3b-834c-7135af4f03b2', 'EXPECTED',
   'D''accord, le remboursement n''est pas possible. Est-ce qu''un avoir reste envisageable, même partiel ? Ou est-ce que l''appareil peut passer en garantie, puisqu''il s''arrête tout seul ?',
   'La demande change de nature : l''échange repart sur autre chose.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S11 / EXCELLENT
  ('13633106-c328-5480-bf60-95fcdcaf7103', '5560a686-085d-5d3b-834c-7135af4f03b2', 'EXCELLENT',
   'D''accord, je comprends, trente jours c''est trente jours. Alors je change ma demande : l''appareil s''éteint tout seul au bout d''une heure, donc ce n''est pas un simple retour, c''est une panne. Est-ce qu''il peut partir en garantie ? Et sinon, un avoir serait-il possible ?',
   'La règle est acceptée, puis la situation est requalifiée : l''échange rebondit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S12 / INSUFFICIENT
  ('0808654d-2cea-5367-9114-538d157d0fc4', '41806f0f-f2fa-57a8-84be-5c157422d84e', 'INSUFFICIENT',
   'Vraiment aucune exception ? J''habite juste en face et je n''ai personne d''autre. Essayez de lui demander, s''il vous plaît, ça ne coûte rien de demander.',
   'La même demande revient, plus insistante : l''échange se ferme.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S12 / EXPECTED
  ('6156a7ed-0faa-5fc4-b147-cd5a40867107', '41806f0f-f2fa-57a8-84be-5c157422d84e', 'EXPECTED',
   'Je comprends. Dans ce cas, est-ce que vous connaissez un cabinet du quartier qui accepte encore des patients ? Ou est-ce qu''une liste existe quelque part à la mairie ?',
   'La demande change : on ne demande plus une place, mais une piste.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S12 / EXCELLENT
  ('0f293d0b-d895-5213-8562-a974e34c564b', '41806f0f-f2fa-57a8-84be-5c157422d84e', 'EXCELLENT',
   'Je comprends, le docteur est complet. Je ne vous demande donc pas une place : savez-vous si un nouveau médecin s''installe dans le quartier cette année ? Et est-ce que le cabinet reprend parfois des patients quand un confrère part à la retraite ?',
   'Le refus est explicitement mis de côté et deux questions utiles prennent sa place.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S13 / INSUFFICIENT
  ('ff62aad5-6ad1-5d07-8895-c33492b94e4b', '89968340-313a-5c05-a7bf-6f5061dde55a', 'INSUFFICIENT',
   'Mais c''est bien mon adresse, elle est écrite dessus et la personne a signé. Je ne vois pas ce que vous voulez de plus, honnêtement. C''est toujours compliqué ici.',
   'Le document est défendu encore et encore : l''échange n''avance plus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S13 / EXPECTED
  ('45076301-f7ab-50c7-888d-0669e1afc98b', '89968340-313a-5c05-a7bf-6f5061dde55a', 'EXPECTED',
   'D''accord. Alors dites-moi plutôt quels justificatifs vous acceptez : une facture d''électricité au nom de la personne qui m''héberge, avec sa pièce d''identité, est-ce que cela convient ?',
   'La demande change de sens : on ne défend plus, on s''informe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S13 / EXCELLENT
  ('f57eb47c-5e81-57a6-a37f-5c90e8c140e8', '89968340-313a-5c05-a7bf-6f5061dde55a', 'EXCELLENT',
   'D''accord, je n''insiste pas sur ce papier. Dites-moi plutôt ce qui est accepté : une facture au nom de mon hébergeant et une copie de sa carte d''identité, est-ce que cela suffit ? Et si je reviens avec ces pièces demain, faut-il reprendre un rendez-vous ?',
   'La règle est acceptée, la suite est préparée : l''échange devient utile.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S14 / INSUFFICIENT
  ('a9018bc4-7a3f-5d1d-bf26-f86fb4c66021', '34a901f5-07e3-52d9-b38e-a35cc3c6c310', 'INSUFFICIENT',
   'Ah bon ? Pourtant l''entretien s''était très bien passé, vous m''aviez dit que mon profil correspondait. Je ne comprends pas bien ce qui a changé depuis.',
   'La décision est discutée : l''échange se referme sans rien apporter.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S14 / EXPECTED
  ('c0c63394-a971-5310-ad82-b646291de45b', '34a901f5-07e3-52d9-b38e-a35cc3c6c310', 'EXPECTED',
   'Je vous remercie de me le dire. Est-ce que vous pouvez me dire ce qui a manqué dans mon profil ? Et est-ce que d''autres postes s''ouvrent dans les mois qui viennent ?',
   'Deux demandes nouvelles remplacent la demande perdue.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S14 / EXCELLENT
  ('18947bde-e7bc-5083-ab72-674e40685903', '34a901f5-07e3-52d9-b38e-a35cc3c6c310', 'EXCELLENT',
   'Je vous remercie de m''avoir rappelé. Puisque le poste est pris, deux choses : qu''est-ce qui a fait la différence, pour que je progresse ? Et si un poste similaire s''ouvre cette année, est-ce que je peux vous renvoyer ma candidature directement ?',
   'Le refus est acté et l''échange se prolonge sur ce qui reste possible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S15 / INSUFFICIENT
  ('2d84f7b8-88cb-5fbb-b6a2-a629538c3eb6', '3139e107-5df7-53d3-801a-89a489fb22bd', 'INSUFFICIENT',
   'Quarante kilomètres pour une erreur que vous avez faite ? Ce n''est pas à moi de me déplacer. Vous pouvez très bien le corriger vous-même, j''en suis sûr.',
   'La demande initiale est répétée sur un ton plus dur : rien n''avance.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S15 / EXPECTED
  ('23e42b24-ea0a-5ddf-9da9-c47ff2438278', '3139e107-5df7-53d3-801a-89a489fb22bd', 'EXPECTED',
   'D''accord, pas par téléphone. Alors est-ce que je peux envoyer la correction par courrier ou depuis mon espace en ligne ? Et que dois-je joindre pour que le dossier soit complet ?',
   'La demande change de canal et l''échange repart.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9-S15 / EXCELLENT
  ('32e9ca95-a32c-5848-829b-8f2921650309', '3139e107-5df7-53d3-801a-89a489fb22bd', 'EXCELLENT',
   'D''accord, la modification se fait en agence. Alors préparons-la : quels documents dois-je apporter, et faut-il un rendez-vous ou puis-je venir sans ? Et si l''erreur me fait payer trop ce mois-ci, est-ce que le prélèvement peut être suspendu en attendant ?',
   'La contrainte est acceptée et l''échange sert à préparer la suite.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S1 / INSUFFICIENT
  ('b9a39a3c-33ba-542b-9fd7-5b1f133a41b9', '79689aa4-a626-54a9-b05b-cac0e0c3dacb', 'INSUFFICIENT',
   'Oui, vraiment, c''est mieux pour tout le monde. Pour les salariés, pour l''entreprise, pour tout le monde, c''est mieux. Je pense que c''est mieux comme ça.',
   'La phrase revient à l''identique : rien n''est précisé, le propos piétine.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S1 / EXPECTED
  ('b063a02b-cf57-516f-9747-a540cd469a6d', '79689aa4-a626-54a9-b05b-cac0e0c3dacb', 'EXPECTED',
   'Je veux dire par là que chacun peut caler ses horaires sur ses trajets et sa famille. L''entreprise y gagne aussi : moins de retards le matin, moins de journées posées pour un rendez-vous.',
   'L''idée est redite en d''autres mots et gagne en précision.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S1 / EXCELLENT
  ('7d115e1b-3ae2-5ed5-9f71-d25cd0757b73', '79689aa4-a626-54a9-b05b-cac0e0c3dacb', 'EXCELLENT',
   'Je veux dire par là que chacun choisit son heure d''arrivée selon ses trajets et ses enfants. Pour l''entreprise, cela veut dire moins de retards le matin et moins de congés posés pour un rendez-vous d''une heure. « Mieux pour tout le monde », c''est cela concrètement.',
   'La reprise précise l''idée des deux côtés et referme la boucle sur la formule de départ.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S2 / INSUFFICIENT
  ('d2401b01-2011-520e-9a2d-4f261162209b', '7984462c-3a76-518c-9ea7-1e5722cd9b4b', 'INSUFFICIENT',
   'Oui, ça coûte cher, vraiment très cher. Les transports, c''est cher pour tout le monde et ça augmente encore. C''est cher, voilà.',
   'Le mot « cher » revient quatre fois sans jamais être expliqué.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S2 / EXPECTED
  ('ee03c52e-1f28-5dfd-a2cf-661cc7ee370b', '7984462c-3a76-518c-9ea7-1e5722cd9b4b', 'EXPECTED',
   'Plus précisément, l''abonnement me prend soixante-quinze euros par mois, soit une semaine de courses. Et ce n''est pas un choix : sans voiture, je n''ai pas d''autre moyen d''aller travailler.',
   'L''idée est redite en termes concrets : « cher » devient mesurable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S2 / EXCELLENT
  ('0d973725-0b85-5669-8b33-ecb2e29a1a89', '7984462c-3a76-518c-9ea7-1e5722cd9b4b', 'EXCELLENT',
   'Plus précisément, soixante-quinze euros par mois, c''est une semaine de courses pour ma famille. Et ce n''est pas une dépense qu''on peut réduire : sans voiture, il n''y a pas d''autre façon d''aller travailler. C''est ce que j''appelle cher.',
   'La reprise chiffre, explique l''absence de choix, puis reprend le mot de départ.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S3 / INSUFFICIENT
  ('f8e24480-18fe-5bc7-a137-cd95ab6dd276', 'f2164eaa-3143-5b2d-8765-d4751f61d207', 'INSUFFICIENT',
   'C''est plus pratique, franchement. Les commerces de quartier, c''est vraiment pratique au quotidien, beaucoup plus pratique que les grandes surfaces.',
   'Le mot est répété sans être expliqué : le propos tourne sur lui-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S3 / EXPECTED
  ('8f14546e-154a-54a2-b909-63b126a9d045', 'f2164eaa-3143-5b2d-8765-d4751f61d207', 'EXPECTED',
   'Pratique, c''est-à-dire que je descends acheter du pain en trois minutes, sans voiture et sans faire la queue. Je n''ai pas besoin de prévoir ni de charger un coffre.',
   'L''idée est reformulée par des gestes concrets : « pratique » devient visible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S3 / EXCELLENT
  ('7f1b3ea3-4770-5972-9a8a-200b64377815', 'f2164eaa-3143-5b2d-8765-d4751f61d207', 'EXCELLENT',
   'Pratique, c''est-à-dire que j''y descends en trois minutes, sans voiture, sans chariot, sans queue. Je peux y aller à sept heures du soir pour une chose oubliée. Une grande surface demande de prévoir ; le commerce du bas, non.',
   'La reprise remplace le mot par des gestes, puis oppose les deux situations.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S4 / INSUFFICIENT
  ('d58f307a-f8a1-5932-b167-69ee78b3001f', '9f0960f1-a1df-5b80-8784-56c5287e762b', 'INSUFFICIENT',
   'C''est très important pour les enfants, c''est même essentiel. Tous les spécialistes le disent, la lecture est importante pour les enfants, il ne faut pas l''oublier.',
   'Le mot est renforcé au lieu d''être expliqué : rien ne progresse.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S4 / EXPECTED
  ('eb00b1d2-c4db-582b-a97d-a0624c1ffbce', '9f0960f1-a1df-5b80-8784-56c5287e762b', 'EXPECTED',
   'Important, je veux dire que dix minutes chaque soir suffisent à leur donner du vocabulaire. Un enfant à qui l''on a lu des histoires arrive en classe avec des mots que les autres découvrent.',
   'L''idée est redite concrètement : « important » se transforme en effet observable.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S4 / EXCELLENT
  ('0f27bab0-45e3-5a79-a8ab-c2a07cb6ac01', '9f0960f1-a1df-5b80-8784-56c5287e762b', 'EXCELLENT',
   'Important, je veux dire que dix minutes par soir changent le vocabulaire d''un enfant en un an. Il arrive en classe avec des mots que les autres découvrent, et il suit sans effort. Ce n''est pas un supplément : c''est ce qui rend l''école plus facile.',
   'La reprise mesure l''effet, puis requalifie le mot de départ.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S5 / INSUFFICIENT
  ('2d626d11-0d41-5873-8138-60b5baeb5f09', '1e06cff1-77f3-5986-901b-513a7d26dbda', 'INSUFFICIENT',
   'Ça ne marche pas, c''est tout. On a essayé, ça ne marche pas dans notre immeuble. Il faudrait autre chose parce que là, ça ne marche vraiment pas.',
   'La formule revient trois fois sans qu''on sache de quoi il s''agit.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S5 / EXPECTED
  ('a5538787-ab08-5878-aaf5-67dc0d9f07e9', '1e06cff1-77f3-5986-901b-513a7d26dbda', 'EXPECTED',
   'Concrètement, le bac jaune est plein de sacs noirs dès le lundi soir. Le camion refuse de le vider et tout part à l''incinération, y compris ce que les autres ont trié.',
   'L''idée est redite par une scène précise : le problème devient visible.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S5 / EXCELLENT
  ('bedd8460-3248-5fe4-9cf9-dee08e33af43', '1e06cff1-77f3-5986-901b-513a7d26dbda', 'EXCELLENT',
   'Concrètement, le bac jaune contient des sacs noirs dès le lundi soir. Le camion le refuse, et tout part à l''incinération, y compris ce que les autres ont trié correctement. Ceux qui font l''effort le font donc pour rien, et ils arrêtent.',
   'La reprise décrit la scène, puis explique pourquoi le système se défait.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S6 / INSUFFICIENT
  ('a43c225e-d083-5265-98bc-8d616a1e638e', '513b15ca-165c-5f02-9871-336f4c8816f7', 'INSUFFICIENT',
   'Non, non, je ne suis pas dur, pas du tout. Je dis juste qu''ils ne lisent plus, c''est un constat, ce n''est pas une critique, voilà tout.',
   'La même phrase revient avec une dénégation : le malentendu reste entier.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S6 / EXPECTED
  ('6dc091c2-9545-58dc-b7d4-4254c898f297', '513b15ca-165c-5f02-9871-336f4c8816f7', 'EXPECTED',
   'Ce n''est pas ce que je voulais dire : ils lisent beaucoup, mais sur écran, par petits morceaux. Ce qui se perd, c''est le texte long qu''on suit pendant une heure.',
   'L''idée est reformulée et le malentendu tombe de lui-même.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S6 / EXCELLENT
  ('bbdb111e-fa64-5009-9f13-f1e63ab9f6ee', '513b15ca-165c-5f02-9871-336f4c8816f7', 'EXCELLENT',
   'Ce n''est pas ce que je voulais dire : ils lisent sans doute plus de mots que nous au même âge, mais par fragments, sur un écran. Ce qui disparaît, c''est le texte long, tenu pendant une heure. Le reproche n''est pas pour eux, il est pour la forme.',
   'La reprise inverse le reproche et redéfinit exactement ce qui était visé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S7 / INSUFFICIENT
  ('a3d8a382-b909-58d2-986f-282c3fcebbbe', 'd06a752c-a778-58ea-a99b-932f52fb7300', 'INSUFFICIENT',
   'Non, je n''ai jamais dit interdire, jamais. J''ai dit limiter, ce n''est pas pareil du tout. Limiter, c''est limiter, ce n''est pas interdire les voitures.',
   'La dénégation tourne en rond : l''idée n''est jamais redite autrement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S7 / EXPECTED
  ('76401508-567a-51aa-94fd-26eb214b500b', 'd06a752c-a778-58ea-a99b-932f52fb7300', 'EXPECTED',
   'Je ne dis pas cela. Je dis que la place du centre peut accueillir vingt voitures au lieu de quatre-vingts, avec un parking à trois minutes à pied. Les voitures restent, elles se garent ailleurs.',
   'L''idée est reformulée par un chiffre et une solution : le malentendu tombe.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S7 / EXCELLENT
  ('59c98265-cf82-5ac0-b3d6-f3025518a1ca', 'd06a752c-a778-58ea-a99b-932f52fb7300', 'EXCELLENT',
   'Je ne dis pas cela. Je dis que la place peut accueillir vingt voitures au lieu de quatre-vingts, avec un parking à trois minutes à pied. Les livraisons passent le matin, les riverains gardent leur accès. Ce n''est pas moins de voitures, c''est moins de voitures arrêtées là.',
   'La reprise donne la mesure, les exceptions, puis reformule la nuance décisive.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S8 / INSUFFICIENT
  ('2237c08d-f666-53b5-aaed-52fa49bb1c9a', '111a1762-73e1-53fb-9c70-8192f1ab9e00', 'INSUFFICIENT',
   'Non, je ne suis pas contre le télétravail, pas du tout. Je dis juste que ça isole. Ça isole, c''est un fait, mais je ne suis pas contre.',
   'La phrase revient telle quelle : l''interlocuteur n''a aucune raison de changer d''avis.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S8 / EXPECTED
  ('f6e27600-839c-5a31-9335-c085a110ada5', '111a1762-73e1-53fb-9c70-8192f1ab9e00', 'EXPECTED',
   'Non, je ne suis pas contre. Ce que je dis, c''est qu''au bout de trois mois sans venir, on ne sait plus à qui poser une question simple. Deux jours sur place par semaine suffisent à éviter cela.',
   'L''idée est reformulée avec sa condition : la position devient claire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S8 / EXCELLENT
  ('3d29b561-b2c3-5180-b47d-8a2446f2e4f8', '111a1762-73e1-53fb-9c70-8192f1ab9e00', 'EXCELLENT',
   'Non, je ne suis pas contre. Ce que je dis, c''est qu''au bout de trois mois à distance, on ne sait plus à qui poser une question de deux minutes, et on attend un rendez-vous pour cela. Deux jours sur place suffisent. Le problème n''est pas le télétravail, c''est le télétravail complet.',
   'La reprise déplace le problème et nomme exactement ce qui était visé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S9 / INSUFFICIENT
  ('e7ac08f8-343f-5b42-949e-59b7923e26c6', '89cabd64-b692-5c2a-a711-90dc1c83511f', 'INSUFFICIENT',
   'Non, non, ce n''est pas contre vous, vraiment pas. Je dis que l''école demande trop, c''est tout. Ce n''est pas un reproche, c''est un constat sur l''école.',
   'Le constat est répété et la personne reste visée : rien n''est levé.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S9 / EXPECTED
  ('ce9234f8-4d89-52bf-9a33-172eff549fef', '89cabd64-b692-5c2a-a711-90dc1c83511f', 'EXPECTED',
   'Ce n''est pas à vous que je pense. Je pense aux devoirs qui supposent un parent disponible à dix-huit heures et capable d''expliquer une leçon. Un parent qui finit à dix-neuf heures ne peut pas suivre.',
   'L''idée est redirigée vers son vrai objet : le malentendu disparaît.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S9 / EXCELLENT
  ('cf93c34b-4027-5cba-92c9-34fb9d3dc0b0', '89cabd64-b692-5c2a-a711-90dc1c83511f', 'EXCELLENT',
   'Ce n''est pas à vous que je pense. Je pense aux devoirs qui supposent un adulte disponible à dix-huit heures, capable d''expliquer une division et de faire réciter une leçon. Un parent qui finit à dix-neuf heures ne peut pas, et son enfant prend du retard sans que personne l''ait décidé.',
   'La reprise nomme précisément le mécanisme visé, sans jamais accuser quelqu''un.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S10 / INSUFFICIENT
  ('414fcb54-c0b4-5b69-a1c4-e3055c2c758f', '9e8e637a-b3da-570a-81c5-bf094aa85016', 'INSUFFICIENT',
   'Les supprimer ? Non, bien sûr que non, ce n''est pas ce que j''ai dit. J''ai dit qu''ils font perdre du temps, et c''est vrai, ils font perdre du temps.',
   'L''extrême est écarté mais la phrase revient à l''identique : rien n''avance.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S10 / EXPECTED
  ('f36ed928-bf90-5b2f-831c-d468d1d2e717', '9e8e637a-b3da-570a-81c5-bf094aa85016', 'EXPECTED',
   'Ce n''est pas la question. Ce que je dis, c''est qu''on les ouvre pour cinq minutes et qu''on referme une heure plus tard sans s''en rendre compte. Ce n''est pas l''outil, c''est la façon dont il retient.',
   'L''idée est reformulée et le débat revient à sa vraie mesure.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S10 / EXCELLENT
  ('b6e5e3bc-0832-55d2-b304-dcb0eca99238', '9e8e637a-b3da-570a-81c5-bf094aa85016', 'EXCELLENT',
   'Ce n''est pas la question. Ce que je dis, c''est qu''on les ouvre pour cinq minutes et qu''on referme une heure plus tard, sans décision consciente entre les deux. Ce n''est pas l''outil qui est en cause, c''est ce qui est fait pour qu''on ne s''arrête pas. Les supprimer ne réglerait rien.',
   'La reprise déplace la cible et répond à l''objection dans le même mouvement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S11 / INSUFFICIENT
  ('8497d7d5-f21b-5a1d-a4d9-2adce6892bad', 'aeef2f61-2821-5433-868c-44ee8255dce4', 'INSUFFICIENT',
   'C''est vraiment une question de moyens, je le maintiens. Sans moyens, on ne peut rien faire, c''est toujours une question de moyens au bout du compte.',
   'La formule revient une troisième fois : le propos n''avance plus.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S11 / EXPECTED
  ('d54fe15c-55e0-57a9-b50a-506639f13aa0', 'aeef2f61-2821-5433-868c-44ee8255dce4', 'EXPECTED',
   'Plutôt que de parler de moyens, disons qu''une crèche a besoin d''une professionnelle pour cinq enfants, et qu''on ne les trouve pas. Le problème n''est pas seulement l''argent, c''est le métier.',
   'L''idée est reprise en d''autres termes et le propos repart sur le recrutement.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S11 / EXCELLENT
  ('54827516-bdb4-525b-9f34-8e684f442559', 'aeef2f61-2821-5433-868c-44ee8255dce4', 'EXCELLENT',
   'Plutôt que de parler de moyens, disons qu''une crèche a besoin d''une professionnelle pour cinq enfants, et que ces professionnelles n''existent pas en nombre suffisant. Même avec le budget, les places n''ouvriraient pas cette année. Le vrai sujet, c''est la formation, et elle prend deux ans.',
   'La reprise abandonne la formule et ouvre une suite entièrement nouvelle.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S12 / INSUFFICIENT
  ('71d8837f-c0a9-596f-8e16-a4f300b952ca', '79a0536c-c787-5098-8f8d-8d526e0eab1e', 'INSUFFICIENT',
   'C''est important, c''est vraiment important d''apprendre le français. Tout le monde vous dira que c''est important, et moi aussi je trouve que c''est important.',
   'Le mot revient sans cesse : le propos tourne sur place.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S12 / EXPECTED
  ('12aa03c3-3714-5481-9b67-cfc510ef1bdc', '79a0536c-c787-5098-8f8d-8d526e0eab1e', 'EXPECTED',
   'Disons-le autrement : sans le français, on ne comprend pas une lettre de la préfecture et on signe des papiers qu''on n''a pas lus. Ce n''est pas une question d''importance, c''est une question d''autonomie.',
   'L''idée est reformulée et le propos repart sur l''autonomie.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S12 / EXCELLENT
  ('1058a200-48c1-5d3a-b460-0e5587e2bc31', '79a0536c-c787-5098-8f8d-8d526e0eab1e', 'EXCELLENT',
   'Disons-le autrement : sans le français, on signe des papiers qu''on n''a pas lus et on dépend de quelqu''un pour chaque courrier. Ma voisine a attendu six mois un droit qu''elle avait, faute d''avoir compris une lettre. Ce n''est pas une question d''importance, c''est une question d''autonomie.',
   'La reprise remplace le mot, apporte un fait, et ouvre une suite claire.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S13 / INSUFFICIENT
  ('eab090e3-b09c-55b9-801c-b32fee7ddccd', '8097e787-04ab-50e2-b681-38a31144e610', 'INSUFFICIENT',
   'Ça dépend vraiment des gens, franchement. Certains aiment ça, d''autres pas du tout, donc ça dépend des gens et de leur caractère, je crois.',
   'La formule revient et le propos ne trouve aucune sortie.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S13 / EXPECTED
  ('d215c0c6-df02-537e-9174-3bd7ee4f17ae', '8097e787-04ab-50e2-b681-38a31144e610', 'EXPECTED',
   'Au fond, ce que je veux dire, c''est que ça dépend surtout du temps disponible. Une personne qui travaille en trois-huit ne peut pas s''engager le samedi, même si elle en a envie.',
   'La reprise transforme « ça dépend » en une condition précise : le propos repart.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S13 / EXCELLENT
  ('f9bf624c-c79f-5eba-8929-7e86e8380f44', '8097e787-04ab-50e2-b681-38a31144e610', 'EXCELLENT',
   'Au fond, ce que je veux dire, c''est que cela dépend moins du caractère que des horaires. Une personne en trois-huit ne peut pas s''engager tous les samedis, même très motivée. La vraie question, c''est donc de créer des missions de deux heures, à des horaires variables.',
   'La reprise déplace la condition et ouvre directement sur une proposition.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S14 / INSUFFICIENT
  ('26f6cf37-67e9-51e0-a43a-1751ec6c8d96', '814f0baa-ff8c-55fe-b402-a799df445fb6', 'INSUFFICIENT',
   'Il faut du temps, vraiment. Ça prend du temps, on ne peut pas aller plus vite, il faut laisser du temps au temps, c''est comme ça.',
   'La formule est répétée et même redoublée : le propos n''avance plus du tout.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S14 / EXPECTED
  ('8a299e7d-87cd-581d-a7a6-dea573161a26', '814f0baa-ff8c-55fe-b402-a799df445fb6', 'EXPECTED',
   'Plutôt que « du temps », disons qu''il faut une adresse stable, un compte en banque et un premier contrat. Tant que ces trois choses manquent, rien d''autre ne peut commencer.',
   'La formule vague devient une liste concrète : le propos repart.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S14 / EXCELLENT
  ('df620376-78d9-5484-840c-664ee73129be', '814f0baa-ff8c-55fe-b402-a799df445fb6', 'EXCELLENT',
   'Plutôt que « du temps », disons qu''il faut trois choses dans l''ordre : une adresse stable, un compte en banque, puis un premier contrat. Chacune conditionne la suivante, et c''est cet enchaînement qui prend dix-huit mois. Ce n''est pas la lenteur des gens, c''est l''ordre des démarches.',
   'La reprise remplace le mot par un mécanisme, puis écarte une fausse explication.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S15 / INSUFFICIENT
  ('758ae5c1-291c-5bef-96f3-547be9b9211d', '51051411-3c01-5c55-977d-2efe65cd5902', 'INSUFFICIENT',
   'C''est un endroit où… comment on dit… attendez… c''est le mot que je cherche… un truc comme… non, ça ne me revient pas, désolé.',
   'Tout s''arrête sur le mot manquant : l''idée n''est jamais dite.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S15 / EXPECTED
  ('4b26f87f-2559-57b2-8f0a-f321571a4d3a', '51051411-3c01-5c55-977d-2efe65cd5902', 'EXPECTED',
   'Je ne trouve pas le mot, mais l''idée, c''est que les gens du quartier cultivent chacun un petit morceau de terrain et se croisent en le faisant. C''est cela qui compte, plus que les légumes.',
   'Le mot est abandonné, l''idée est redite autrement, et le propos continue.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9-S15 / EXCELLENT
  ('4ef70380-7b97-5f47-8776-33d814891ec2', '51051411-3c01-5c55-977d-2efe65cd5902', 'EXCELLENT',
   'Je ne trouve pas le mot, mais l''idée, c''est que chacun cultive un petit morceau de terrain et croise les autres en venant arroser. Des gens qui ne se parlaient pas dans l''ascenseur discutent une heure entre deux rangs de tomates. C''est cela que je voulais dire.',
   'Le blocage est contourné en deux secondes et l''exemple relance le propos plus loin.', '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02');

-- --------------------------------------------------------------------------
-- 4. Filet — la migration echoue plutot que de livrer un catalogue faux.
--
-- 🛑 Borne aux competences d'EXPRESSION. V318 a seede six competences de
-- COMPREHENSION (CO-A2..CE-B2) : elles n'ont ni petit sujet ni point
-- d'apprentissage, et c'est voulu — le module Competences ne couvre que
-- EE et EO. Sans cette borne, le filet refuserait un catalogue correct.
-- --------------------------------------------------------------------------
DO $$
DECLARE
    manquants int;
    hors_contrat int;
BEGIN
    SELECT count(*) INTO manquants
      FROM skills
     WHERE is_active AND section IN ('EE', 'EO')
       AND (learning_points IS NULL OR jsonb_array_length(learning_points) <> 3);
    IF manquants > 0 THEN
        RAISE EXCEPTION 'V320 : % competence(s) active(s) sans 3 points d''apprentissage',
            manquants;
    END IF;

    SELECT count(*) INTO hors_contrat
      FROM (SELECT s.code, count(p.id) AS actifs
              FROM skills s
              LEFT JOIN skill_prompts p ON p.skill_id = s.id AND p.is_active
             WHERE s.is_active AND s.section IN ('EE', 'EO')
             GROUP BY s.code) t
     WHERE t.actifs <> 15;
    IF hors_contrat > 0 THEN
        RAISE EXCEPTION 'V320 : % competence(s) active(s) n''ont pas 15 sujets actifs',
            hors_contrat;
    END IF;

    SELECT count(*) INTO hors_contrat
      FROM (SELECT p.code, count(r.id) AS refs
              FROM skill_prompts p
              JOIN skills s ON s.id = p.skill_id AND s.is_active
                            AND s.section IN ('EE', 'EO')
              LEFT JOIN skill_references r ON r.skill_prompt_id = p.id
             WHERE p.is_active
             GROUP BY p.code) t
     WHERE t.refs <> 3;
    IF hors_contrat > 0 THEN
        RAISE EXCEPTION 'V320 : % sujet(s) actif(s) n''ont pas 3 references', hors_contrat;
    END IF;
END $$;
