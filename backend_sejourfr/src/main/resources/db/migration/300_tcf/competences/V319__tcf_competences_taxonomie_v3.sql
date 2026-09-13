-- ==========================================================================
-- V319 — Taxonomie V3 des 48 competences d'expression
--
-- Passage de la taxonomie publiee (V300-V317) a la taxonomie V3, validee
-- par le proprietaire le 2026-09-13. Reference : docs/taxonomie-competences-v3.md
--
-- FICHIER GENERE — NE PAS EDITER A LA MAIN.
--   cd backend_sejourfr && python3 tools/competences/taxonomie_v3.py
--
-- 7 competences RETIREES (is_active = false, rang range au-dela de 8),
-- 7 CREEES, 19 RECENTREES (titre et/ou critere), 1 tache reordonnee (EO3).
-- Les 48 rangs actifs restent 48.
--
-- 🛑 AUCUNE SUPPRESSION. Une competence sur laquelle un candidat a produit
-- emporterait ses sujets en cascade, donc son historique. Le geste est la
-- DESACTIVATION : elle sort du catalogue, tout est conserve.
--
-- 🛑 Desactiver ne libere PAS le rang : uq_skills_task_order ne filtre pas
-- is_active. Chaque retiree est donc rangee au-dela de 8 (le CHECK va
-- jusqu'a 50), sinon la place ne serait pas reutilisable.
--
-- Le reordonnancement tient en UNE transaction : uq_skills_task_order est
-- DEFERRABLE INITIALLY DEFERRED (V025), donc les collisions transitoires ne
-- sont verifiees qu'au COMMIT.
--
-- 🛑 Les competences CREEES portent un code NEUF (C9, C10, C11) — jamais
-- celui d'une retiree, qui rattacherait un contenu neuf a l'historique
-- d'une autre compétence.
--
-- ⚠️ Leurs SUJETS arrivent par une migration separee : une competence sans
-- petit sujet s'affiche a zero, elle ne casse rien.
-- ==========================================================================

-- --------------------------------------------------------------------------
-- 1. Les 7 competences RETIREES — desactivees et rangees au-dela de 8.
-- --------------------------------------------------------------------------

-- EE1-C4 — Demander une information, une aide ou une autorisation n'est pas décrire. Acte transactionnel, hors du périmètre de la tâche 1 IRN — sa place est en EO2.
UPDATE skills
   SET is_active = false, display_order = 9, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE1-C4';

-- EE1-C5 — Inviter, proposer, accepter ou refuser : acte transactionnel du format TCF « tout public », sans rapport avec la description.
UPDATE skills
   SET is_active = false, display_order = 10, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE1-C5';

-- EE1-C6 — S'excuser n'est ni décrire une personne, ni un groupe, ni un lieu, ni un objet.
UPDATE skills
   SET is_active = false, display_order = 11, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE1-C6';

-- EE2-C4 — « Introduire un événement déclencheur » suppose un récit à péripétie, alors que la tâche 2 couvre aussi les activités quotidiennes et le compte rendu d'expérience.
UPDATE skills
   SET is_active = false, display_order = 9, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE2-C4';

-- EE3-C6 — La tâche 3 IRN ne demande ni de comparer deux documents, ni d'opposer systématiquement deux possibilités. Non structurante.
UPDATE skills
   SET is_active = false, display_order = 9, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE3-C6';

-- EO2-C4 — « Demander les conditions et les modalités » disait la même chose que « Demander des informations pratiques ». Fondue dans le rang 3 ; la place libérée va à l'interaction imprévue.
UPDATE skills
   SET is_active = false, display_order = 9, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO2-C4';

-- EO3-C6 — Décalque de EE3-C6, non structurante à l'oral. Remplacée par une compétence mesurable dans la transcription (EO3-C9).
UPDATE skills
   SET is_active = false, display_order = 9, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO3-C6';

-- --------------------------------------------------------------------------
-- 2. Les 19 competences RECENTREES et les rangs qui bougent.
--
-- Un titre ou un critere qui change ne change PAS l'identite de la ligne :
-- ses sujets, ses references et les observations des candidats restent
-- attaches. Le contenu qui ne correspondrait plus est repris ailleurs.
-- --------------------------------------------------------------------------

-- --- EE1 -------------------------------------------------------------------
-- EE1-C2 → « Répondre précisément à la demande du message » (rang 1)
UPDATE skills
   SET title = 'Répondre précisément à la demande du message',
       description = 'La tâche 1 part toujours d''un message reçu. Cette compétence entraîne la lecture de ce qu''il demande, et la réponse à cette demande-là — sans s''écarter vers ce qu''on aurait envie de raconter.',
       general_criterion = 'Identifier ce que le message reçu demande, et y répondre sans s''écarter.',
       display_order = 1,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE1-C2';

-- EE1-C1 → « Adapter la réponse au destinataire » (rang 2)
UPDATE skills
   SET title = 'Adapter la réponse au destinataire',
       description = 'On ne répond pas de la même façon à un ami, à un voisin ou à un service. Cette compétence entraîne le choix du ton, du tutoiement ou du vouvoiement et des formules, que le TCF observe dès la première ligne.',
       general_criterion = 'Choisir le ton, le tutoiement ou le vouvoiement et les formules qui conviennent à la personne qui a écrit.',
       display_order = 2,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE1-C1';

-- EE1-C7 → « Décrire une personne ou un groupe » (rang 5)
UPDATE skills
   SET title = 'Décrire une personne ou un groupe',
       description = 'Faire voir quelqu''un à quelqu''un d''autre : son aspect, son âge, son caractère, son rôle. Un groupe se décrit aussi — sa composition, son ambiance —, et c''est l''un des quatre objets que la tâche 1 peut demander.',
       general_criterion = 'Donner l''aspect, l''âge, le caractère, le rôle, ou la composition et l''ambiance d''un groupe.',
       display_order = 5,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE1-C7';

-- EE1-C3 → « Donner des détails concrets et précis » (rang 7)
UPDATE skills
   SET title = 'Donner des détails concrets et précis',
       description = 'Une description vague ne montre rien. Cette compétence entraîne l''appui sur des éléments vérifiables — une couleur, un nombre, un emplacement, un moment — plutôt que sur des adjectifs passe-partout.',
       general_criterion = 'Appuyer la description sur des éléments vérifiables — couleur, nombre, emplacement, moment — plutôt que sur des mots vagues.',
       display_order = 7,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE1-C3';

-- EE1-C8 → « Relier les informations dans une description cohérente » (rang 8)
UPDATE skills
   SET title = 'Relier les informations dans une description cohérente',
       description = 'Trente à soixante mots, c''est court : l''ordre des phrases fait la différence entre une description qui se suit et une liste de détails jetés. Cette compétence entraîne l''enchaînement et la clôture.',
       general_criterion = 'Enchaîner les phrases dans un ordre lisible et refermer la description naturellement.',
       display_order = 8,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE1-C8';

-- --- EE2 -------------------------------------------------------------------
-- EE2-C2 → « Présenter la situation et les personnes » (rang 2)
UPDATE skills
   SET title = 'Présenter la situation et les personnes',
       description = 'Après le repère de temps et de lieu, le lecteur a besoin de savoir avec qui l''on était et ce que l''on faisait. Cette compétence entraîne le cadre humain du récit, sans redire ce que la première phrase a déjà posé.',
       general_criterion = 'Dire avec qui l''on était et ce que l''on faisait, sans redire le moment ni le lieu.',
       display_order = 2,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE2-C2';

-- EE2-C3 → « Utiliser les temps du passé de manière compréhensible » (rang 3)
UPDATE skills
   SET title = 'Utiliser les temps du passé de manière compréhensible',
       description = 'Un récit se tient au passé, et ce qui avance ne se dit pas comme ce qui décrit autour. Cette compétence entraîne cette distinction — sans imposer une forme grammaticale plutôt qu''une autre.',
       general_criterion = 'Employer les temps du passé de manière cohérente pour distinguer les actions du contexte.',
       display_order = 3,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE2-C3';

-- EE2-C8 → « Terminer par le résultat ou ce que cela a apporté » (rang 8)
UPDATE skills
   SET title = 'Terminer par le résultat ou ce que cela a apporté',
       description = 'Un récit se referme. Cette compétence entraîne la dernière phrase — comment cela s''est terminé, ou ce que cela a changé — sans exiger un dénouement spectaculaire que la plupart des expériences quotidiennes n''ont pas.',
       general_criterion = 'Dire comment la situation s''est terminée ou ce qu''elle a changé — un résultat spectaculaire n''est pas exigé.',
       display_order = 8,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE2-C8';

-- --- EE3 -------------------------------------------------------------------
-- EE3-C1 → « Exprimer une position claire » (rang 1)
UPDATE skills
   SET title = 'Exprimer une position claire',
       description = 'La tâche 3 demande un avis sur un lieu, un objet, une personne ou un groupe. Cette compétence entraîne la position identifiable, posée sur cet objet-là et pas sur un débat général.',
       general_criterion = 'Répondre directement à la question posée sur ce lieu, cet objet, cette personne ou ce groupe, et rendre son avis identifiable.',
       display_order = 1,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE3-C1';

-- EE3-C5 → « Faire progresser son propos sans se répéter » (rang 5)
UPDATE skills
   SET title = 'Faire progresser son propos sans se répéter',
       description = 'En quarante à quatre-vingt-dix mots, on n''empile pas des arguments : on avance. Cette compétence entraîne l''idée qui fait progresser, sans quota d''arguments ni retour sur ce qui vient d''être dit.',
       general_criterion = 'Apporter une idée nouvelle qui avance — sans quota d''arguments ni retour sur la précédente.',
       display_order = 5,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE3-C5';

-- EE3-C7 → « Nuancer ou reconnaître une limite » (rang 7)
UPDATE skills
   SET title = 'Nuancer ou reconnaître une limite',
       description = 'Reconnaître une exception ou un avis opposé sans renoncer à sa position : c''est le marqueur de niveau le plus rentable de la tâche 3. Cette compétence l''entraîne comme une possibilité, jamais comme un passage obligé.',
       general_criterion = 'Pouvoir concéder une exception ou un avis opposé sans perdre sa position — une possibilité de haut niveau, jamais un passage obligé.',
       display_order = 7,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE3-C7';

-- EE3-C8 → « Enchaîner ses idées de façon cohérente » (rang 8)
UPDATE skills
   SET title = 'Enchaîner ses idées de façon cohérente',
       description = 'Ce qui se lit, en quatre-vingt-dix mots, c''est l''enchaînement — pas une conclusion de dissertation. Cette compétence entraîne les liens justes entre les idées, et une fin qui n''a pas besoin d''être annoncée.',
       general_criterion = 'Relier les idées avec des connecteurs justes ; une conclusion formelle n''est pas exigée.',
       display_order = 8,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EE3-C8';

-- --- EO1 -------------------------------------------------------------------
-- EO1-C6 → « Raconter brièvement une expérience passée » (rang 6)
UPDATE skills
   SET title = 'Raconter brièvement une expérience passée',
       description = 'L''entretien dirigé porte surtout sur le présent, mais l''examinateur demande parfois un souvenir. Cette compétence entraîne le récit court — sans basculer dans le récit développé, qui est la tâche 2.',
       general_criterion = 'Répondre à une question personnelle par un récit court, sans basculer dans le récit développé de la tâche 2.',
       display_order = 6,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO1-C6';

-- --- EO2 -------------------------------------------------------------------
-- EO2-C3 → « Demander les informations et les conditions » (rang 3)
UPDATE skills
   SET title = 'Demander les informations et les conditions',
       description = 'Prix, horaire, documents, inscription, règles : tout ce qu''il faut savoir pour agir. Cette compétence réunit ce que deux compétences disaient séparément — demander un renseignement et demander une modalité sont le même geste.',
       general_criterion = 'Obtenir ce qu''il faut savoir pour agir : prix, horaire, lieu, durée, documents, inscription, règles, services inclus.',
       display_order = 3,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO2-C3';

-- EO2-C7 → « Explorer plusieurs possibilités » (rang 7)
UPDATE skills
   SET title = 'Explorer plusieurs possibilités',
       description = 'Interroger les options et leurs différences fait partie de l''obtention d''informations. Trancher, non : l''objectif officiel de la tâche 2 est d''obtenir, pas de choisir.',
       general_criterion = 'Interroger plusieurs options et leurs différences — trancher n''est pas exigé.',
       display_order = 7,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO2-C7';

-- --- EO3 -------------------------------------------------------------------
-- EO3-C1 → « Annoncer une position claire » (rang 1)
UPDATE skills
   SET title = 'Annoncer une position claire',
       description = 'La tâche 3 pose une question et attend un avis. Cette compétence entraîne la position identifiable — sans exiger un temps de réaction que notre correcteur, qui travaille sur la transcription, ne mesure pas.',
       general_criterion = 'Répondre clairement à la question et rendre son opinion identifiable.',
       display_order = 1,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO3-C1';

-- EO3-C8 → « Tenir un discours continu et organisé » (rang 2)
UPDATE skills
   SET title = 'Tenir un discours continu et organisé',
       description = 'C''est la caractéristique explicite de la tâche 3 orale, et ce qui la distingue le plus de l''écrit : parler de manière continue. Cette compétence entraîne le propos suivi, nourri et lié — remontée au rang 2 pour cette raison.',
       general_criterion = 'Développer un propos suivi, organisé et suffisamment nourri, avec des reprises et des liens clairs entre les idées.',
       display_order = 2,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO3-C8';

-- EO3-C5 → « Enchaîner une idée nouvelle » (rang 6)
UPDATE skills
   SET title = 'Enchaîner une idée nouvelle',
       description = 'À l''oral, l''enjeu n''est pas de compter les arguments mais de faire avancer le propos. Cette compétence entraîne l''idée qui ajoute, sans quota ni retour sur la précédente.',
       general_criterion = 'Apporter une idée qui fait avancer le propos, sans quota d''arguments ni retour sur la précédente.',
       display_order = 6,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO3-C5';

-- EO3-C7 → « Nuancer ou reconnaître une limite » (rang 8)
UPDATE skills
   SET title = 'Nuancer ou reconnaître une limite',
       description = 'Introduire une réserve ou une concession sans perdre sa position : réellement B2, et parfaitement tenable à l''oral.',
       general_criterion = 'Introduire une réserve, une concession ou une exception sans perdre sa position.',
       display_order = 8,
       updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO3-C7';

-- Rangs qui bougent sans que le texte change (EO3 est reordonnee : sa
-- compétence de continuité remonte du rang 8 au rang 2).
UPDATE skills
   SET display_order = 3, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO3-C2';
UPDATE skills
   SET display_order = 4, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO3-C3';
UPDATE skills
   SET display_order = 5, updated_at = '2026-09-13 09:00:00+02'
 WHERE code = 'EO3-C4';

-- --------------------------------------------------------------------------
-- 3. Les 7 competences CREEES.
--
-- UUID deterministes (uuid5 sur le code metier), meme namespace que
-- generer_seed.py : l'identifiant est le meme sur toutes les bases.
-- --------------------------------------------------------------------------

INSERT INTO skills (id, section, task_code, code, title, description,
                    general_criterion, target_level, display_order, is_active,
                    created_at, updated_at)
VALUES
  -- EE1-C9 — Identifier clairement ce qui est décrit
  ('93877065-0626-53d0-a39d-8b07cc2eb866', 'EE', 'EE1', 'EE1-C9', 'Identifier clairement ce qui est décrit',
   'Avant de décrire, il faut dire de quoi on parle. Cette compétence entraîne l''annonce nette de ce que le message demande de décrire — une personne, un groupe, un lieu ou un objet — pour que le lecteur sache tout de suite de quoi il s''agit.',
   'Nommer sans ambiguïté la personne, le groupe, le lieu ou l''objet dont il est question.',
   'A2', 3, true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C10 — Sélectionner les caractéristiques pertinentes
  ('3b47e1c7-3fb4-5e34-8532-8100cb808e0b', 'EE', 'EE1', 'EE1-C10', 'Sélectionner les caractéristiques pertinentes',
   'En trente à soixante mots, on ne peut pas tout dire. Cette compétence entraîne le choix : retenir les quelques traits qui comptent pour celui qui lit, et laisser le reste de côté.',
   'Choisir les quelques traits qui comptent pour le lecteur, plutôt que d''énumérer tout ce qu''on pourrait dire.',
   'A2', 4, true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE1-C11 — Décrire un lieu ou un objet
  ('c710b2a2-016b-5ef0-a2ef-3d1ba7c79f18', 'EE', 'EE1', 'EE1-C11', 'Décrire un lieu ou un objet',
   'Faire voir un endroit ou une chose à quelqu''un qui ne l''a pas sous les yeux. Cette compétence entraîne le vocabulaire de l''espace, de la forme, de la matière et de l''usage.',
   'Situer et caractériser un lieu ou un objet : aspect, taille, matière, ambiance, usage, état.',
   'A2', 6, true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE2-C9 — Expliquer une action, un choix ou une réaction
  ('09c9e44a-6939-551d-afc3-3d3d05770cb6', 'EE', 'EE2', 'EE2-C9', 'Expliquer une action, un choix ou une réaction',
   'Raconter ce qui s''est passé ne suffit pas : le candidat est officiellement évalué sur sa capacité à décrire, raconter ET expliquer. Cette compétence entraîne le pourquoi — du choix, du fait, ou de la réaction.',
   'Dire pourquoi on a fait cela, pourquoi c''est arrivé, ou pourquoi on a réagi ainsi.',
   'B1', 4, true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EE3-C9 — Adapter son expression au destinataire et au contexte
  ('a2a9a2d0-a0c8-5b6f-a245-28932626c5ef', 'EE', 'EE3', 'EE3-C9', 'Adapter son expression au destinataire et au contexte',
   'On ne donne pas son avis de la même façon à un ami, à un voisin ou à un service. Cette compétence entraîne le choix du ton, du niveau de politesse et du vocabulaire — sans supposer que le contexte est forcément formel.',
   'Choisir le ton, le niveau de politesse et le vocabulaire qui conviennent à la personne et à la situation, familière ou non.',
   'B2', 6, true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO2-C9 — Réagir à une réponse ou une contrainte imprévue
  ('18baf106-ae22-5ad6-9816-3ba8a622e91d', 'EO', 'EO2', 'EO2-C9', 'Réagir à une réponse ou une contrainte imprévue',
   'Dans une vraie interaction, l''interlocuteur dit souvent non, ou répond à côté. Cette compétence entraîne la suite de l''échange : insister poliment, proposer une autre solution, s''adapter sans se bloquer.',
   'Poursuivre l''échange quand la réponse n''est pas celle attendue : insister poliment, proposer une autre solution, s''adapter.',
   'B1', 4, true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02'),
  -- EO3-C9 — Reformuler pour relancer son propos
  ('56c3c2c9-f531-5ec5-9a96-c117422e5f2b', 'EO', 'EO3', 'EO3-C9', 'Reformuler pour relancer son propos',
   'À l''oral, on se reprend. Cette compétence entraîne la reformulation utile : redire autrement pour préciser ou repartir, au lieu de tourner en rond sur la même idée. Elle est lisible dans une transcription, contrairement au débit ou aux pauses.',
   'Reprendre autrement ce que l''on vient de dire pour préciser ou repartir, au lieu de tourner en rond.',
   'B2', 7, true, '2026-09-13 09:00:00+02', '2026-09-13 09:00:00+02');

-- --------------------------------------------------------------------------
-- 4. Filet : exactement 8 competences ACTIVES par tache, rangs 1 a 8.
--
-- La regle produit est verrouillee par SkillSeedIT ; ce bloc la verifie
-- aussi a l'application, pour qu'une migration incomplete ne passe pas.
-- --------------------------------------------------------------------------
DO $$
DECLARE
  mauvaise text;
BEGIN
  SELECT string_agg(task_code || ' (' || n || ')', ', ')
    INTO mauvaise
    FROM (SELECT task_code, count(*) AS n FROM skills
           WHERE is_active GROUP BY task_code) t
   WHERE n <> 8;
  IF mauvaise IS NOT NULL THEN
    RAISE EXCEPTION 'Taxonomie V3 : taches sans 8 competences actives : %', mauvaise;
  END IF;

  SELECT string_agg(code || ' (rang ' || display_order || ')', ', ')
    INTO mauvaise
    FROM skills
   WHERE is_active AND display_order NOT BETWEEN 1 AND 8;
  IF mauvaise IS NOT NULL THEN
    RAISE EXCEPTION 'Taxonomie V3 : competences actives hors des rangs 1-8 : %', mauvaise;
  END IF;
END $$;
