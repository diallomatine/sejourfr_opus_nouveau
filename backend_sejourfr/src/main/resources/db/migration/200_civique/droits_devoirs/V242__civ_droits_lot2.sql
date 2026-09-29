-- ============================================================================
-- V242 — Civique : Droits et devoirs (lot 2)
-- ----------------------------------------------------------------------------
-- Questions + choix. Filtre: 11111111-0000-0000-0000-000000000003 .
-- Données régénérées depuis l'état final (déterministe, rejouable dev+recette).
-- ============================================================================

-- questions
INSERT INTO questions
  (id, module, theme_id, passage_id, media_id, difficulty, question_type, statement, explanation,
   is_active, created_at, updated_at, status, tcf_sub_theme, audio_mode, competence_code)
VALUES
  ('f3000001-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quels droits la citoyenneté française permet-elle d''exercer ?',
   'La citoyenneté française donne droit de vote et d''éligibilité à toutes les élections, droit à la protection de l''État (à l''étranger), droit d''occuper des fonctions publiques.',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Que risque une personne qui ne respecte pas la loi en France ?',
   'Une personne qui enfreint la loi s''expose à des sanctions (amendes, prison, travaux d''intérêt général), prononcées par les tribunaux selon la gravité de l''infraction.',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quel est le rôle de la gendarmerie en France ?',
   'La gendarmerie assure la sécurité publique et la lutte contre la délinquance, principalement en zones rurales et périurbaines. C''est une force militaire placée sous l''autorité du ministère de l''Intérieur.',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel est le rôle de la police nationale en France ?',
   'La police nationale est chargée de la sécurité publique principalement en zones urbaines : prévenir et constater les infractions, protéger les personnes et les biens, maintenir l''ordre.',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Que désigne-t-on par ''infraction'' en droit français ?',
   'Une infraction est un comportement interdit et puni par la loi. Elle comprend les contraventions (peu graves), les délits (moyennes) et les crimes (graves).',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'MISE_SITUATION',
   'Comment peut-on réduire concrètement sa production de déchets ?',
   'On peut réduire ses déchets : trier les recyclables, composter les biodéchets, éviter les emballages superflus, réparer plutôt que jeter, acheter d''occasion ou en vrac.',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Est-il autorisé de laisser un gros encombrant (électroménager, meuble) sur le trottoir ?',
   'Non. Déposer un encombrant sur la voie publique sans autorisation est une infraction. Les communes organisent des collectes spécifiques ou disposent de déchetteries.',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'NAT', 'CONNAISSANCE',
   'Que désigne la traite des êtres humains ?',
   'La traite des êtres humains est le recrutement, le transport ou l''hébergement de personnes à des fins d''exploitation (sexuelle, travail forcé, mendicité, prélèvement d''organes). C''est un crime grave puni sévèrement par la loi.',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'MISE_SITUATION',
   'Que doit faire une personne victime de violences (conjugales, sexuelles, agression) ?',
   'Une victime de violences doit porter plainte au commissariat ou en gendarmerie. Elle peut être accompagnée par des associations spécialisées, des avocats, et a droit à une protection (éloignement de l''agresseur).',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000001-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CR', 'CONNAISSANCE',
   'Quelle est la catégorie d''infractions la plus grave en droit pénal français ?',
   'Le crime est l''infraction la plus grave (meurtre, viol, etc.). Il est jugé par la cour d''assises et puni par des peines pouvant aller jusqu''à la réclusion criminelle à perpétuité.',
   'true', '2026-05-27 17:40:29.926748+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000001', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'En France, peut-on être arrêté sans motif précis ?',
   'Non. Toute privation de liberté doit avoir un fondement légal. La police judiciaire ne peut placer en garde à vue qu''une personne soupçonnée d''avoir commis ou tenté une infraction.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000002', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Toute personne accusée d''une infraction peut-elle se taire devant la police ?',
   'Oui. Le droit au silence est un droit fondamental. Une personne en garde à vue a le droit de ne faire aucune déclaration et d''attendre la présence d''un avocat.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000003', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel numéro d''urgence permet d''appeler les pompiers en France ?',
   'Le 18 est le numéro des pompiers en France. Il est gratuit et accessible 24h/24.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000004', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel numéro d''urgence permet d''appeler le SAMU (urgences médicales) ?',
   'Le 15 est le numéro du SAMU (service d''aide médicale urgente). Il est gratuit, accessible 24h/24, et joint un médecin régulateur.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000005', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel numéro européen permet de joindre toutes les urgences en Europe ?',
   'Le 112 est le numéro d''urgence européen unique, accessible gratuitement dans tous les pays de l''UE. Il peut être utilisé pour la police, les pompiers ou le SAMU.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000006', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel est l''âge minimum pour conduire une voiture en France ?',
   'L''âge minimum pour conduire une voiture (permis B) est de 18 ans. Une conduite accompagnée est possible dès 15 ans, mais l''examen n''est passé qu''à partir de 17 ans dans certains cas.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000007', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Le port de la ceinture de sécurité est-il obligatoire en voiture ?',
   'Oui. Le port de la ceinture est obligatoire pour tous les occupants du véhicule (avant et arrière). Ne pas la porter est une infraction passible d''amende.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000008', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Conduire en état d''ivresse est-il un délit en France ?',
   'Oui. Conduire avec un taux d''alcool supérieur à 0,5 g par litre de sang (0,2 g pour les jeunes conducteurs) est une infraction. Au-delà de 0,8 g, c''est un délit puni de prison.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000009', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'L''enregistrement audio sans accord d''une personne est-il légal ?',
   'Non, en général. Enregistrer une conversation privée sans le consentement des participants est interdit et puni pénalement (article 226-1 du Code pénal).',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000000a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Filmer ou photographier une personne sans son accord est-il autorisé ?',
   'Non, en général. Toute personne a droit à son image. Diffuser ou utiliser l''image de quelqu''un sans son accord est une atteinte à la vie privée, punie par la loi.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000000b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Voler quelque chose dans un magasin est-il une infraction ?',
   'Oui. Le vol est un délit (article 311-1 du Code pénal), puni de jusqu''à 3 ans de prison et 45 000 EUR d''amende, plus selon les circonstances (vol avec violence, en bande, etc.).',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000000c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Frapper quelqu''un dans la rue est-il une infraction en France ?',
   'Oui. Les violences volontaires sont des délits punis par la loi (de l''amende à plusieurs années de prison selon les blessures). Ne pas avoir blessé n''exonère pas de sanction.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000000d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'A-t-on le droit de fumer dans les lieux publics fermés en France ?',
   'Non. Depuis 2008, il est interdit de fumer dans tous les lieux publics fermés (restaurants, bars, transports, bureaux). Des espaces extérieurs peuvent être aménagés.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000000e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'La consommation de drogues comme le cannabis est-elle légale en France ?',
   'Non. La consommation, la détention et le trafic de stupéfiants (cannabis inclus) sont interdits et punis par la loi.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000000f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'L''achat et la consommation d''alcool sont-ils interdits aux mineurs ?',
   'Oui. La vente d''alcool aux mineurs (moins de 18 ans) est interdite et punie par la loi. Les commerçants peuvent demander une pièce d''identité.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000010', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Que faut-il faire en cas de cambriolage ?',
   'Il faut prévenir immédiatement la police (17) ou la gendarmerie, et déposer plainte au commissariat. Ne rien toucher avant l''arrivée des enquêteurs.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000011', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel âge donne accès à la majorité civile en France ?',
   'La majorité civile est fixée à 18 ans. À partir de cet âge, on est juridiquement responsable de ses actes et on peut signer un contrat, voter, se marier.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000012', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Un parent peut-il frapper son enfant en France ?',
   'Non. La loi de 2019 a inscrit dans le Code civil l''interdiction des violences éducatives ordinaires (châtiments corporels et humiliations).',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000013', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Doit-on payer ses impôts en France ?',
   'Oui. Payer ses impôts est une obligation civique. C''est inscrit dans la Déclaration de 1789 (article 13) : la contribution commune est indispensable au fonctionnement de l''État.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000014', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'La protection des enfants est-elle un devoir en France ?',
   'Oui. Tous les adultes ont l''obligation de protéger les enfants et de signaler toute situation de maltraitance. Le numéro 119 est dédié à l''enfance en danger.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000015', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Que doit-on faire si on connait un enfant en danger ?',
   'Il faut le signaler immédiatement. On peut appeler le 119 (enfance en danger), contacter une assistante sociale ou la police. Le silence peut être puni.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000016', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Une personne malade a-t-elle droit à la sécurité sociale ?',
   'Oui. Toute personne résidant régulièrement en France a droit à la protection maladie universelle (PUMA), qui rembourse une partie des frais de santé.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000017', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Les enfants ont-ils l''obligation d''aller à l''école ?',
   'Oui. L''instruction est obligatoire pour tous les enfants de 3 à 16 ans, qu''ils soient français ou étrangers, résidant en France.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000018', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'L''école publique est-elle payante en France ?',
   'Non. L''école publique est gratuite. La gratuité a été instaurée en 1881 par les lois Jules Ferry.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000019', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Un employeur peut-il payer son salarié en dessous du SMIC ?',
   'Non. Le SMIC (Salaire minimum interprofessionnel de croissance) est un minimum légal. Tout employeur doit verser au moins le SMIC pour un travail à temps plein.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000001a', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Le travail au noir (non déclaré) est-il légal en France ?',
   'Non. Le travail dissimulé (sans déclaration ni cotisations) est interdit et puni par la loi, autant pour l''employeur que pour le salarié. Cela prive aussi de droits sociaux.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000001b', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Combien d''heures peut-on travailler maximum par semaine en France ?',
   'La durée légale du travail est de 35 heures par semaine. Au-delà, ce sont des heures supplémentaires (majorées). Le plafond absolu est de 48 heures hebdomadaires.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000001c', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Combien de semaines de congés payés annuels minimum a un salarié à temps plein ?',
   'Tout salarié a droit à 5 semaines (25 jours ouvrés) de congés payés par an, en France, pour une année complète de travail.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000001d', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quels sont les numéros d''urgence essentiels en France ?',
   'Les principaux numéros d''urgence sont : 17 (police), 18 (pompiers), 15 (SAMU), 112 (urgence européenne), 119 (enfance en danger), 3919 (violences conjugales).',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000001e', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Faire confiance et respecter la décision d''un tribunal est-il important ?',
   'Oui. Respecter les décisions de justice est un devoir civique. La force publique fait exécuter les jugements, et ne pas s''y soumettre constitue souvent une nouvelle infraction.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-00000000001f', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Doit-on dire la vérité quand on est témoin devant la justice ?',
   'Oui. Le faux témoignage devant une juridiction est un délit puni par la loi. Tout témoin doit dire la vérité sous serment.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000020', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Comment appelle-t-on l''obligation de ne pas révéler ce qu''on apprend dans son métier (médecin, avocat, prêtre) ?',
   'Le secret professionnel impose à certaines professions de ne pas révéler les informations confidentielles obtenues dans l''exercice de leur métier. Le violer est un délit.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000021', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Un policier peut-il fouiller mon sac sans aucune raison ?',
   'Non. Pour fouiller un sac, le policier doit avoir un cadre légal (contrôle d''identité avec motifs, enquête, plan Vigipirate dans certaines zones).',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000022', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel droit fondamental garantit la liberté de se déplacer en France ?',
   'La liberté d''aller et venir est un droit fondamental. Elle permet à chacun de circuler librement sur le territoire, sauf restrictions légales (zone interdite, ordre judiciaire).',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000023', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Une victime peut-elle demander réparation à l''auteur d''une infraction ?',
   'Oui. La victime peut se constituer partie civile lors du procès pénal pour obtenir des dommages et intérêts, ou engager une procédure civile parallèle.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000024', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'L''esclavage est-il interdit en France ?',
   'Oui. L''esclavage a été définitivement aboli en 1848. Tout traitement assimilé (servitude, travail forcé) est aujourd''hui un crime puni pénalement.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000025', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Un agent public peut-il accepter de l''argent pour rendre un service ?',
   'Non. Accepter de l''argent ou un avantage pour rendre un service public est de la corruption, un délit grave puni par la loi.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000026', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Doit-on respecter les consignes de tri des déchets ?',
   'Oui. Le tri sélectif est obligatoire dans la plupart des communes. Ne pas respecter le tri ou déposer des déchets hors des bacs prévus est une infraction passible d''amende.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000027', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Quel est le numéro national d''aide aux femmes victimes de violences ?',
   'Le 3919 est le numéro national d''écoute pour les femmes victimes de violences (conjugales, sexuelles, harcèlement). C''est gratuit et confidentiel.',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL),

  ('f3000002-0000-0000-0000-000000000028', 'CIVIQUE', '11111111-0000-0000-0000-000000000003', NULL, NULL, 'CSP', 'CONNAISSANCE',
   'Le racisme est-il puni par la loi française ?',
   'Oui. Les actes et propos racistes (injures, discriminations, provocation à la haine) sont des délits punis par la loi (loi du 29 juillet 1881 sur la liberté de la presse).',
   'true', '2026-05-27 17:40:29.939109+02', NULL, 'ACTIVE', NULL, NULL, NULL);

