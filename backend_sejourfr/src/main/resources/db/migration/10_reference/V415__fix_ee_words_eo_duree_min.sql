-- Corrige les bornes officielles TCF IRN des productions.
--
-- Expression Écrite (EE) : les bornes seedées en V130 (60-120 / 120-150 /
-- 150-180) étaient erronées. Bornes officielles :
--   Tâche 1 : 30-60 mots
--   Tâches 2 et 3 : 40-90 mots
UPDATE production_tasks SET mots_min = 30, mots_max = 60
  WHERE epreuve = 'TCF_EE' AND tache_numero = 1;
UPDATE production_tasks SET mots_min = 40, mots_max = 90
  WHERE epreuve = 'TCF_EE' AND tache_numero IN (2, 3);

-- Expression Orale (EO) : seuil minimal acceptable = 120 s (2 min) pour toutes
-- les tâches. La cible affichée reste duree_max_sec (180 / 210 s).
UPDATE production_tasks SET duree_min_sec = 120 WHERE epreuve = 'TCF_EO';
