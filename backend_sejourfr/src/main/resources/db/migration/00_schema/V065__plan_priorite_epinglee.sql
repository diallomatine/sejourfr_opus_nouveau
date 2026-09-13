-- ============================================================================
-- V065 — La priorite COURANTE du Plan, epinglee
-- ----------------------------------------------------------------------------
-- Une seule ligne par candidat : la competence que le Plan a designee en
-- premiere place, et depuis quand.
--
-- POURQUOI UNE TABLE, alors que TOUT le Plan est derive.
-- L'ordre des priorites se recalcule a chaque GET /api/me/plan a partir de
-- `learning_plan_observations` : statut, puis confiance, puis RECENCE. Une
-- production rendue sur une autre competence devenait donc, par sa seule
-- fraicheur, la nouvelle priorite n°1 — l'etape en cours disparaissait de
-- l'ecran au milieu de son cycle. Cas reel : EE3 « Developper un argument »
-- affichee a 0/5, remplacee par EO1 apres une production orale.
--
-- Ce fait-la n'est derivable de rien. « Quelle etape ce candidat a-t-il
-- commence » ne se lit ni dans les observations (l'etape sautait a 0/5, donc
-- aucun sujet traite a lire) ni dans la maitrise. C'est une DESIGNATION prise a
-- un instant, au meme titre qu'une observation : elle se persiste.
--
-- 🛑 CE QUI N'EST PAS ICI, ET NE DOIT JAMAIS Y ENTRER.
--   * La FILE d'attente. Le backlog reste entierement derive : PlanActionRanker
--     ordonne deja le pool ENTIER par score, une action par competence, sans
--     doublon par construction. Le persister serait une seconde autorite sur un
--     ordre que le moteur sait recalculer.
--   * L'ORDRE d'affichage, la nature de l'action, l'etat d'etape : derives
--     serveur, jamais persistes.
-- Cette table repond a UNE question et une seule : « laquelle etait la
-- premiere ? ».
--
-- LIBERATION. Aucune colonne d'etat, aucun `released_at` : la condition de
-- sortie est deja ecrite dans LearningPlanPriorityResolver.actionable(), qui
-- ecarte une competence dont le transfert est prouve OU dont la verification a
-- ete rendue. Tant que la competence epinglee est dans le pool, elle reste
-- premiere ; des qu'elle en sort, la ligne est reecrite sur la suivante. Un
-- `released_at` aurait duplique cette regle.
-- ============================================================================

CREATE TABLE plan_pinned_priorities
(
    user_id   uuid PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    skill_id  uuid        NOT NULL REFERENCES skills (id) ON DELETE CASCADE,
    pinned_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE plan_pinned_priorities IS
    'La competence en premiere place du Plan, epinglee jusqu''a la sortie de son cycle. '
        'Une ligne par candidat. La file des priorites suivantes reste derivee.';

COMMENT ON COLUMN plan_pinned_priorities.pinned_at IS
    'Quand cette competence a pris la premiere place. Sert la tracabilite, jamais un tri '
        '— l''ordre du reste appartient a PlanActionRanker.';