-- choices
INSERT INTO choices
  (id, question_id, label, is_correct, display_order)
VALUES
  ('b3b34b49-c6e0-46a0-a33e-b7ffa98d4195', 'f3000001-0000-0000-0000-000000000015',
   'Voter, être éligible, bénéficier de la protection de l''État',
   'true', '0'),

  ('073a1bcb-e009-42b9-88c5-05dd9f7f5401', 'f3000001-0000-0000-0000-000000000015',
   'Aucun droit particulier',
   'false', '1'),

  ('69a36938-0c59-494d-98a3-933cefd86b18', 'f3000001-0000-0000-0000-000000000015',
   'Uniquement le droit de porter le drapeau',
   'false', '2'),

  ('df3a65b3-7d89-4778-a555-9fcdbb9ce775', 'f3000001-0000-0000-0000-000000000015',
   'Le droit à un revenu universel',
   'false', '3'),

  ('f65b3930-b288-4d4f-bf2d-f9e896391fb3', 'f3000001-0000-0000-0000-000000000016',
   'Des sanctions pénales (amendes, prison, TIG)',
   'true', '0'),

  ('9017dca8-a88e-49e1-b3c1-c4cc0dee64d5', 'f3000001-0000-0000-0000-000000000016',
   'Rien du tout',
   'false', '1'),

  ('1add2e67-9ed1-4acf-83f3-6107170564f5', 'f3000001-0000-0000-0000-000000000016',
   'Uniquement un avertissement verbal',
   'false', '2'),

  ('91d2a1f9-d05f-4beb-b3ff-cfcacf95bece', 'f3000001-0000-0000-0000-000000000016',
   'Une récompense',
   'false', '3'),

  ('0b45c1ab-8d27-4ec9-974c-ca114779713b', 'f3000001-0000-0000-0000-000000000017',
   'Sécurité publique en zones rurales et périurbaines',
   'true', '0'),

  ('4aa79817-2503-421f-96c4-e109aeca3bdc', 'f3000001-0000-0000-0000-000000000017',
   'Gérer les écoles',
   'false', '1'),

  ('f486ae12-5e66-4a14-8963-b2c0490668e6', 'f3000001-0000-0000-0000-000000000017',
   'Voter les lois',
   'false', '2'),

  ('9c9f00b7-2b1c-4f8f-ab2e-aec04066859c', 'f3000001-0000-0000-0000-000000000017',
   'Distribuer le courrier',
   'false', '3'),

  ('8978dd54-7a93-49a7-8268-73197e5d6a83', 'f3000001-0000-0000-0000-000000000018',
   'Sécurité publique principalement en zones urbaines',
   'true', '0'),

  ('66a3e875-ccaf-440b-9328-76491304cb6a', 'f3000001-0000-0000-0000-000000000018',
   'Voter les lois',
   'false', '1'),

  ('ce79f17e-49b4-453c-aef4-844ce52e72ec', 'f3000001-0000-0000-0000-000000000018',
   'Diriger les écoles',
   'false', '2'),

  ('6cdf78c7-3193-4cd2-915f-1291b0be1d8e', 'f3000001-0000-0000-0000-000000000018',
   'Réparer les routes',
   'false', '3'),

  ('f0fd4735-6512-402c-872c-c9c10177d6e4', 'f3000001-0000-0000-0000-000000000019',
   'Un acte interdit puni par la loi (contravention, délit, crime)',
   'true', '0'),

  ('42b1f195-8cef-498d-b19d-ddd4a7662e4e', 'f3000001-0000-0000-0000-000000000019',
   'Un avis personnel',
   'false', '1'),

  ('20cdcdc2-ee99-42a6-81c3-9ba6bdf81d80', 'f3000001-0000-0000-0000-000000000019',
   'Une croyance religieuse',
   'false', '2'),

  ('455b04fc-9fd8-4795-abe0-dd238f2923c3', 'f3000001-0000-0000-0000-000000000019',
   'Un acte de courage',
   'false', '3'),

  ('823c7291-a179-436a-8441-142cce7d788a', 'f3000001-0000-0000-0000-00000000001a',
   'Trier, composter, éviter les emballages, réparer',
   'true', '0'),

  ('d533c704-3cba-4dcb-bf57-565fc6bf44e5', 'f3000001-0000-0000-0000-00000000001a',
   'Tout jeter dans le même sac',
   'false', '1'),

  ('67b00dff-df00-4834-8235-07c97c0d9401', 'f3000001-0000-0000-0000-00000000001a',
   'Brûler les déchets à la maison',
   'false', '2'),

  ('235f1e5f-d90a-4cb9-b554-d1965edac457', 'f3000001-0000-0000-0000-00000000001a',
   'Les jeter dans la rue',
   'false', '3'),

  ('a9babe72-84ed-451e-abda-44bcce1ee19b', 'f3000001-0000-0000-0000-00000000001b',
   'Non, c''est une infraction ; il faut utiliser la déchetterie ou la collecte d''encombrants',
   'true', '0'),

  ('b82c7d23-dc9c-4b66-b7c3-dd5febe15c8f', 'f3000001-0000-0000-0000-00000000001b',
   'Oui, c''est libre',
   'false', '1'),

  ('b62964ff-a283-4aa7-9ac8-8da3a5de9a2c', 'f3000001-0000-0000-0000-00000000001b',
   'Uniquement la nuit',
   'false', '2'),

  ('0c6229bd-3e8e-47a4-bc46-ffd31c95df66', 'f3000001-0000-0000-0000-00000000001b',
   'Uniquement le 14 juillet',
   'false', '3'),

  ('f73859d0-b2e7-46a4-a757-6d301c48b6a7', 'f3000001-0000-0000-0000-00000000001c',
   'L''exploitation de personnes (travail forcé, prostitution forcée, etc.)',
   'true', '0'),

  ('c8f20f9d-43c9-4c87-a499-7578596378ed', 'f3000001-0000-0000-0000-00000000001c',
   'Le commerce d''animaux',
   'false', '1'),

  ('4abd8d78-fe8d-426c-b470-bf25be6e2a83', 'f3000001-0000-0000-0000-00000000001c',
   'Un trafic de drogue',
   'false', '2'),

  ('89cec547-918c-487f-b364-1d9d9e552dc5', 'f3000001-0000-0000-0000-00000000001c',
   'Un commerce équitable',
   'false', '3'),

  ('bbe50665-995b-4686-a716-ebd7e9dad197', 'f3000001-0000-0000-0000-00000000001d',
   'Porter plainte et se faire accompagner par des associations spécialisées',
   'true', '0'),

  ('f48d42f8-2829-40e2-818c-3f7d2f5e5087', 'f3000001-0000-0000-0000-00000000001d',
   'Rester silencieuse',
   'false', '1'),

  ('57a3ee40-c985-4c73-95c5-8cd61b113af9', 'f3000001-0000-0000-0000-00000000001d',
   'Se venger elle-même',
   'false', '2'),

  ('4cb0241c-4711-4b83-be91-b233975ef618', 'f3000001-0000-0000-0000-00000000001d',
   'Quitter le pays',
   'false', '3'),

  ('64baaca6-56a8-4230-a987-82f9948418f5', 'f3000001-0000-0000-0000-00000000001e',
   'Le crime (meurtre, viol)',
   'true', '0'),

  ('7f8eef44-84cc-4fb9-845e-5209be10ed6b', 'f3000001-0000-0000-0000-00000000001e',
   'La contravention de stationnement',
   'false', '1'),

  ('d2e2d5c9-92ec-41ce-928b-16e026c110b1', 'f3000001-0000-0000-0000-00000000001e',
   'Le retard de paiement',
   'false', '2'),

  ('9f68add5-0c33-4be2-9303-bd860691d83a', 'f3000001-0000-0000-0000-00000000001e',
   'L''oubli d''une obligation',
   'false', '3'),

  ('525e2694-af01-46f7-8d7c-e4ce35cbf7a0', 'f3000002-0000-0000-0000-000000000001',
   'Non, il faut un motif légal',
   'true', '0'),

  ('9cc6b9b3-569f-458d-bb56-915cc34e8b70', 'f3000002-0000-0000-0000-000000000001',
   'Oui, sans aucune raison',
   'false', '1'),

  ('0d189660-a941-417c-b7af-69de6538ebcd', 'f3000002-0000-0000-0000-000000000001',
   'Oui, sur ordre du maire',
   'false', '2'),

  ('30b1fd11-d0bc-4c1e-bbce-4b5ddc7acf54', 'f3000002-0000-0000-0000-000000000001',
   'Oui, le week-end uniquement',
   'false', '3'),

  ('9c98e6a5-be96-4026-9e72-ec86abd7d3f8', 'f3000002-0000-0000-0000-000000000002',
   'Oui, le droit au silence est garanti',
   'true', '0'),

  ('f3ed57f8-02a4-427e-aba8-bae7baf91c4b', 'f3000002-0000-0000-0000-000000000002',
   'Non, elle doit tout dire',
   'false', '1'),

  ('c393250a-7f47-462e-b0d5-0ba3ec96b198', 'f3000002-0000-0000-0000-000000000002',
   'Uniquement les enfants y ont droit',
   'false', '2'),

  ('55a2ea48-35bc-4178-a089-3900beb77c14', 'f3000002-0000-0000-0000-000000000002',
   'Uniquement avec accord du maire',
   'false', '3'),

  ('c2ae41dd-64e2-49ea-85e5-b3b383ce4394', 'f3000002-0000-0000-0000-000000000003',
   'Le 18',
   'true', '0'),

  ('e1f6ed2d-c080-43de-bdcf-3b9277d7323a', 'f3000002-0000-0000-0000-000000000003',
   'Le 17',
   'false', '1'),

  ('04725ed1-a18f-4155-ae81-2f1f05a37b73', 'f3000002-0000-0000-0000-000000000003',
   'Le 15',
   'false', '2'),

  ('50c5ed0c-bbc9-4947-88fc-fcc62fb633b0', 'f3000002-0000-0000-0000-000000000003',
   'Le 12',
   'false', '3'),

  ('6bf62ed8-7093-4846-8b77-0cab904dc1aa', 'f3000002-0000-0000-0000-000000000004',
   'Le 15',
   'true', '0'),

  ('bbdd45f3-1b05-4085-a8c8-a9b3f24260dc', 'f3000002-0000-0000-0000-000000000004',
   'Le 17',
   'false', '1'),

  ('f7b1f96a-a149-4870-8d35-5210bf19829b', 'f3000002-0000-0000-0000-000000000004',
   'Le 18',
   'false', '2'),

  ('99b7399a-9f8f-4ac9-a44c-afdd8c0139f0', 'f3000002-0000-0000-0000-000000000004',
   'Le 36 36',
   'false', '3'),

  ('07badbb4-030e-4ca9-b815-8f4d9fcdac1f', 'f3000002-0000-0000-0000-000000000005',
   'Le 112',
   'true', '0'),

  ('b14b595b-dd29-4879-9e1d-4067914d9857', 'f3000002-0000-0000-0000-000000000005',
   'Le 18',
   'false', '1'),

  ('4966dca6-b50b-4cbe-9006-30b705f97f6d', 'f3000002-0000-0000-0000-000000000005',
   'Le 36 36',
   'false', '2'),

  ('4258c7d5-fd18-4f9a-bf07-99b4eca58524', 'f3000002-0000-0000-0000-000000000005',
   'Le 911',
   'false', '3'),

  ('93fd6657-5813-4af9-912a-755a9a10f9f8', 'f3000002-0000-0000-0000-000000000006',
   '18 ans (avec quelques exceptions)',
   'true', '0'),

  ('f8f95b43-8255-433c-bddf-40ec0704c829', 'f3000002-0000-0000-0000-000000000006',
   '16 ans',
   'false', '1'),

  ('c1f417d1-5970-4d84-9076-34a10e7f2b39', 'f3000002-0000-0000-0000-000000000006',
   '21 ans',
   'false', '2'),

  ('5e7ea63b-a7da-42ba-97c4-3b1928ad892e', 'f3000002-0000-0000-0000-000000000006',
   '25 ans',
   'false', '3'),

  ('1f91b2ce-48d2-4b37-b65f-262c6940d559', 'f3000002-0000-0000-0000-000000000007',
   'Oui, pour tous les passagers',
   'true', '0'),

  ('aeed8469-5aba-4f11-8c2e-e4e19c43ac09', 'f3000002-0000-0000-0000-000000000007',
   'Non, uniquement le conducteur',
   'false', '1'),

  ('5cd4a982-70c3-4c6a-9ab3-d84a3a0d649b', 'f3000002-0000-0000-0000-000000000007',
   'Uniquement sur l''autoroute',
   'false', '2'),

  ('72f1eb4d-c0ca-43f2-80fc-854ab99b0413', 'f3000002-0000-0000-0000-000000000007',
   'Uniquement la nuit',
   'false', '3'),

  ('835a2d56-cb65-47fd-a28a-c9e45bafc92a', 'f3000002-0000-0000-0000-000000000008',
   'Oui, c''est une infraction sanctionnée',
   'true', '0'),

  ('7efdd463-40a9-4684-bee3-a6e11759427c', 'f3000002-0000-0000-0000-000000000008',
   'Non, c''est libre',
   'false', '1'),

  ('83cfa257-c994-433f-8cd4-741c7c8f8438', 'f3000002-0000-0000-0000-000000000008',
   'Uniquement la nuit',
   'false', '2'),

  ('0b92f1d0-070a-4ae0-89e8-133a5095862c', 'f3000002-0000-0000-0000-000000000008',
   'Uniquement les jours fériés',
   'false', '3'),

  ('83b96cb0-ee6e-49de-a6f7-a8a7979e0289', 'f3000002-0000-0000-0000-000000000009',
   'Non, c''est interdit sans consentement',
   'true', '0'),

  ('528473f8-77f8-4aa5-bd63-957d9a66e5bf', 'f3000002-0000-0000-0000-000000000009',
   'Oui, sans condition',
   'false', '1'),

  ('d2cb66c5-6c5d-49e0-b84d-42443186bf8c', 'f3000002-0000-0000-0000-000000000009',
   'Uniquement en présence d''un avocat',
   'false', '2'),

  ('aa063ceb-37dd-4f70-b08a-f25bab1289f8', 'f3000002-0000-0000-0000-000000000009',
   'Uniquement sur autoroute',
   'false', '3'),

  ('6e3b45ee-3ca7-473a-875b-30ce32158d4e', 'f3000002-0000-0000-0000-00000000000a',
   'Non, le droit à l''image protège chacun',
   'true', '0'),

  ('d073b889-33aa-4e3d-9236-0d4b200948ee', 'f3000002-0000-0000-0000-00000000000a',
   'Oui, sans condition',
   'false', '1'),

  ('18e0d879-3b47-436c-a6db-1852cf7fce29', 'f3000002-0000-0000-0000-00000000000a',
   'Oui, dans la rue uniquement',
   'false', '2'),

  ('400e7408-45d2-436d-aa7c-cf7da8a78c72', 'f3000002-0000-0000-0000-00000000000a',
   'Oui, si la personne est connue',
   'false', '3'),

  ('7826e627-2f4f-447c-a2d3-4d0e1b18df01', 'f3000002-0000-0000-0000-00000000000b',
   'Oui, c''est un délit puni pénalement',
   'true', '0'),

  ('0a3336c2-b522-4937-bbc5-c66c762d79f9', 'f3000002-0000-0000-0000-00000000000b',
   'Non, c''est gratuit en cas d''oubli',
   'false', '1'),

  ('b9f62deb-e69b-4307-97bf-fc544a0ae4d5', 'f3000002-0000-0000-0000-00000000000b',
   'Uniquement pour des sommes supérieures à 100 EUR',
   'false', '2'),

  ('e4db53ef-a2c5-490b-910a-6c9763602a39', 'f3000002-0000-0000-0000-00000000000b',
   'Uniquement la nuit',
   'false', '3'),

  ('ddb26ae8-0e91-4238-9fd4-2847d8467be9', 'f3000002-0000-0000-0000-00000000000c',
   'Oui, les violences volontaires sont sanctionnées',
   'true', '0'),

  ('ec053bc6-b0d5-4075-a7a2-9dd606ae89b9', 'f3000002-0000-0000-0000-00000000000c',
   'Non, c''est libre',
   'false', '1'),

  ('683f3855-88e3-458e-bd5c-c629df827326', 'f3000002-0000-0000-0000-00000000000c',
   'Uniquement en cas de blessures',
   'false', '2'),

  ('28bd8209-fac7-450a-b5fd-a0963cd15183', 'f3000002-0000-0000-0000-00000000000c',
   'Uniquement entre adultes',
   'false', '3'),

  ('0f84017f-fe22-43d5-86e1-e22d83587332', 'f3000002-0000-0000-0000-00000000000d',
   'Non, c''est interdit depuis 2008',
   'true', '0'),

  ('4f5caa6f-9a12-4d37-a6b3-e055bf904c24', 'f3000002-0000-0000-0000-00000000000d',
   'Oui, partout',
   'false', '1'),

  ('b28268d0-3600-4064-9e4e-62cfc44c87a3', 'f3000002-0000-0000-0000-00000000000d',
   'Uniquement le soir',
   'false', '2'),

  ('712a3d99-024d-4b6f-aeb4-abaad0c16a8d', 'f3000002-0000-0000-0000-00000000000d',
   'Uniquement les hommes',
   'false', '3'),

  ('ac914cd3-d1cb-4a73-a365-c392a5148e5c', 'f3000002-0000-0000-0000-00000000000e',
   'Non, c''est interdit et puni',
   'true', '0'),

  ('8a686034-e1c8-43e9-8d54-97e04ff513bf', 'f3000002-0000-0000-0000-00000000000e',
   'Oui, sans condition',
   'false', '1'),

  ('4add62d3-5f77-4302-882e-671ab26effde', 'f3000002-0000-0000-0000-00000000000e',
   'Uniquement le 14 juillet',
   'false', '2'),

  ('8aa0f728-f4bd-4a83-bfb9-0e2253d76e9c', 'f3000002-0000-0000-0000-00000000000e',
   'Uniquement avec autorisation préfectorale',
   'false', '3'),

  ('14673604-92fb-4650-9389-4f133ddd5e55', 'f3000002-0000-0000-0000-00000000000f',
   'Oui, interdit aux moins de 18 ans',
   'true', '0'),

  ('ae0a1e6d-6966-4116-8e79-86e524e49392', 'f3000002-0000-0000-0000-00000000000f',
   'Non, c''est libre',
   'false', '1'),

  ('7eabc7b9-df8a-449d-8b93-d38ab7401a74', 'f3000002-0000-0000-0000-00000000000f',
   'Uniquement le vin',
   'false', '2'),

  ('c284800d-bee8-4041-aceb-867f8ba4d4b3', 'f3000002-0000-0000-0000-00000000000f',
   'Uniquement les boissons fortes',
   'false', '3'),

  ('84550420-062a-4135-af67-6fca1a86f189', 'f3000002-0000-0000-0000-000000000010',
   'Appeler la police (17) et déposer plainte',
   'true', '0'),

  ('a466b322-7030-4f5e-aa01-e40bc4a14a48', 'f3000002-0000-0000-0000-000000000010',
   'Ranger soi-même la maison',
   'false', '1'),

  ('b51cc311-84e3-444b-a1b5-cf5bef823756', 'f3000002-0000-0000-0000-000000000010',
   'Rien dire à personne',
   'false', '2'),

  ('11f7d941-4d38-46da-9c5a-9c868a9fa753', 'f3000002-0000-0000-0000-000000000010',
   'Affronter le cambrioleur seul',
   'false', '3'),

  ('8cb97461-fa3c-4ee9-a00e-73820e191752', 'f3000002-0000-0000-0000-000000000011',
   '18 ans',
   'true', '0'),

  ('c7241922-e1d1-4106-8c37-8d814a8e8fd9', 'f3000002-0000-0000-0000-000000000011',
   '16 ans',
   'false', '1'),

  ('987577fb-c20d-4517-a45d-fa632dccbfea', 'f3000002-0000-0000-0000-000000000011',
   '21 ans',
   'false', '2'),

  ('cab67858-e677-4539-aa4e-31d3de4db038', 'f3000002-0000-0000-0000-000000000011',
   '25 ans',
   'false', '3'),

  ('a5a7ede3-8dcb-4d25-b9b1-5e309a97fee1', 'f3000002-0000-0000-0000-000000000012',
   'Non, les violences éducatives sont interdites',
   'true', '0'),

  ('df29492d-33e3-42a2-bb4a-14e98e9d7e9f', 'f3000002-0000-0000-0000-000000000012',
   'Oui, sans condition',
   'false', '1'),

  ('e0417985-4682-4774-ac15-e4ce0e7369ac', 'f3000002-0000-0000-0000-000000000012',
   'Uniquement la mère',
   'false', '2'),

  ('3c556677-2543-4f94-b5ab-a712980f755c', 'f3000002-0000-0000-0000-000000000012',
   'Uniquement les jours fériés',
   'false', '3'),

  ('45a069ab-89e4-48dc-94a0-1e0475c974da', 'f3000002-0000-0000-0000-000000000013',
   'Oui, c''est un devoir civique',
   'true', '0'),

  ('afd9b6b6-1985-477e-a117-b11b90b1cf56', 'f3000002-0000-0000-0000-000000000013',
   'Non, c''est facultatif',
   'false', '1'),

  ('a3c2558c-4cca-4000-930b-e87a33c1e6ab', 'f3000002-0000-0000-0000-000000000013',
   'Uniquement les riches',
   'false', '2'),

  ('36f252d5-08c4-40c2-aaab-9abcca619a7e', 'f3000002-0000-0000-0000-000000000013',
   'Uniquement les fonctionnaires',
   'false', '3'),

  ('ad9e0a2b-dcde-4ede-9d12-36efa1cd295c', 'f3000002-0000-0000-0000-000000000014',
   'Oui, et le 119 permet de signaler',
   'true', '0'),

  ('6fdcca0b-aebd-4570-a57c-d7447e5e8500', 'f3000002-0000-0000-0000-000000000014',
   'Non, c''est aux parents seulement',
   'false', '1'),

  ('e4fa436b-4dc4-4e20-9184-e0d2b5dc7ef5', 'f3000002-0000-0000-0000-000000000014',
   'Uniquement les enseignants',
   'false', '2'),

  ('7afd0a40-038f-4122-8565-39a626ec0c6c', 'f3000002-0000-0000-0000-000000000014',
   'Uniquement les voisins',
   'false', '3'),

  ('19b47c9f-2a1a-4330-9d3c-004257a31748', 'f3000002-0000-0000-0000-000000000015',
   'Le signaler (119, services sociaux, police)',
   'true', '0'),

  ('c53928e6-f0ff-4ae2-8e88-1eefbd7a01c9', 'f3000002-0000-0000-0000-000000000015',
   'Rien faire',
   'false', '1'),

  ('4687cec0-b82f-47ed-8322-22b17a847868', 'f3000002-0000-0000-0000-000000000015',
   'Le signaler dans 6 mois',
   'false', '2'),

  ('be5e6592-47bf-4530-9d1e-bbad5f148d38', 'f3000002-0000-0000-0000-000000000015',
   'Demander à la famille',
   'false', '3'),

  ('d0a3b7d2-e038-48ac-8e61-e7ee26013075', 'f3000002-0000-0000-0000-000000000016',
   'Oui, via la Sécurité sociale (PUMA)',
   'true', '0'),

  ('7611bdaf-6e24-4058-9eb7-f90ecd0b05d9', 'f3000002-0000-0000-0000-000000000016',
   'Non, jamais',
   'false', '1'),

  ('35550e83-3569-4755-b329-ba5ec5e73c00', 'f3000002-0000-0000-0000-000000000016',
   'Uniquement les Français',
   'false', '2'),

  ('1078a313-2311-40cd-bee6-202abc6e7aac', 'f3000002-0000-0000-0000-000000000016',
   'Uniquement les retraités',
   'false', '3'),

  ('651a8819-5157-49b5-b8f9-aff79741594a', 'f3000002-0000-0000-0000-000000000017',
   'Oui, de 3 à 16 ans',
   'true', '0'),

  ('aeb07113-a496-48a8-a09f-804676f51ccd', 'f3000002-0000-0000-0000-000000000017',
   'Non, c''est facultatif',
   'false', '1'),

  ('0f591f36-6d7b-41cf-b14a-51958dd3b980', 'f3000002-0000-0000-0000-000000000017',
   'Uniquement les français',
   'false', '2'),

  ('766c150d-9cae-420a-90c7-b89353caa608', 'f3000002-0000-0000-0000-000000000017',
   'Uniquement les filles',
   'false', '3'),

  ('ad12654b-e1cf-4261-b847-afd408bb278a', 'f3000002-0000-0000-0000-000000000018',
   'Non, elle est gratuite (depuis 1881)',
   'true', '0'),

  ('abde2f29-de11-4435-8ef6-8430476fe46e', 'f3000002-0000-0000-0000-000000000018',
   'Oui, l''inscription coûte cher',
   'false', '1'),

  ('c5f8ffcb-ae42-4c34-bdac-85d83e2a9235', 'f3000002-0000-0000-0000-000000000018',
   'Uniquement le lycée est gratuit',
   'false', '2'),

  ('a2f39177-4e05-40f4-9af4-cc7677298857', 'f3000002-0000-0000-0000-000000000018',
   'Uniquement les enfants pauvres',
   'false', '3'),

  ('a287d695-21eb-4984-92c7-65374733e84d', 'f3000002-0000-0000-0000-000000000019',
   'Non, le SMIC est un minimum légal',
   'true', '0'),

  ('3dd0357c-fd5b-4ce2-be23-fb991a5c2639', 'f3000002-0000-0000-0000-000000000019',
   'Oui, c''est libre',
   'false', '1'),

  ('6ba255fa-0bba-439c-bd68-37b8cf2f6c20', 'f3000002-0000-0000-0000-000000000019',
   'Uniquement aux jeunes',
   'false', '2'),

  ('9107a158-b6b6-48e3-bfa3-a8bc3be19b6c', 'f3000002-0000-0000-0000-000000000019',
   'Uniquement aux apprentis',
   'false', '3'),

  ('1c672926-9e30-4436-874e-662982724fe9', 'f3000002-0000-0000-0000-00000000001a',
   'Non, c''est interdit et puni',
   'true', '0'),

  ('542520c3-3e77-430c-a2c7-f48b9fcf6211', 'f3000002-0000-0000-0000-00000000001a',
   'Oui, c''est libre',
   'false', '1'),

  ('b5f80597-84c7-4fd3-aaf5-9ab4d7198988', 'f3000002-0000-0000-0000-00000000001a',
   'Uniquement quelques heures',
   'false', '2'),

  ('870aed7a-a03e-4ed9-9be0-8aaa9b4b489c', 'f3000002-0000-0000-0000-00000000001a',
   'Uniquement entre proches',
   'false', '3'),

  ('c56c3deb-8776-4a40-97fa-c589c1a1ccef', 'f3000002-0000-0000-0000-00000000001b',
   '35 heures légales, 48 heures maximum absolu',
   'true', '0'),

  ('e102266f-cb6c-490b-a19a-f834d714021c', 'f3000002-0000-0000-0000-00000000001b',
   '20 heures maximum',
   'false', '1'),

  ('a936c7a6-50b2-40dc-8822-0307c6dc5407', 'f3000002-0000-0000-0000-00000000001b',
   '60 heures légales',
   'false', '2'),

  ('ce99653a-fd5d-4a0b-9ea8-74d5aa86a112', 'f3000002-0000-0000-0000-00000000001b',
   'Aucune limite',
   'false', '3'),

  ('bce5c1de-c6ad-4438-9d2e-b58cf5826e75', 'f3000002-0000-0000-0000-00000000001c',
   '5 semaines (25 jours ouvrés)',
   'true', '0'),

  ('82e0332c-9a21-4166-b8aa-9448224f0164', 'f3000002-0000-0000-0000-00000000001c',
   '2 semaines',
   'false', '1'),

  ('ce6ca2dc-5968-4ec8-98b9-cfdc15d7042e', 'f3000002-0000-0000-0000-00000000001c',
   '10 semaines',
   'false', '2'),

  ('1bd8ccc8-3dd4-45e7-8170-72763103823e', 'f3000002-0000-0000-0000-00000000001c',
   'Aucun congé légal',
   'false', '3'),

  ('9b9e12dd-c007-4c29-926c-08b5bbccbbf3', 'f3000002-0000-0000-0000-00000000001d',
   '17 police, 18 pompiers, 15 SAMU, 112 européen',
   'true', '0'),

  ('2d227406-e415-46bb-91e3-5902dd43ddaa', 'f3000002-0000-0000-0000-00000000001d',
   'Un seul numéro suffit',
   'false', '1'),

  ('0afaa27b-061c-4ea9-ae32-e36993f00dc6', 'f3000002-0000-0000-0000-00000000001d',
   'Le 36 36 pour tout',
   'false', '2'),

  ('61cd2b34-2666-44d8-8739-2f98d9adb4a8', 'f3000002-0000-0000-0000-00000000001d',
   'Aucun numéro spécifique',
   'false', '3'),

  ('f4a93849-6720-4e62-a752-1adde34cbe60', 'f3000002-0000-0000-0000-00000000001e',
   'Oui, c''est un devoir civique',
   'true', '0'),

  ('99f9254d-22ae-4ca6-970d-3bf6ac66ccd4', 'f3000002-0000-0000-0000-00000000001e',
   'Non, c''est facultatif',
   'false', '1'),

  ('8cae6106-a5ff-42a1-9e03-b9701d0891a8', 'f3000002-0000-0000-0000-00000000001e',
   'Uniquement les décisions favorables',
   'false', '2'),

  ('839436c3-ab3c-4d48-8a8f-21c7d696b57b', 'f3000002-0000-0000-0000-00000000001e',
   'Uniquement les décisions européennes',
   'false', '3'),

  ('806744af-10f0-4f8d-b6ea-a0716da8ab20', 'f3000002-0000-0000-0000-00000000001f',
   'Oui, le faux témoignage est puni',
   'true', '0'),

  ('9c2a9ede-2155-4aaa-8212-45cae84179ec', 'f3000002-0000-0000-0000-00000000001f',
   'Non, on peut mentir',
   'false', '1'),

  ('014233db-970e-4201-8684-29a561e87dfe', 'f3000002-0000-0000-0000-00000000001f',
   'Uniquement les adultes doivent dire vrai',
   'false', '2'),

  ('13b0f3ea-8d0d-44b2-8ded-7f604f1d57c5', 'f3000002-0000-0000-0000-00000000001f',
   'Uniquement les écrits sont obligatoires',
   'false', '3'),

  ('de773a6f-e996-4c4b-83ad-21cc77bdeb00', 'f3000002-0000-0000-0000-000000000020',
   'Le secret professionnel',
   'true', '0'),

  ('ac9462d9-93ca-4c3c-9be0-1f3c513be02c', 'f3000002-0000-0000-0000-000000000020',
   'Le silence administratif',
   'false', '1'),

  ('d5dac95e-fbb9-4d3a-a1b0-e9a9b43cc16d', 'f3000002-0000-0000-0000-000000000020',
   'Le serment d''allégeance',
   'false', '2'),

  ('3445c5b0-4f02-4cd3-859d-e0d955fc8cfb', 'f3000002-0000-0000-0000-000000000020',
   'La discrétion volontaire',
   'false', '3'),

  ('93f234a9-b384-4e98-a62d-242c12f36b59', 'f3000002-0000-0000-0000-000000000021',
   'Non, un cadre légal est nécessaire',
   'true', '0'),

  ('e6d4f671-9e0a-400a-947a-c2fc88a71286', 'f3000002-0000-0000-0000-000000000021',
   'Oui, sans aucune condition',
   'false', '1'),

  ('f1759d00-7d13-4cb6-9591-c46de25cf866', 'f3000002-0000-0000-0000-000000000021',
   'Oui, uniquement la nuit',
   'false', '2'),

  ('723ec322-1292-4aa9-b1b3-af7aec0fd9db', 'f3000002-0000-0000-0000-000000000021',
   'Oui, sur autoroute uniquement',
   'false', '3'),

  ('b64240d7-33c7-4b2b-8183-eda23bc9db28', 'f3000002-0000-0000-0000-000000000022',
   'La liberté d''aller et venir',
   'true', '0'),

  ('b3b9cd34-7d32-4aaa-83c8-3f65f7dfe96e', 'f3000002-0000-0000-0000-000000000022',
   'La liberté de propriété',
   'false', '1'),

  ('2fa05c62-ec18-4e43-b1a1-335e4609a996', 'f3000002-0000-0000-0000-000000000022',
   'La liberté de la presse',
   'false', '2'),

  ('cb660b74-ee03-4849-bceb-10e23919a05d', 'f3000002-0000-0000-0000-000000000022',
   'La liberté religieuse',
   'false', '3'),

  ('607421cb-322c-4513-8d60-82d2ce95203b', 'f3000002-0000-0000-0000-000000000023',
   'Oui, en se constituant partie civile',
   'true', '0'),

  ('8fa2f7a6-05a2-4894-b017-f471b73206b9', 'f3000002-0000-0000-0000-000000000023',
   'Non, jamais',
   'false', '1'),

  ('e0e2a78f-79a6-45ec-bec9-00d8d6d23026', 'f3000002-0000-0000-0000-000000000023',
   'Uniquement pour les agressions physiques',
   'false', '2'),

  ('c03ed382-1457-49c9-8001-0f6e7df1efba', 'f3000002-0000-0000-0000-000000000023',
   'Uniquement les Français',
   'false', '3'),

  ('0e2644bd-5e60-4645-aa3a-fd975bf73fbc', 'f3000002-0000-0000-0000-000000000024',
   'Oui, aboli en 1848 et puni en tant que crime',
   'true', '0'),

  ('2959a432-7757-4b58-a148-138b039e1bf8', 'f3000002-0000-0000-0000-000000000024',
   'Non, encore toléré parfois',
   'false', '1'),

  ('22ff9d4c-3985-4a0c-b3f1-55c335affb94', 'f3000002-0000-0000-0000-000000000024',
   'Uniquement entre adultes',
   'false', '2'),

  ('9c7a97b4-d3b0-4496-90db-51ead2b18f82', 'f3000002-0000-0000-0000-000000000024',
   'Uniquement dans certains métiers',
   'false', '3'),

  ('557bfb88-f067-4cf4-a392-b70916678785', 'f3000002-0000-0000-0000-000000000025',
   'Non, c''est de la corruption, un délit grave',
   'true', '0'),

  ('f76dc46a-ffc1-4631-bb4f-d2cb40594d42', 'f3000002-0000-0000-0000-000000000025',
   'Oui, c''est une coutume',
   'false', '1'),

  ('416f390f-ef59-4481-89b4-e46377c7de85', 'f3000002-0000-0000-0000-000000000025',
   'Uniquement sur les marchés',
   'false', '2'),

  ('62c2df62-487f-4b28-be84-b017f90de87f', 'f3000002-0000-0000-0000-000000000025',
   'Uniquement le dimanche',
   'false', '3'),

  ('cf0bdaad-4aac-4725-8463-70424447b600', 'f3000002-0000-0000-0000-000000000026',
   'Oui, c''est une obligation civique et légale',
   'true', '0'),

  ('8d706115-2e13-457a-86d6-9ff99b75e255', 'f3000002-0000-0000-0000-000000000026',
   'Non, c''est facultatif',
   'false', '1'),

  ('7b585d5a-7000-4376-9695-c200a8df76b4', 'f3000002-0000-0000-0000-000000000026',
   'Uniquement les week-ends',
   'false', '2'),

  ('369ca038-2cd1-4cb3-a871-13083b54c6ad', 'f3000002-0000-0000-0000-000000000026',
   'Uniquement le verre',
   'false', '3'),

  ('30b723b8-591d-4db8-b3ef-83b67a5ffc3a', 'f3000002-0000-0000-0000-000000000027',
   'Le 3919',
   'true', '0'),

  ('745511cf-3f10-4143-9928-532e8fbe2c7c', 'f3000002-0000-0000-0000-000000000027',
   'Le 15',
   'false', '1'),

  ('fbf42298-2d74-4cdd-8f0c-d7b6b7de5bc1', 'f3000002-0000-0000-0000-000000000027',
   'Le 17',
   'false', '2'),

  ('b3417a7c-cd1d-430b-b720-f42b38435304', 'f3000002-0000-0000-0000-000000000027',
   'Le 36 36',
   'false', '3'),

  ('96bd785a-b51f-4344-acaf-3781ae6f753c', 'f3000002-0000-0000-0000-000000000028',
   'Oui, c''est un délit puni par la loi',
   'true', '0'),

  ('9cdb7bb8-1007-4b86-b33a-736240c07b52', 'f3000002-0000-0000-0000-000000000028',
   'Non, c''est une opinion protégée',
   'false', '1'),

  ('68064287-9ea2-4ccc-b445-99d614584735', 'f3000002-0000-0000-0000-000000000028',
   'Uniquement en public',
   'false', '2'),

  ('519b91df-33d0-4599-8b40-9a749d097e5a', 'f3000002-0000-0000-0000-000000000028',
   'Uniquement sur internet',
   'false', '3');
