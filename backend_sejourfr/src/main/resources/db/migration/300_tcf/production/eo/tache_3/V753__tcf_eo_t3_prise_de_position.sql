-- ============================================================================
-- V753 — TCF EO T3 · bande A2 : les sujets appellent une PRISE DE POSITION
-- ----------------------------------------------------------------------------
-- Défaut corrigé : la rubrique EO_T3 (production-rubrics-v8.json,
-- consignes_correcteur) exige « une prise de position ET des arguments
-- développés ET un monologue organisé » et demande explicitement de
-- « pénaliser le propos purement descriptif » ; son descripteur B2 exige une
-- objection envisagée puis traitée. Or six sujets de la bande A2 imposaient au
-- candidat, en point OBLIGATOIRE, de décrire ou de raconter :
--
--   · 3001-…0001 « Dites où elle se trouve […] racontez un souvenir »
--   · 3001-…0005 « Dites quel sport vous pratiquez […] racontez un exemple »
--   · 3001-…0006 « décrivez un voyage que vous avez fait »
--   · 3002-…0003 « Que faites-vous […] ? Présentez deux gestes »
--   · 3002-…0006 « racontez un moment de votre vie quotidienne »
--   · 3002-…0007 « décrivez un plat précis : ses ingrédients […] »
--
-- Le candidat était donc pénalisé pour avoir fait exactement ce que le sujet
-- lui demandait, et ne pouvait démontrer aucun marqueur B2 — T3 étant la seule
-- tâche où ces marqueurs s'observent. C'est un défaut de CONTENU, pas de
-- notation : aucune règle de notation n'est modifiée ici.
--
-- Correction retenue : RÉÉCRITURE de la consigne, thème conservé.
--   · Pas de reclassement vers T1/T2 : EO T1 est l'entretien dirigé « se
--     présenter » joué en temps réel (pool d'un seul sujet par niveau) et EO T2
--     le jeu de rôle ; y déplacer un monologue serait faux, changerait la
--     composition de tous les examens (index modulo la taille du pool) et
--     ferait chuter le compte de tâches distinctes des attempts historiques
--     (auto-finalisation d'épreuve).
--   · Pas de désactivation/remplacement : GET /api/production-tasks/{id}
--     (ProductionTaskService.getActiveTask) renvoie 404 sur une tâche
--     is_active = false — les deux fronts s'en servent pour réafficher le sujet
--     d'une production passée ; désactiver casserait l'écran de résultat.
--   · Rien n'est supprimé : mêmes ids, même épreuve, même tache_numero, même
--     niveau_cible, mêmes bornes de durée, même is_active. Les
--     production_submissions existantes restent rattachées et lisibles. La
--     formulation d'origine reste dans V750/V751/V752 (retour arrière = un
--     UPDATE symétrique).
--
-- Forme cible, celle que les en-têtes de V751/V752 déclaraient déjà pour la
-- bande A2 (« A2 = position + 2 raisons + exemple ») et que 3001-…0004 et
-- 91d0f63c respectaient seuls : question tranchable → choix/opinion explicite
-- → deux raisons → un exemple précis qui ILLUSTRE l'argument (l'exemple vécu
-- des anciennes consignes est conservé à ce titre, il n'est plus la finalité).
--
-- Idempotent, borné à six ids explicites.
-- ============================================================================

-- 3001-…0001 · thème : la ville que l'on préfère
UPDATE production_tasks
SET consigne = 'On dit souvent qu''on est toujours mieux dans la ville où l''on a grandi. Êtes-vous d''accord ? Donnez votre opinion, expliquez deux raisons et donnez un exemple précis vécu dans la ville que vous préférez pour illustrer votre point de vue.'
WHERE id = '88888888-3001-1000-0000-000000000001'::uuid
  AND epreuve = 'TCF_EO' AND tache_numero = 3;

-- 3001-…0005 · thème : le sport
UPDATE production_tasks
SET consigne = 'Selon vous, faut-il faire du sport chaque semaine pour rester en bonne santé ? Donnez votre opinion, expliquez deux raisons et donnez un exemple précis de votre vie (un match, une séance, une promenade) pour illustrer votre point de vue.'
WHERE id = '88888888-3001-1000-0000-000000000005'::uuid
  AND epreuve = 'TCF_EO' AND tache_numero = 3;

-- 3001-…0006 · thème : les voyages
UPDATE production_tasks
SET consigne = 'Selon vous, faut-il voyager loin pour passer de bonnes vacances ? Donnez votre opinion, expliquez deux raisons et donnez un exemple précis (un voyage que vous avez fait, des vacances près de chez vous) pour illustrer votre point de vue.'
WHERE id = '88888888-3001-1000-0000-000000000006'::uuid
  AND epreuve = 'TCF_EO' AND tache_numero = 3;

-- 3002-…0003 · thème : les gestes pour l'environnement
UPDATE production_tasks
SET consigne = 'Selon vous, les gestes de chacun (trier ses déchets, économiser l''eau, marcher au lieu de prendre la voiture) suffisent-ils à protéger l''environnement ? Donnez votre opinion, expliquez deux raisons et donnez un exemple précis de votre quotidien pour illustrer votre point de vue.'
WHERE id = '88888888-3002-1000-0000-000000000003'::uuid
  AND epreuve = 'TCF_EO' AND tache_numero = 3;

-- 3002-…0006 · thème : habiter seul ou en famille (seule la fin change)
UPDATE production_tasks
SET consigne = 'Préférez-vous habiter seul ou avec votre famille ? Donnez votre choix, expliquez deux raisons (la liberté, la compagnie, le partage des tâches, le prix du logement...) et donnez un exemple précis de votre vie quotidienne pour illustrer votre préférence.'
WHERE id = '88888888-3002-1000-0000-000000000006'::uuid
  AND epreuve = 'TCF_EO' AND tache_numero = 3;

-- 3002-…0007 · thème : cuisine du pays d'origine ou cuisine locale
UPDATE production_tasks
SET consigne = 'Préférez-vous manger les plats de votre pays d''origine ou découvrir la cuisine du pays où vous vivez ? Donnez votre choix, expliquez deux raisons et donnez un exemple précis (un plat, un repas, une habitude) pour illustrer votre préférence.'
WHERE id = '88888888-3002-1000-0000-000000000007'::uuid
  AND epreuve = 'TCF_EO' AND tache_numero = 3;
