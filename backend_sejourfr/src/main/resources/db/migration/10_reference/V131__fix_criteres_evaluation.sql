-- ============================================================================
-- V131 : Correction des grilles d'évaluation des 18 tâches d'expression.
-- ============================================================================
-- Objectifs :
--   1. Remplacer le critère "prononciation" (non mesurable par Whisper) par
--      "clarte_orale" (mesurable indirectement via la transcription).
--   2. Renforcer les consignes_correcteur pour clarifier la distinction entre
--      niveau ciblé par la tâche et niveau CECRL réellement atteint.
--   3. Ajouter un champ "marqueurs_niveau_superieur" qui aide le LLM à
--      identifier les productions qui dépassent le niveau cible.
--
-- Pourquoi : suite à un test utilisateur, un texte clairement B2 (riche,
-- nuancé, avec subordinations complexes) a été noté 17/20 mais classé B1
-- par le LLM, qui a aligné le niveau CECRL sur le niveau cible de la tâche
-- au lieu d'évaluer le niveau réel du candidat.
--
-- Stratégie : on utilise UPDATE par couple (epreuve, tache_numero, niveau_cible)
-- pour rester idempotent et indépendant des UUID générés en V130.
-- ============================================================================

-- ============================================================================
-- EO -- A2 / Tâche 1
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "A2",
  "consignes_correcteur": "Niveau A2 attendu sur la tâche. Le candidat doit pouvoir parler de lui-même avec des phrases simples. Tolérer les hésitations, les pauses, et les erreurs de conjugaison sur les temps autres que le présent. Valoriser un vocabulaire concret du quotidien. Couvrir au moins 3 thèmes parmi : nom/âge, nationalité, profession/études, ville, famille.",
  "marqueurs_niveau_superieur": "Si le candidat développe spontanément des subordonnées (parce que, quand, qui), utilise le passé composé correctement, varie le vocabulaire au-delà du minimum, et structure son propos de manière fluide → envisager B1. Si en plus il nuance, emploie l''imparfait pour le contexte, et fait des transitions naturelles → envisager B2."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND niveau_cible = 'A2';

-- ============================================================================
-- EO -- A2 / Tâche 2
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "A2",
  "consignes_correcteur": "Niveau A2 attendu sur la tâche. Le candidat doit poser des questions intelligibles. Vérifier qu''il sait formuler au moins 4 questions directes (Est-ce que / Combien / Comment / Quand) avec un vocabulaire pratique du contexte postal.",
  "marqueurs_niveau_superieur": "Si le candidat varie les structures interrogatives (inversion, intonation montante), utilise le conditionnel de politesse (je voudrais, pourriez-vous), reformule, ou demande des précisions → envisager B1. S''il négocie ou anticipe des cas de figure → envisager B2."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 2 AND niveau_cible = 'A2';

-- ============================================================================
-- EO -- A2 / Tâche 3
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "A2",
  "consignes_correcteur": "Niveau A2 attendu sur la tâche. Avis simple attendu. Le candidat doit donner son opinion avec des connecteurs basiques (parce que, mais, aussi). Pas d''exigence d''argumentation poussée. Vérifier la présence d''au moins 2 avantages et 1 inconvénient.",
  "marqueurs_niveau_superieur": "Si le candidat structure clairement (d''abord, ensuite, enfin), utilise des connecteurs variés (cependant, en revanche), donne des exemples concrets → envisager B1. S''il nuance, hiérarchise les arguments, ou exprime une position personnelle élaborée → envisager B2."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 3 AND niveau_cible = 'A2';

-- ============================================================================
-- EO -- B1 / Tâche 1
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "B1",
  "consignes_correcteur": "Niveau B1 attendu sur la tâche. Le candidat doit construire un discours suivi sur des sujets familiers, utiliser le passé composé et l''imparfait correctement, et marquer la causalité (parce que, donc, alors). Développement attendu sur au moins 3 axes : parcours, intérêts, motivations.",
  "marqueurs_niveau_superieur": "Si le candidat utilise des subordonnées complexes (bien que, alors que, tandis que), un lexique précis et nuancé, des connecteurs argumentatifs (en effet, par conséquent), exprime des nuances personnelles → envisager B2. Si en plus il manie le conditionnel passé, l''hypothèse, et un style soutenu → envisager C1."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND niveau_cible = 'B1';

