-- L'estimation CECRL des QCM TCF a changé : score calibré corrigé du hasard
-- (ligne de base 25 % d'un QCM à 4 choix), niveau = bande du score, niveau
-- global d'un examen = plancher des épreuves (règle TCF IRN). Les niveaux
-- stockés sous l'ancienne règle « garde-fou palier » ne correspondent plus :
-- on les invalide pour forcer la re-dérivation cohérente depuis le score
-- pondéré à la lecture (AttemptMapper.cecrlLevelOf).
UPDATE attempts
SET cecrl_level = NULL
WHERE module = 'TCF'
  AND cecrl_level IS NOT NULL;
