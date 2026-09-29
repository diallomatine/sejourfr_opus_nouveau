-- ============================================================================
-- V678 — TCF SL B2 — lot 18 (point : nominalisation)
-- ----------------------------------------------------------------------------
-- Questions + choix. theme_id 22222222-0000-0000-0000-000000000003, difficulty='B2'.
-- 7 items, tous sur la nominalisation (choisir le nom d''action dérivé correct :
-- arrestation/arrêt, isolation/isolement, blanchissage/blanchiment, vieillissement/
-- vieillesse, règlement/réglage, essayage/essai, signalement/signalisation).
-- Contenu original, déterministe.
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('33333333-c012-1000-0000-000000000001', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « L''___ du cambrioleur recherché depuis trois mois a eu lieu hier à l''aube, près de la gare de Nantes. »',
   'La **nominalisation de « arrêter » appliquée à une personne** est « arrestation » : action d''appréhender quelqu''un (par la police). « Arrêt » désigne l''action de s''arrêter, un lieu (arrêt de bus) ou une décision d''une cour de justice — jamais l''interpellation d''un individu. « Arrêté » est un texte administratif (un arrêté municipal). « Cessation » nominalise « cesser » et s''applique à une activité (cessation d''activité), pas à une personne appréhendée.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_nominalisation'),

  ('33333333-c012-1000-0000-000000000002', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Grâce aux travaux d''___ réalisés cet hiver, la facture de chauffage de Rachid a baissé d''un tiers. »',
   'Le verbe « isoler » a **deux nominalisations de sens distinct** : « isolation » = procédé technique qui protège un bâtiment du froid ou du bruit — c''est le seul sens compatible avec des travaux et une facture de chauffage. « Isolement » désigne l''état d''une personne seule, coupée des autres (l''isolement des personnes âgées). « Insolation » est un paronyme : malaise causé par une exposition au soleil. « Isoloir » désigne la cabine où l''électeur vote à l''abri des regards.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_nominalisation'),

  ('33333333-c012-1000-0000-000000000003', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le pressing où Olena dépose son linge facture le ___ des nappes en lin à douze euros pièce. »',
   'Le verbe « blanchir » produit **trois nominalisations spécialisées** : « blanchissage » = nettoyage du linge (le métier du pressing, seule réponse possible ici). « Blanchiment » s''emploie pour l''argent d''origine illégale (blanchiment de capitaux) ou pour un mur, des dents. « Blanchissement » désigne le processus naturel de devenir blanc (le blanchissement des cheveux). « Blancheur » n''est pas un nom d''action mais un nom de qualité : l''état de ce qui est blanc.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_nominalisation'),

  ('33333333-c012-1000-0000-000000000004', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « Le ___ de la population oblige la commune de Guéret à ouvrir une seconde maison de santé. »',
   'La nuance est **processus vs état** : « vieillissement » (suffixe -ment sur « vieillir ») nomme le **processus** en cours — c''est lui qui transforme la démographie d''une commune. « Vieillesse » désigne l''état, la période de la vie (une vieillesse paisible), pas une évolution collective. « Ancienneté » mesure la durée passée dans une fonction ou une entreprise. « Vétusté » qualifie l''état dégradé d''un bâtiment ou d''un équipement, jamais d''une population.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_nominalisation'),

  ('33333333-c012-1000-0000-000000000005', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « L''électricienne demande à Diego le ___ de sa facture sous trente jours, par virement de préférence. »',
   'Le verbe « régler » possède **plusieurs nominalisations spécialisées** : « règlement » = paiement d''une somme due (régler une facture → le règlement de la facture). « Réglage » = ajustement technique d''un appareil ou d''une machine (le réglage du thermostat). « Régulation » = contrôle continu d''un flux ou d''un système (la régulation du trafic). « Régularisation » = mise en conformité d''une situation administrative (la régularisation d''un dossier).',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_nominalisation'),

  ('33333333-c012-1000-0000-000000000006', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La boutique bordelaise où Fatou a choisi sa robe de mariée réserve une cabine pour l''___, sur rendez-vous uniquement. »',
   'La **nominalisation de « essayer » appliquée à un vêtement** est « essayage » : action de passer un habit pour vérifier qu''il convient — d''où la cabine d''essayage. « Essai » désigne le test d''un produit ou d''un véhicule (un essai gratuit, un essai routier) ou une tentative. « Épreuve » nomme un test imposé, un examen ou une difficulté à surmonter. « Expérimentation » renvoie à une démarche scientifique ou à la mise à l''essai d''un dispositif public, pas à un vêtement.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_nominalisation'),

  ('33333333-c012-1000-0000-000000000007', 'TCF', '22222222-0000-0000-0000-000000000003', NULL, NULL, 'B2', 'STRUCTURE',
   'Complétez : « La plateforme où Wei modère un forum a simplifié le ___ des messages haineux : deux clics suffisent désormais. »',
   'La **nominalisation de « signaler » un fait ou un contenu** est « signalement » : action de porter un contenu problématique à la connaissance des modérateurs ou des autorités. « Signalisation » désigne l''ensemble des panneaux et marquages qui guident la circulation (la signalisation routière). « Signalétique » nomme le système de panneaux d''orientation d''un lieu (la signalétique d''un hôpital). « Signature » nominalise « signer » : action d''apposer son nom sur un document.',
   'true', '2026-06-07 12:00:00+02', '2026-06-07 12:00:00+02', 'ACTIVE', NULL, NULL, 'struct_nominalisation');

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('33333333-c012-2100-0000-000000000001', '33333333-c012-1000-0000-000000000001', 'arrêt', 'false', '1'),
  ('33333333-c012-2200-0000-000000000001', '33333333-c012-1000-0000-000000000001', 'arrestation', 'true', '2'),
  ('33333333-c012-2300-0000-000000000001', '33333333-c012-1000-0000-000000000001', 'arrêté', 'false', '3'),
  ('33333333-c012-2400-0000-000000000001', '33333333-c012-1000-0000-000000000001', 'cessation', 'false', '4'),

  ('33333333-c012-2100-0000-000000000002', '33333333-c012-1000-0000-000000000002', 'isolement', 'false', '1'),
  ('33333333-c012-2200-0000-000000000002', '33333333-c012-1000-0000-000000000002', 'insolation', 'false', '2'),
  ('33333333-c012-2300-0000-000000000002', '33333333-c012-1000-0000-000000000002', 'isolation', 'true', '3'),
  ('33333333-c012-2400-0000-000000000002', '33333333-c012-1000-0000-000000000002', 'isoloir', 'false', '4'),

  ('33333333-c012-2100-0000-000000000003', '33333333-c012-1000-0000-000000000003', 'blanchissage', 'true', '1'),
  ('33333333-c012-2200-0000-000000000003', '33333333-c012-1000-0000-000000000003', 'blanchiment', 'false', '2'),
  ('33333333-c012-2300-0000-000000000003', '33333333-c012-1000-0000-000000000003', 'blanchissement', 'false', '3'),
  ('33333333-c012-2400-0000-000000000003', '33333333-c012-1000-0000-000000000003', 'blancheur', 'false', '4'),

  ('33333333-c012-2100-0000-000000000004', '33333333-c012-1000-0000-000000000004', 'vieillesse', 'false', '1'),
  ('33333333-c012-2200-0000-000000000004', '33333333-c012-1000-0000-000000000004', 'ancienneté', 'false', '2'),
  ('33333333-c012-2300-0000-000000000004', '33333333-c012-1000-0000-000000000004', 'vétusté', 'false', '3'),
  ('33333333-c012-2400-0000-000000000004', '33333333-c012-1000-0000-000000000004', 'vieillissement', 'true', '4'),

  ('33333333-c012-2100-0000-000000000005', '33333333-c012-1000-0000-000000000005', 'réglage', 'false', '1'),
  ('33333333-c012-2200-0000-000000000005', '33333333-c012-1000-0000-000000000005', 'règlement', 'true', '2'),
  ('33333333-c012-2300-0000-000000000005', '33333333-c012-1000-0000-000000000005', 'régulation', 'false', '3'),
  ('33333333-c012-2400-0000-000000000005', '33333333-c012-1000-0000-000000000005', 'régularisation', 'false', '4'),

  ('33333333-c012-2100-0000-000000000006', '33333333-c012-1000-0000-000000000006', 'essai', 'false', '1'),
  ('33333333-c012-2200-0000-000000000006', '33333333-c012-1000-0000-000000000006', 'épreuve', 'false', '2'),
  ('33333333-c012-2300-0000-000000000006', '33333333-c012-1000-0000-000000000006', 'essayage', 'true', '3'),
  ('33333333-c012-2400-0000-000000000006', '33333333-c012-1000-0000-000000000006', 'expérimentation', 'false', '4'),

  ('33333333-c012-2100-0000-000000000007', '33333333-c012-1000-0000-000000000007', 'signalement', 'true', '1'),
  ('33333333-c012-2200-0000-000000000007', '33333333-c012-1000-0000-000000000007', 'signalisation', 'false', '2'),
  ('33333333-c012-2300-0000-000000000007', '33333333-c012-1000-0000-000000000007', 'signalétique', 'false', '3'),
  ('33333333-c012-2400-0000-000000000007', '33333333-c012-1000-0000-000000000007', 'signature', 'false', '4');

-- ============================================================================
-- CHECKLIST (contrôles passés)
-- ----------------------------------------------------------------------------
-- [x] 7 items, UUID déterministes (33333333-c012-1000-…-01..07 / choices 2100-2400).
-- [x] 4 propositions / 1 seule correcte par item ; options de même catégorie
--     (4 noms existants de la même famille ou du même champ dérivationnel).
-- [x] Distribution des bonnes réponses : pos1:2, pos2:2, pos3:2, pos4:1
--     (4 positions utilisées, aucune ne dépasse 2).
-- [x] Point unique : nominalisation (arrestation/arrêt/arrêté, isolation/isolement,
--     blanchissage/blanchiment/blanchissement, vieillissement/vieillesse,
--     règlement/réglage/régulation, essayage/essai, signalement/signalisation) —
--     aucun point de la liste interdite.
-- [x] explanation ≥ 80 caractères, point clé en **gras** (nominalisation, suffixe,
--     processus vs état) et démonte chacun des 3 distracteurs.
-- [x] Contextes tous différents (fait divers policier, travaux d''isolation,
--     pressing, démographie communale, facture d''artisane, boutique de mariée,
--     modération en ligne) ; prénoms variés (Rachid, Olena, Diego, Fatou, Wei) ;
--     villes variées (Nantes, Guéret, Bordeaux).
-- [x] Contenu 100 % original ; pas de SVG ni SSML dans ce lot (items texte purs).
-- [x] Apostrophes SQL doublées ; pas de JSONB dans ce schéma (table choices).
-- ============================================================================