-- ============================================================================
-- EO -- B1 / Tâche 2
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "B1",
  "consignes_correcteur": "Niveau B1 attendu sur la tâche. Le candidat doit exposer un problème, demander une action, et négocier. Vérifier l''emploi du conditionnel de politesse (je voudrais, pourriez-vous) et la capacité à reformuler. Au moins 3 questions ou demandes pertinentes attendues.",
  "marqueurs_niveau_superieur": "Si le candidat alterne registres (ferme mais courtois), anticipe la réponse de l''interlocuteur, propose plusieurs solutions, utilise le subjonctif (il faut que, je voudrais que) → envisager B2. S''il maîtrise le discours indirect, les nuances diplomatiques, et un lexique commercial précis (geste commercial, dédommagement) → envisager C1."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 2 AND niveau_cible = 'B1';

-- ============================================================================
-- EO -- B1 / Tâche 3
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "B1",
  "consignes_correcteur": "Niveau B1 attendu sur la tâche. Le candidat doit prendre position avec au moins deux arguments et des exemples. Vérifier les connecteurs argumentatifs (d''abord, ensuite, en effet, par exemple) et la cohérence du point de vue.",
  "marqueurs_niveau_superieur": "Si le candidat structure en trois temps (thèse / arguments / conclusion), nuance sa position, traite une objection, utilise un lexique abstrait → envisager B2. S''il manie l''antithèse, les concessions élaborées (certes... néanmoins), un style rhétorique → envisager C1."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 3 AND niveau_cible = 'B1';

-- ============================================================================
-- EO -- B2 / Tâche 1
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "B2",
  "consignes_correcteur": "Niveau B2 attendu sur la tâche. Le candidat doit présenter un parcours avec recul et analyse, utiliser des subordonnées complexes, et exprimer des nuances. Au moins 4 axes développés (parcours, motivations, choix, projection).",
  "marqueurs_niveau_superieur": "Si le candidat maîtrise un style fluide et personnel, utilise des expressions idiomatiques justes, exprime des subtilités émotionnelles, manie le conditionnel passé (j''aurais pu, il aurait fallu que) → envisager C1. S''il déploie un discours littéraire ou un registre soutenu sans effort → envisager C2."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 1 AND niveau_cible = 'B2';

-- ============================================================================
-- EO -- B2 / Tâche 2
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "B2",
  "consignes_correcteur": "Niveau B2 attendu sur la tâche. Jeu de rôle exigeant : le candidat doit négocier, anticiper, reformuler avec un registre adapté. Vérifier la maîtrise du subjonctif après expression de volonté/nécessité, l''emploi du discours indirect, et la précision lexicale du domaine concerné.",
  "marqueurs_niveau_superieur": "Si le candidat manie la concession élaborée (j''entends bien votre position mais...), adapte finement son registre, utilise des formules idiomatiques de la négociation, propose des solutions créatives → envisager C1. S''il atteint un naturel comparable à un locuteur natif → envisager C2."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 2 AND niveau_cible = 'B2';

