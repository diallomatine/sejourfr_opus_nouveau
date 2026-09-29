-- Le funnel diagnostic réutilise le compteur agrégé anonyme page_views.
-- Le nom le plus long (PLAN_RECOMMENDED_EXERCISE_STARTED) dépasse varchar(20).
-- Aucune donnée personnelle ni nouvelle dimension libre n'est ajoutée.
ALTER TABLE page_views
    ALTER COLUMN event TYPE varchar(64);

COMMENT ON COLUMN page_views.event IS
    'Événement allowlisté par PageViewService, agrégé par page/source/jour.';