-- ============================================================================
-- EO -- B2 / Tâche 3
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",   "label": "Pertinence du contenu",       "poids": 0.30},
    {"code": "grammaire",    "label": "Correction grammaticale",     "poids": 0.25},
    {"code": "vocabulaire",  "label": "Richesse lexicale",           "poids": 0.20},
    {"code": "coherence",    "label": "Cohérence du discours",       "poids": 0.15},
    {"code": "clarte_orale", "label": "Clarté et fluidité",          "poids": 0.10}
  ],
  "niveau_attendu": "B2",
  "consignes_correcteur": "Niveau B2 attendu sur la tâche. Argumentation construite et nuancée avec traitement explicite d''une objection. Vérifier les connecteurs concessifs (certes... toutefois, bien que, néanmoins), le lexique abstrait, et l''emploi du subjonctif après expressions de doute ou de nécessité.",
  "marqueurs_niveau_superieur": "Si le candidat manie l''antithèse rhétorique, mobilise un lexique conceptuel précis (paradoxe, causalité, dialectique), construit un raisonnement original avec une chute marquante → envisager C1. S''il déploie un style personnel et fluide proche d''un essai littéraire → envisager C2."
}'::jsonb
WHERE epreuve = 'TCF_EO' AND tache_numero = 3 AND niveau_cible = 'B2';

-- ============================================================================
-- EE -- A2 / Tâche 1
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "A2",
  "consignes_correcteur": "Niveau A2 attendu sur la tâche. Message simple à un ami. Le candidat doit utiliser des formules d''ouverture et de clôture simples (Bonjour, à bientôt), parler de sa vie quotidienne au présent et au passé composé. Tolérer les erreurs qui ne gênent pas la compréhension.",
  "marqueurs_niveau_superieur": "Si le candidat développe des paragraphes structurés, utilise l''imparfait pour le contexte, varie le lexique, et exprime des sentiments nuancés → envisager B1. S''il manie le conditionnel, les subordonnées, et un registre fluide → envisager B2."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 1 AND niveau_cible = 'A2';

-- ============================================================================
-- EE -- A2 / Tâche 2
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "A2",
  "consignes_correcteur": "Niveau A2 attendu sur la tâche. Récit simple d''un événement récent. Vérifier l''emploi correct du passé composé et la présence de marqueurs temporels (hier, ce matin, il y a deux jours).",
  "marqueurs_niveau_superieur": "Si le candidat alterne passé composé et imparfait correctement, structure son récit en plusieurs étapes, utilise des connecteurs temporels variés → envisager B1. S''il introduit du discours indirect, des descriptions élaborées, ou une dimension réflexive → envisager B2."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 2 AND niveau_cible = 'A2';

-- ============================================================================
-- EE -- A2 / Tâche 3
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "A2",
  "consignes_correcteur": "Niveau A2 attendu sur la tâche. Opinion simple + deux raisons. Le candidat doit savoir introduire son avis (je pense que, pour moi) et justifier (parce que, c''est pourquoi).",
  "marqueurs_niveau_superieur": "Si le candidat développe une argumentation avec exemples, utilise des connecteurs variés, exprime une nuance → envisager B1. S''il traite une objection, manie la concession (cependant, néanmoins), ou utilise un lexique abstrait → envisager B2."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 3 AND niveau_cible = 'A2';

-- ============================================================================
-- EE -- B1 / Tâche 1
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "B1",
  "consignes_correcteur": "Niveau B1 attendu sur la tâche. Récit court avec une dimension subjective. Vérifier l''alternance passé composé / imparfait pour distinguer événement et contexte.",
  "marqueurs_niveau_superieur": "Si le candidat utilise le plus-que-parfait pour l''antériorité, des subordonnées complexes, exprime des émotions nuancées avec un lexique précis, structure un récit avec chute → envisager B2. S''il déploie un style personnel et littéraire, des métaphores accessibles, une analyse réflexive marquante → envisager C1."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 1 AND niveau_cible = 'B1';

-- ============================================================================
-- EE -- B1 / Tâche 2
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "B1",
  "consignes_correcteur": "Niveau B1 attendu sur la tâche. Récit structuré en trois temps (contexte / événement / leçon retirée). Vérifier la progression contextuelle (au départ, ensuite, finalement) et la présence d''une analyse personnelle.",
  "marqueurs_niveau_superieur": "Si le récit présente des subordinations complexes (pendant que, alors que), un lexique nuancé (submergé, bouleversé, marquant), une réflexion personnelle aboutie avec chute conceptuelle → envisager B2. S''il manie un style littéraire, des métaphores originales, une introspection profonde → envisager C1."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 2 AND niveau_cible = 'B1';

-- ============================================================================
-- EE -- B1 / Tâche 3
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "B1",
  "consignes_correcteur": "Niveau B1 attendu sur la tâche. Argumentation en deux temps avec illustration. Vérifier les connecteurs (en effet, par exemple, d''ailleurs) et le maintien d''un point de vue clair du début à la fin.",
  "marqueurs_niveau_superieur": "Si le candidat traite une objection, manie les concessions (certes... toutefois), utilise un lexique abstrait précis, structure en trois temps argumentatifs → envisager B2. S''il déploie un raisonnement original, des références culturelles, un style rhétorique → envisager C1."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 3 AND niveau_cible = 'B1';

-- ============================================================================
-- EE -- B2 / Tâche 1
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "B2",
  "consignes_correcteur": "Niveau B2 attendu sur la tâche. Registre formel mais ferme. Vérifier les formules d''appel et de clôture, le conditionnel de politesse, et la précision du vocabulaire commercial (prestation, dédommagement, geste commercial).",
  "marqueurs_niveau_superieur": "Si le candidat manie un style soutenu sans effort, utilise des formules idiomatiques juridiques ou commerciales, structure son argumentation avec finesse rhétorique → envisager C1. S''il atteint un niveau proche d''un courrier rédigé par un professionnel natif → envisager C2."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 1 AND niveau_cible = 'B2';

-- ============================================================================
-- EE -- B2 / Tâche 2
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "B2",
  "consignes_correcteur": "Niveau B2 attendu sur la tâche. Récit réflexif sur une décision difficile. Vérifier l''emploi du plus-que-parfait (action antérieure), du conditionnel passé (regret/projection), et la capacité à prendre du recul sur l''expérience.",
  "marqueurs_niveau_superieur": "Si le candidat déploie un style personnel et fluide, des métaphores justes, une introspection nuancée, un lexique psychologique précis → envisager C1. S''il atteint une qualité littéraire (rythme, chute, originalité de l''angle) → envisager C2."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 2 AND niveau_cible = 'B2';

-- ============================================================================
-- EE -- B2 / Tâche 3
-- ============================================================================
UPDATE production_tasks
SET criteres_evaluation = '{
  "criteres": [
    {"code": "pertinence",  "label": "Pertinence du contenu",   "poids": 0.30},
    {"code": "grammaire",   "label": "Correction grammaticale", "poids": 0.30},
    {"code": "vocabulaire", "label": "Richesse lexicale",       "poids": 0.20},
    {"code": "coherence",   "label": "Cohérence du discours",   "poids": 0.20}
  ],
  "niveau_attendu": "B2",
  "consignes_correcteur": "Niveau B2 attendu sur la tâche. Argumentation en trois temps (thèse + arguments + objection traitée). Vérifier les connecteurs concessifs (certes... toutefois, bien que, néanmoins) et la précision conceptuelle (apprentissage personnalisé, automatisation, biais).",
  "marqueurs_niveau_superieur": "Si le candidat construit un raisonnement original, mobilise des références (auteurs, exemples historiques), nuance avec finesse, manie l''antithèse rhétorique → envisager C1. S''il déploie un style essayistique mature, une dialectique aboutie, et une qualité d''écriture proche d''un éditorial → envisager C2."
}'::jsonb
WHERE epreuve = 'TCF_EE' AND tache_numero = 3 AND niveau_cible = 'B2';

-- ============================================================================
-- Assertion : vérifier que les 18 tâches ont bien été mises à jour
-- ============================================================================
DO $$
DECLARE
expected_count INT := 18;
  actual_count INT;
BEGIN
SELECT COUNT(*) INTO actual_count
FROM production_tasks
WHERE criteres_evaluation ? 'marqueurs_niveau_superieur';

IF actual_count <> expected_count THEN
    RAISE EXCEPTION 'V131 attendait % tâches mises à jour, en a trouvé %', expected_count, actual_count;
END IF;
END $$;