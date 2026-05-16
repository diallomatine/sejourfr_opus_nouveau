-- ============================================================================
-- V21 : Lot 7 TCF — B1 complet avec distracteurs durcis
-- ============================================================================
-- 📋 24 questions B1 :
--    - 12 questions image (e-mail pro, affiche, capture app, annonce, fidélité, site admin)
--    - 12 questions texte (passages 150-220 mots)
--
-- 🎯 Toutes appliquent les nouvelles règles B1 :
--    - ≥2 distracteurs piégeux sur 3
--    - Pas de réponse évidente, le candidat doit analyser
--    - Stratégies : vrai mais hors champ, reformulation faussée,
--                   inversion de locuteur, presque-synonyme trompeur
--    - Au moins 1 fausse piste dans le document
--
-- 📊 Répartition des compétences :
--    - ce_detail_specifique     : 6
--    - ce_reformulation         : 5
--    - ce_inference_intention   : 5
--    - ce_idee_principale       : 4
--    - ce_reperage_explicite    : 4
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 📄 1. PASSAGES TEXTE (6) — Plage V21 : 44444444-0021-*
-- ----------------------------------------------------------------------------

INSERT INTO passages (id, type, content, theme_id) VALUES

-- ────────── Passage 1 — Travail : pot de départ (Q13-Q14) ──────────
(
    '44444444-0021-0000-0000-000000000001', 'TEXTE',
    E'Chers tous,\n\n' ||
    E'Comme vous le savez, Sandrine quitte notre équipe à la fin du mois après huit années chez nous. Nous organisons un pot de départ le vendredi 28, à partir de 17h30 en salle de réunion.\n\n' ||
    E'Pour le cadeau collectif, Marc se charge de la cagnotte (15 € par personne, en espèces ou par virement avant mercredi soir). Si vous souhaitez participer à la collecte sans pouvoir venir au pot, prévenez-le directement.\n\n' ||
    E'Côté logistique, Camille apporte les boissons, et chacun amène quelque chose à grignoter (sucré ou salé, selon vos envies). Inutile de prévoir des assiettes, j''en ai en réserve au bureau.\n\n' ||
    E'À vendredi,\nThomas',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 2 — Logement : règlement de copropriété (Q15-Q16) ──────────
(
    '44444444-0021-0000-0000-000000000002', 'TEXTE',
    E'Extrait du règlement de copropriété — Résidence Les Glycines\n\n' ||
    E'Article 12 — Vie en collectivité. Les nuisances sonores sont à éviter en permanence, et particulièrement entre 22h et 7h en semaine, ainsi qu''à partir de 21h les vendredis et samedis. Les travaux bruyants (perceuse, marteau) ne sont autorisés que du lundi au samedi, entre 9h et 12h puis entre 14h et 19h.\n\n' ||
    E'Article 13 — Animaux. La présence d''animaux de compagnie est tolérée, à l''exclusion des chiens classés comme dangereux. Les propriétaires sont tenus de garder leurs animaux en laisse dans les parties communes et d''éviter tout aboiement répété susceptible de gêner les voisins.\n\n' ||
    E'Article 14 — Parties communes. Il est strictement interdit de stocker tout objet personnel dans les couloirs, le hall d''entrée et les paliers.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 3 — Consommation : avis client (Q17-Q18) ──────────
(
    '44444444-0021-0000-0000-000000000003', 'TEXTE',
    E'Avis client publié sur la plateforme — Hôtel Le Petit Coin, Avignon\n\n' ||
    E'Nous avons passé trois nuits dans cet hôtel en août. Globalement, c''était un bon séjour, même si tout n''a pas été parfait.\n\n' ||
    E'Les points positifs d''abord : l''emplacement est excellent, à dix minutes à pied du centre historique. Le personnel s''est montré attentif, particulièrement la réceptionniste qui nous a recommandé d''excellents restaurants. Le petit-déjeuner buffet était varié et de qualité.\n\n' ||
    E'En revanche, deux points nous ont gênés. D''abord la climatisation de notre chambre, en panne le premier soir, et seulement réparée le lendemain matin malgré nos demandes répétées. Ensuite, le bruit de la rue, audible dès 6h du matin, fenêtres fermées comprises.\n\n' ||
    E'Au final, malgré ces désagréments, nous reviendrions, mais cette fois en demandant une chambre côté cour.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 4 — Loisirs : présentation d'un club (Q19-Q20) ──────────
(
    '44444444-0021-0000-0000-000000000004', 'TEXTE',
    E'Bienvenue au Club de tennis municipal de Saint-Médard !\n\n' ||
    E'Notre club accueille les joueurs de tous niveaux, des débutants complets aux compétiteurs expérimentés. Nous proposons quatre formules d''adhésion : licence loisir (160 € par an), licence compétition (240 € par an), forfait jeunes moins de 18 ans (95 € par an) et forfait découverte 3 mois (60 €) pour les nouveaux adhérents qui hésitent encore.\n\n' ||
    E'Les courts sont accessibles tous les jours de 8h à 22h, y compris le dimanche. La réservation se fait obligatoirement en ligne via notre site, au minimum deux jours à l''avance pour les courts couverts, et la veille pour les courts extérieurs.\n\n' ||
    E'Bon à savoir : la première semaine de septembre, nous organisons des séances d''essai gratuites pour les non-adhérents curieux de découvrir le club.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 5 — Santé : newsletter (Q21-Q22) ──────────
(
    '44444444-0021-0000-0000-000000000005', 'TEXTE',
    E'Newsletter santé du mois — Bien dormir en été\n\n' ||
    E'Les nuits chaudes perturbent fréquemment le sommeil de nombreuses personnes. Voici quelques conseils simples, validés par les spécialistes du sommeil, pour mieux dormir quand la température grimpe.\n\n' ||
    E'D''abord, gardez votre chambre fraîche : fermez les volets dès le matin et n''ouvrez les fenêtres qu''à la nuit tombée, quand l''air extérieur est plus frais. Évitez les douches glacées juste avant de dormir : contre-intuitif, mais elles relancent l''activité du corps. Préférez une douche tiède, vingt minutes avant le coucher.\n\n' ||
    E'Côté alimentation, dînez léger et au moins deux heures avant de vous coucher. L''alcool, souvent perçu comme un facilitateur d''endormissement, dégrade en réalité la qualité du sommeil profond.\n\n' ||
    E'Enfin, si la chaleur reste insupportable malgré ces gestes, sachez qu''un ventilateur orienté vers un saladier rempli de glaçons crée une sensation très efficace de fraîcheur.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 6 — Transports : info voyageurs (Q23-Q24) ──────────
(
    '44444444-0021-0000-0000-000000000006', 'TEXTE',
    E'Information voyageurs — Ligne TER Toulouse-Auch\n\n' ||
    E'En raison de travaux d''entretien de la voie, plusieurs modifications affecteront la circulation des trains entre le 15 et le 30 mars inclus.\n\n' ||
    E'En semaine, le train de 7h12 au départ de Toulouse partira exceptionnellement à 7h35, sans modification des arrêts. Les trains du soir circulent normalement, à l''exception du 19h40 qui sera supprimé et remplacé par un service routier au départ de la gare routière d''Auch.\n\n' ||
    E'Le week-end, aucun train ne circulera sur l''ensemble de la ligne. Des autocars de remplacement assureront les liaisons, avec des temps de trajet allongés d''environ 25 minutes. Les billets déjà achetés restent valables, sans démarche supplémentaire de votre part.\n\n' ||
    E'Nous vous remercions de votre compréhension et vous invitons à consulter notre site pour les horaires actualisés.',
    '22222222-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;


-- ----------------------------------------------------------------------------
-- 🖼️ 2. MEDIAS (6 SVG) — Plage V21 : 33333333-0021-*
-- ----------------------------------------------------------------------------

INSERT INTO medias (id, type, url, alt_text, inline_svg) VALUES

-- ────────── Media 1 : E-mail professionnel — changement réunion ──────────
(
    '33333333-0021-0000-0000-000000000001',
    'IMAGE',
    NULL,
    'E-mail professionnel d''un manager annonçant à son équipe le report d''une réunion initialement prévue le mardi à 10h, désormais reportée au jeudi à 14h en salle B, avec un changement d''ordre du jour.',
    '<svg width="100%" viewBox="0 0 680 580" role="img" xmlns="http://www.w3.org/2000/svg"><title>E-mail professionnel : report de réunion</title><desc>E-mail d''un manager à son équipe pour reporter une réunion et modifier l''ordre du jour.</desc><rect x="0" y="0" width="680" height="580" fill="#F1F3F4"/><rect x="20" y="20" width="640" height="540" rx="8" fill="#FFFFFF" stroke="#DADCE0" stroke-width="1"/><rect x="20" y="20" width="640" height="50" fill="#FFFFFF"/><line x1="20" y1="70" x2="660" y2="70" stroke="#DADCE0" stroke-width="0.5"/><g transform="translate(40, 32)"><rect x="0" y="4" width="20" height="2" fill="#5F6368" rx="1"/><rect x="0" y="11" width="20" height="2" fill="#5F6368" rx="1"/><rect x="0" y="18" width="20" height="2" fill="#5F6368" rx="1"/></g><text x="80" y="50" font-family="Arial, sans-serif" font-size="18" font-weight="500" fill="#5F6368">Boîte de réception</text><g transform="translate(580, 30)"><rect x="0" y="0" width="32" height="32" rx="16" fill="#1A73E8"/><text x="16" y="22" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#FFFFFF">T</text></g><rect x="40" y="100" width="600" height="440" fill="#FFFFFF"/><text x="40" y="128" font-family="Arial, sans-serif" font-size="17" font-weight="600" fill="#202124">Report de la réunion d''équipe — modification d''horaire</text><g transform="translate(40, 152)"><circle cx="20" cy="20" r="20" fill="#34A853"/><text x="20" y="26" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" font-weight="600" fill="#FFFFFF">T</text></g><text x="92" y="164" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#202124">Thomas Berger</text><text x="190" y="164" font-family="Arial, sans-serif" font-size="12" fill="#5F6368">&lt;thomas.b@entreprise.fr&gt;</text><text x="92" y="183" font-family="Arial, sans-serif" font-size="12" fill="#5F6368">à équipe-projet</text><text x="600" y="164" text-anchor="end" font-family="Arial, sans-serif" font-size="11" fill="#5F6368">Aujourd''hui 09:14</text><line x1="40" y1="210" x2="640" y2="210" stroke="#DADCE0" stroke-width="0.5"/><text x="40" y="244" font-family="Arial, sans-serif" font-size="13" fill="#202124">Bonjour à tous,</text><text x="40" y="276" font-family="Arial, sans-serif" font-size="13" fill="#202124">Petit changement de programme : <tspan font-weight="700">la réunion d''équipe initialement prévue</tspan></text><text x="40" y="294" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#202124">mardi à 10h est reportée à jeudi 14h en salle B</text><text x="350" y="294" font-family="Arial, sans-serif" font-size="13" fill="#202124"> (et non plus en salle A).</text><text x="40" y="328" font-family="Arial, sans-serif" font-size="13" fill="#202124">Nous y aborderons les points suivants :</text><text x="60" y="354" font-family="Arial, sans-serif" font-size="13" fill="#202124">• Bilan du trimestre (Camille)</text><text x="60" y="376" font-family="Arial, sans-serif" font-size="13" fill="#202124">• Présentation du nouveau client (Marc)</text><text x="60" y="398" font-family="Arial, sans-serif" font-size="13" fill="#202124">• Recrutement en cours (moi-même)</text><text x="40" y="430" font-family="Arial, sans-serif" font-size="13" fill="#202124">Le point sur le budget annuel, que nous devions traiter mardi, est <tspan font-weight="700">décalé</tspan></text><text x="40" y="448" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#202124">à la prochaine réunion de la semaine suivante</text><text x="380" y="448" font-family="Arial, sans-serif" font-size="13" fill="#202124">, faute de temps.</text><text x="40" y="482" font-family="Arial, sans-serif" font-size="13" fill="#202124">Merci de confirmer votre présence avant mercredi midi.</text><text x="40" y="514" font-family="Arial, sans-serif" font-size="13" fill="#202124">Bonne journée,</text><text x="40" y="532" font-family="Arial, sans-serif" font-size="13" fill="#202124">Thomas</text></svg>'
),

-- ────────── Media 2 : Affiche atelier cuisine ──────────
(
    '33333333-0021-0000-0000-000000000002',
    'IMAGE',
    NULL,
    'Affiche annonçant un atelier cuisine "Pâtisserie d''automne" le samedi 12 octobre à 14h, 35 euros par personne, places limitées à 8 participants, sur inscription préalable. Niveau débutant accepté, matériel et tablier fournis.',
    '<svg width="100%" viewBox="0 0 680 800" role="img" xmlns="http://www.w3.org/2000/svg"><title>Affiche atelier cuisine pâtisserie d''automne</title><desc>Affiche d''un atelier cuisine de pâtisserie le samedi 12 octobre à 14h, 35 euros, 8 places maximum.</desc><rect x="0" y="0" width="680" height="800" fill="#FAEEDA"/><rect x="40" y="40" width="600" height="720" fill="#FFFFFF" stroke="#854F0B" stroke-width="3"/><rect x="60" y="60" width="560" height="80" fill="#854F0B"/><text x="340" y="100" text-anchor="middle" font-family="Georgia, serif" font-size="28" font-weight="700" fill="#FFFFFF">L''ATELIER DU GOÛT</text><text x="340" y="125" text-anchor="middle" font-family="Georgia, serif" font-size="13" font-style="italic" fill="#FAEEDA">cours de cuisine en petit comité</text><text x="340" y="200" text-anchor="middle" font-family="Arial, sans-serif" font-size="15" font-weight="600" fill="#854F0B">PROCHAIN ATELIER</text><line x1="280" y1="212" x2="400" y2="212" stroke="#E1372F" stroke-width="2"/><text x="340" y="250" text-anchor="middle" font-family="Georgia, serif" font-size="32" font-weight="700" fill="#0F1839">Pâtisserie d''automne</text><text x="340" y="280" text-anchor="middle" font-family="Georgia, serif" font-size="15" font-style="italic" fill="#5C6573">tarte aux pommes, crumble &amp; financiers</text><g transform="translate(140, 320)"><rect x="0" y="0" width="180" height="80" rx="8" fill="#FFF8E8" stroke="#854F0B" stroke-width="1"/><text x="90" y="24" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#854F0B">QUAND</text><text x="90" y="48" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#0F1839">Samedi 12 octobre</text><text x="90" y="68" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#E1372F">14h — 17h</text></g><g transform="translate(360, 320)"><rect x="0" y="0" width="180" height="80" rx="8" fill="#FFF8E8" stroke="#854F0B" stroke-width="1"/><text x="90" y="24" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#854F0B">TARIF</text><text x="90" y="56" text-anchor="middle" font-family="Arial, sans-serif" font-size="28" font-weight="700" fill="#E1372F">35 €</text><text x="90" y="72" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#5C6573">par personne, tout inclus</text></g><line x1="120" y1="430" x2="560" y2="430" stroke="#854F0B" stroke-width="1" stroke-dasharray="4 4"/><g transform="translate(120, 460)"><circle cx="6" cy="8" r="3" fill="#168F5B"/><text x="20" y="12" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Tous niveaux acceptés, débutants bienvenus</text></g><g transform="translate(120, 488)"><circle cx="6" cy="8" r="3" fill="#168F5B"/><text x="20" y="12" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Matériel et tablier fournis sur place</text></g><g transform="translate(120, 516)"><circle cx="6" cy="8" r="3" fill="#168F5B"/><text x="20" y="12" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Vous repartez avec vos préparations</text></g><g transform="translate(120, 544)"><circle cx="6" cy="8" r="3" fill="#E1372F"/><text x="20" y="12" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#E1372F">8 places maximum — inscription préalable obligatoire</text></g><rect x="120" y="600" width="440" height="80" rx="6" fill="#854F0B"/><text x="340" y="624" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#FAEEDA">RÉSERVATION</text><text x="340" y="648" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#FFFFFF">par téléphone au 05 56 12 34 56</text><text x="340" y="668" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#FAEEDA">ou par mail : contact@latelier-du-gout.fr</text><text x="340" y="720" text-anchor="middle" font-family="Georgia, serif" font-size="11" font-style="italic" fill="#854F0B">12 rue des Tilleuls — 33000 Bordeaux</text></svg>'
),

-- ────────── Media 3 : Récap commande app de livraison ──────────
(
    '33333333-0021-0000-0000-000000000003',
    'IMAGE',
    NULL,
    'Capture d''écran d''une application de livraison de repas affichant le récapitulatif d''une commande : 2 plats, sous-total 24 euros, code promo nouveau-client appliqué (-5 euros), frais de livraison 2,50 euros, total 21,50 euros, livraison estimée dans 35-45 minutes.',
    '<svg width="100%" viewBox="0 0 680 760" role="img" xmlns="http://www.w3.org/2000/svg"><title>Application de livraison — récapitulatif de commande</title><desc>Capture d''écran d''une application de livraison de repas avec détail prix et code promo.</desc><rect x="0" y="0" width="680" height="760" fill="#F5F5F7"/><rect x="170" y="40" width="340" height="700" rx="32" fill="#1A1A1A"/><rect x="180" y="80" width="320" height="660" rx="4" fill="#FFFFFF"/><rect x="280" y="50" width="120" height="22" rx="11" fill="#1A1A1A"/><text x="200" y="104" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">9:42</text><g transform="translate(440, 92)"><rect x="0" y="0" width="3" height="8" rx="0.5" fill="#0F1839"/><rect x="5" y="-2" width="3" height="10" rx="0.5" fill="#0F1839"/><rect x="10" y="-4" width="3" height="12" rx="0.5" fill="#0F1839"/><rect x="15" y="-6" width="3" height="14" rx="0.5" fill="#0F1839"/></g><rect x="180" y="120" width="320" height="50" fill="#FF6B35"/><text x="340" y="150" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#FFFFFF">Récapitulatif</text><g transform="translate(200, 135)"><path d="M 6 0 L 0 8 L 6 16" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/></g><rect x="200" y="190" width="280" height="100" rx="8" fill="#FAFAFA" stroke="#E5E5E7" stroke-width="0.5"/><text x="216" y="216" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#0F1839">Le Petit Bistrot</text><text x="216" y="234" font-family="Arial, sans-serif" font-size="11" fill="#5F6368">⭐ 4,7 · Cuisine française · 1,2 km</text><line x1="216" y1="248" x2="464" y2="248" stroke="#E5E5E7" stroke-width="0.5"/><text x="216" y="268" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Tagliatelles aux champignons</text><text x="464" y="268" text-anchor="end" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">12,00 €</text><text x="216" y="284" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Steak frites maison</text><text x="464" y="284" text-anchor="end" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">12,00 €</text><rect x="200" y="310" width="280" height="160" rx="8" fill="#FAFAFA" stroke="#E5E5E7" stroke-width="0.5"/><text x="216" y="336" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#0F1839">Détail du paiement</text><text x="216" y="362" font-family="Arial, sans-serif" font-size="12" fill="#5F6368">Sous-total (2 plats)</text><text x="464" y="362" text-anchor="end" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">24,00 €</text><text x="216" y="384" font-family="Arial, sans-serif" font-size="12" fill="#168F5B">Code BIENVENUE (nouveau client)</text><text x="464" y="384" text-anchor="end" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#168F5B">−5,00 €</text><text x="216" y="406" font-family="Arial, sans-serif" font-size="12" fill="#5F6368">Frais de livraison</text><text x="464" y="406" text-anchor="end" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">+2,50 €</text><line x1="216" y1="420" x2="464" y2="420" stroke="#E5E5E7" stroke-width="0.5"/><text x="216" y="446" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#0F1839">Total à payer</text><text x="464" y="446" text-anchor="end" font-family="Arial, sans-serif" font-size="17" font-weight="700" fill="#FF6B35">21,50 €</text><rect x="200" y="490" width="280" height="90" rx="8" fill="#FFF6F0" stroke="#FF6B35" stroke-width="1"/><text x="216" y="514" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#FF6B35">🛵 LIVRAISON ESTIMÉE</text><text x="216" y="538" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#0F1839">35 — 45 minutes</text><text x="216" y="558" font-family="Arial, sans-serif" font-size="11" fill="#5F6368">soit entre 10h17 et 10h27</text><text x="216" y="572" font-family="Arial, sans-serif" font-size="10" font-style="italic" fill="#5F6368">Délais variables selon la circulation</text><rect x="200" y="600" width="280" height="48" rx="24" fill="#FF6B35"/><text x="340" y="630" text-anchor="middle" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#FFFFFF">Confirmer et payer 21,50 €</text><text x="340" y="680" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#5F6368">Code promo non cumulable avec d''autres offres</text></svg>'
),

-- ────────── Media 4 : Annonce vente d'occasion ──────────
(
    '33333333-0021-0000-0000-000000000004',
    'IMAGE',
    NULL,
    'Annonce de vente entre particuliers d''un vélo électrique d''occasion, 750 euros, état très bon, deux ans d''utilisation, vendu avec deux batteries, retrait uniquement sur place à Nantes.',
    '<svg width="100%" viewBox="0 0 680 700" role="img" xmlns="http://www.w3.org/2000/svg"><title>Annonce vente vélo électrique d''occasion</title><desc>Annonce entre particuliers d''un vélo électrique d''occasion à 750 euros à Nantes.</desc><rect x="0" y="0" width="680" height="700" fill="#F4F7FB"/><rect x="20" y="20" width="640" height="660" rx="8" fill="#FFFFFF" stroke="#D5DDE3" stroke-width="1"/><rect x="20" y="20" width="640" height="56" rx="8" fill="#168F5B"/><text x="40" y="56" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#FFFFFF">OccaZpro</text><text x="115" y="56" font-family="Arial, sans-serif" font-size="11" fill="#E6F5EC">— ventes entre particuliers</text><text x="600" y="50" text-anchor="end" font-family="Arial, sans-serif" font-size="11" fill="#FFFFFF">📍 Nantes</text><rect x="20" y="76" width="640" height="180" fill="#E8F5EE"/><g transform="translate(280, 110)"><rect x="0" y="60" width="40" height="50" fill="#168F5B"/><circle cx="20" cy="120" r="30" fill="none" stroke="#0F1839" stroke-width="4"/><circle cx="100" cy="120" r="30" fill="none" stroke="#0F1839" stroke-width="4"/><line x1="20" y1="120" x2="100" y2="120" stroke="#0F1839" stroke-width="3"/><line x1="60" y1="120" x2="40" y2="80" stroke="#0F1839" stroke-width="3"/><line x1="60" y1="120" x2="80" y2="80" stroke="#0F1839" stroke-width="3"/><rect x="35" y="70" width="50" height="20" fill="#1E3A8C"/><text x="60" y="84" text-anchor="middle" font-family="Arial, sans-serif" font-size="9" font-weight="700" fill="#FFFFFF">BAT</text></g><g transform="translate(40, 280)"><rect x="0" y="0" width="100" height="24" rx="12" fill="#168F5B"/><text x="50" y="16" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#FFFFFF">Disponible</text><rect x="112" y="0" width="100" height="24" rx="12" fill="#E8ECF8"/><text x="162" y="16" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#1E3A8C">Très bon état</text></g><text x="40" y="340" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#0F1839">Vélo électrique Cityride</text><text x="40" y="360" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">Modèle 2023 · 2 ans d''utilisation · acheté 1 400 € neuf</text><text x="40" y="410" font-family="Arial, sans-serif" font-size="36" font-weight="700" fill="#168F5B">750 €</text><text x="200" y="410" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">prix ferme</text><text x="200" y="426" font-family="Arial, sans-serif" font-size="11" font-style="italic" fill="#5C6573">paiement en espèces ou virement</text><line x1="40" y1="450" x2="640" y2="450" stroke="#E0E2E7" stroke-width="1"/><g transform="translate(40, 480)"><text x="0" y="0" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#0F1839">Ce qui est inclus dans la vente</text><text x="0" y="24" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Le vélo en bon état général (quelques rayures sur le cadre)</text><text x="0" y="46" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• <tspan font-weight="700">Deux batteries</tspan> (une d''origine + une achetée en 2024)</text><text x="0" y="68" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Le chargeur et la facture d''origine</text><text x="0" y="90" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Un antivol U récent (acheté 50 €)</text></g><rect x="40" y="600" width="600" height="56" rx="4" fill="#FDECEB" stroke="#E1372F" stroke-width="1"/><text x="56" y="624" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#E1372F">⚠ CONDITIONS DE VENTE</text><text x="56" y="644" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Retrait <tspan font-weight="700">uniquement sur place à Nantes</tspan>. Pas d''envoi possible. Essai bienvenu.</text></svg>'
),

-- ────────── Media 5 : Carte de fidélité ──────────
(
    '33333333-0021-0000-0000-000000000005',
    'IMAGE',
    NULL,
    'Carte de fidélité d''une chaîne de boulangeries présentant les avantages : 10% sur les viennoiseries du lundi au vendredi, café offert à partir de 10 visites, exclusivement utilisable en boutique (pas en ligne), valable un an.',
    '<svg width="100%" viewBox="0 0 680 480" role="img" xmlns="http://www.w3.org/2000/svg"><title>Carte de fidélité boulangerie</title><desc>Carte de fidélité d''une chaîne de boulangeries avec liste des avantages et restrictions.</desc><rect x="0" y="0" width="680" height="480" fill="#F8F4E8"/><rect x="40" y="40" width="600" height="400" rx="12" fill="#FFFFFF" stroke="#854F0B" stroke-width="2"/><rect x="40" y="40" width="600" height="80" rx="12" fill="#854F0B"/><text x="60" y="78" font-family="Georgia, serif" font-size="24" font-weight="700" fill="#FAEEDA">Boulangerie du Coin</text><text x="60" y="100" font-family="Arial, sans-serif" font-size="12" font-style="italic" fill="#FAEEDA">depuis 1983 · 12 boutiques en France</text><rect x="540" y="60" width="80" height="36" rx="18" fill="#FAEEDA"/><text x="580" y="82" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#854F0B">FIDÉLITÉ</text><text x="60" y="156" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#854F0B">VOTRE CARTE</text><text x="60" y="184" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#0F1839">Mme Camille Lemoine</text><text x="60" y="206" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">N° 4521 · Valable jusqu''au 30 juin de l''année prochaine</text><line x1="60" y1="226" x2="620" y2="226" stroke="#D5C8A8" stroke-width="0.5"/><text x="60" y="254" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#854F0B">VOS AVANTAGES</text><g transform="translate(60, 274)"><circle cx="6" cy="8" r="3" fill="#168F5B"/><text x="20" y="12" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">−10% sur les viennoiseries du lundi au vendredi</text></g><g transform="translate(60, 298)"><circle cx="6" cy="8" r="3" fill="#168F5B"/><text x="20" y="12" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">Café offert à partir de 10 visites enregistrées</text></g><g transform="translate(60, 322)"><circle cx="6" cy="8" r="3" fill="#168F5B"/><text x="20" y="12" font-family="Arial, sans-serif" font-size="13" font-weight="600" fill="#0F1839">Invitation aux dégustations privées (2 par an)</text></g><rect x="60" y="350" width="560" height="70" rx="4" fill="#FDECEB" stroke="#E1372F" stroke-width="1"/><text x="76" y="372" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#E1372F">⚠ À NOTER</text><text x="76" y="390" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Avantages valables <tspan font-weight="700">uniquement en boutique</tspan>, jamais sur les commandes en ligne.</text><text x="76" y="404" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">La réduction ne s''applique pas le week-end ni sur les commandes spéciales.</text></svg>'
),

-- ────────── Media 6 : Site administratif — démarche en ligne ──────────
(
    '33333333-0021-0000-0000-000000000006',
    'IMAGE',
    NULL,
    'Capture d''écran d''un site administratif présentant les étapes d''une démarche de demande de carte grise en ligne, avec quatre étapes successives, durée estimée de traitement et liste des pièces nécessaires.',
    '<svg width="100%" viewBox="0 0 680 720" role="img" xmlns="http://www.w3.org/2000/svg"><title>Site administratif — demande de carte grise en ligne</title><desc>Capture d''écran d''un site administratif présentant la démarche de demande de carte grise.</desc><rect x="0" y="0" width="680" height="720" fill="#F0F4F8"/><rect x="20" y="20" width="640" height="680" rx="6" fill="#FFFFFF" stroke="#D5DDE3" stroke-width="1"/><rect x="20" y="20" width="640" height="50" fill="#1E3A8C"/><text x="40" y="50" font-family="Arial, sans-serif" font-size="16" font-weight="700" fill="#FFFFFF">DemarchesEnLigne.fr</text><text x="640" y="48" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#A8B0C5">Service officiel</text><rect x="40" y="90" width="600" height="40" rx="4" fill="#F4F8FB"/><text x="56" y="115" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Accueil  ›  Véhicules  ›  <tspan font-weight="600" fill="#1E3A8C">Demande de carte grise</tspan></text><text x="40" y="170" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#0F1839">Demande de carte grise en ligne</text><text x="40" y="194" font-family="Arial, sans-serif" font-size="13" fill="#5C6573">Démarche entièrement dématérialisée — durée estimée du traitement : 7 à 14 jours ouvrés</text><g transform="translate(40, 220)"><rect x="0" y="0" width="600" height="100" rx="6" fill="#FEF5DD" stroke="#A36E0A" stroke-width="1"/><text x="20" y="26" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#A36E0A">📋 PIÈCES À PRÉPARER AVANT DE COMMENCER</text><text x="20" y="50" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">• Pièce d''identité en cours de validité</text><text x="20" y="68" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">• Justificatif de domicile de <tspan font-weight="700">moins de 6 mois</tspan></text><text x="20" y="86" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">• Ancien certificat d''immatriculation (si véhicule d''occasion)</text></g><text x="40" y="354" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#0F1839">Étapes de la démarche</text><g transform="translate(40, 380)"><circle cx="20" cy="20" r="20" fill="#168F5B"/><text x="20" y="26" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">1</text><text x="56" y="20" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#0F1839">Création du dossier en ligne</text><text x="56" y="36" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">durée moyenne : 15 minutes</text></g><line x1="60" y1="420" x2="60" y2="440" stroke="#D5DDE3" stroke-width="1"/><g transform="translate(40, 440)"><circle cx="20" cy="20" r="20" fill="#168F5B"/><text x="20" y="26" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">2</text><text x="56" y="20" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#0F1839">Téléchargement des pièces justificatives</text><text x="56" y="36" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">format PDF, JPEG ou PNG, 4 Mo maximum par fichier</text></g><line x1="60" y1="480" x2="60" y2="500" stroke="#D5DDE3" stroke-width="1"/><g transform="translate(40, 500)"><circle cx="20" cy="20" r="20" fill="#168F5B"/><text x="20" y="26" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">3</text><text x="56" y="20" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#0F1839">Paiement sécurisé en ligne</text><text x="56" y="36" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">carte bancaire uniquement, le montant varie selon votre département</text></g><line x1="60" y1="540" x2="60" y2="560" stroke="#D5DDE3" stroke-width="1"/><g transform="translate(40, 560)"><circle cx="20" cy="20" r="20" fill="#1E3A8C"/><text x="20" y="26" text-anchor="middle" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">4</text><text x="56" y="20" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#0F1839">Réception de la carte grise par courrier</text><text x="56" y="36" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">à votre domicile, sous 7 à 14 jours ouvrés après validation</text></g><rect x="40" y="620" width="600" height="50" rx="4" fill="#E8F5EE"/><text x="56" y="640" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#168F5B">💡 BON À SAVOIR</text><text x="56" y="658" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Vous pouvez circuler avec un certificat provisoire pendant 1 mois, en attendant la carte définitive.</text></svg>'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 3. QUESTIONS IMAGE (12) — CE B1 image
-- ============================================================================
-- Plage UUID : 55555555-0021-0000-...

-- ──────────────────────────────────────────────────────────────────────────
-- 📧 Media 1 : E-mail report réunion (Q1-Q2)
-- ──────────────────────────────────────────────────────────────────────────

-- Q1 : repérage avec piège (nouvelle date)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000001', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Quand et où aura lieu la réunion finalement ?',
    'L''e-mail précise que la réunion « est reportée à jeudi 14h en salle B (et non plus en salle A) ». Il faut combiner le jour, l''heure et le bon lieu. La réponse C reformule correctement ces trois éléments. La réponse A reprend les informations initiales (avant le report) : c''est une inversion temporelle. La réponse B mélange la nouvelle date (jeudi) avec l''ancienne salle (A) : c''est une combinaison erronée. La réponse D inverse le lieu : la salle A n''est plus utilisée.',
    '33333333-0021-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000001', 'Mardi à 10h en salle A',  false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000001', 'Jeudi à 14h en salle A',  false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000001', 'Jeudi à 14h en salle B',  true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000001', 'Mardi à 14h en salle B',  false, 4);

-- Q2 : inférence sur le budget annuel
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000002', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Quand sera abordé le sujet du budget annuel ?',
    'L''e-mail indique que « le point sur le budget annuel, que nous devions traiter mardi, est décalé à la prochaine réunion de la semaine suivante ». Il sera donc abordé à la réunion suivante, soit une semaine plus tard. La réponse C reformule cette information. La réponse A est une reformulation faussée : le budget est précisément ce qui est retiré de l''ordre du jour de jeudi. La réponse B mélange deux dates citées dans le mail : la réunion de jeudi et la confirmation de mercredi midi. La réponse D propose une option non mentionnée et contraire (par mail) : Thomas convoque une réunion physique pour ce point.',
    '33333333-0021-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000002', 'Lors de la réunion de jeudi',                                       false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000002', 'Mercredi midi au plus tard',                                         false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000002', 'À la prochaine réunion la semaine suivante',                          true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000002', 'Par e-mail dans la journée',                                          false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🍰 Media 2 : Affiche atelier cuisine (Q3-Q4)
-- ──────────────────────────────────────────────────────────────────────────

-- Q3 : détail (places et conditions)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000003', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Quelles sont les conditions de participation à l''atelier ?',
    'L''affiche précise quatre éléments : « tous niveaux acceptés, débutants bienvenus », « matériel et tablier fournis », « 8 places maximum » et « inscription préalable obligatoire ». La réponse B reformule fidèlement ces conditions. La réponse A inverse le nombre de places (12 au lieu de 8) et est partiellement vraie sur les débutants. La réponse C est une demi-vérité : il faut bien réserver, mais pas en venant sur place — uniquement par téléphone ou mail. La réponse D inverse les éléments : le matériel est fourni, on ne doit pas l''apporter.',
    '33333333-0021-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000003', '12 places maximum, débutants acceptés, matériel fourni',                              false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000003', '8 places maximum, débutants bienvenus, inscription obligatoire',                       true,  2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000003', 'Inscription le jour même sur place, tous niveaux acceptés',                            false, 3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000003', 'Inscription obligatoire, matériel à apporter, débutants acceptés',                     false, 4);

-- Q4 : reformulation (que faut-il faire pour participer)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000004', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reformulation',
    'Comment réserver une place à cet atelier ?',
    'L''affiche indique « par téléphone au 05 56 12 34 56 ou par mail : contact@latelier-du-gout.fr ». Deux moyens sont donc proposés. La réponse C reformule cette information. La réponse A est une reformulation faussée : on ne se présente pas sur place (8 places maximum + inscription préalable obligatoire). La réponse B est partiellement vraie (le téléphone) mais omet l''option mail. La réponse D propose un canal non mentionné (site internet).',
    '33333333-0021-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000004', 'En se présentant directement sur place le jour de l''atelier',                          false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000004', 'Par téléphone uniquement',                                                              false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000004', 'Par téléphone ou par mail',                                                              true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000004', 'En remplissant un formulaire sur le site internet',                                     false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🛵 Media 3 : Récap commande livraison (Q5-Q6)
-- ──────────────────────────────────────────────────────────────────────────

-- Q5 : repérage avec calcul (montant total)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000005', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reperage_explicite',
    'Combien le client va-t-il payer au total ?',
    'L''écran affiche clairement « Total à payer : 21,50 € » sous le détail du paiement (24 − 5 + 2,50 = 21,50). La réponse D est correcte. La réponse A reprend le sous-total avant déduction et frais. La réponse B prend le sous-total moins la promo, sans les frais de livraison (calcul incomplet). La réponse C ajoute les frais de livraison au sous-total sans déduire la promo.',
    '33333333-0021-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000005', '24,00 €',  false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000005', '19,00 €',  false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000005', '26,50 €',  false, 3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000005', '21,50 €',  true,  4);

-- Q6 : inférence sur la réduction
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000006', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Pourquoi le client a-t-il bénéficié de 5 euros de réduction ?',
    'L''écran affiche « Code BIENVENUE (nouveau client) − 5,00 € ». La réduction est donc liée au statut de nouveau client de l''application. La réponse C reformule cette information. La réponse A est une reformulation faussée : il ne s''agit pas d''une promotion limitée dans le temps, mais d''une remise réservée aux nouveaux clients. La réponse B est une généralisation abusive : ce n''est pas le montant qui déclenche la promo. La réponse D adopte une position adjacente erronée : aucune mention de fidélité (au contraire, c''est pour les nouveaux clients).',
    '33333333-0021-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000006', 'C''est une promotion valable jusqu''à la fin de la semaine',                            false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000006', 'Toutes les commandes au-dessus de 20 € bénéficient de cette réduction',                false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000006', 'Il s''agit d''une remise réservée aux nouveaux clients de l''application',              true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000006', 'C''est un avantage lié à son ancienneté sur l''application',                            false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🚲 Media 4 : Vente vélo électrique (Q7-Q8)
-- ──────────────────────────────────────────────────────────────────────────

-- Q7 : détail (ce qui est inclus dans la vente)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000007', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Que l''acheteur recevra-t-il en plus du vélo ?',
    'L''annonce détaille quatre éléments inclus : deux batteries, le chargeur, la facture d''origine et un antivol U récent. La réponse B reformule l''essentiel : deux batteries + un antivol U. La réponse A est une demi-vérité : la batterie est citée, mais l''annonce en mentionne deux. La réponse C inverse l''information : la facture est incluse, pas le casque (jamais mentionné). La réponse D est une généralisation erronée : aucune révision en magasin n''est offerte.',
    '33333333-0021-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000007', 'Une batterie et un antivol',                                                            false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000007', 'Deux batteries, le chargeur, la facture et un antivol',                                  true,  2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000007', 'Deux batteries, un casque et le chargeur',                                                false, 3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000007', 'Le vélo et une révision gratuite en magasin',                                              false, 4);

-- Q8 : inférence (où récupérer le vélo)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000008', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Comment l''acheteur peut-il récupérer le vélo ?',
    'L''annonce indique en encart rouge « Retrait uniquement sur place à Nantes. Pas d''envoi possible. Essai bienvenu. ». La réponse C reformule cette contrainte. La réponse A est une reformulation faussée : aucun envoi par transporteur n''est proposé (« pas d''envoi possible »). La réponse B inverse la logique : c''est l''acheteur qui doit se déplacer, pas le vendeur. La réponse D mélange deux notions : l''essai est possible, mais sur place (pas en dehors de Nantes).',
    '33333333-0021-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000008', 'Par envoi via un transporteur, frais à sa charge',                                       false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000008', 'Le vendeur peut le livrer à domicile dans Nantes',                                       false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000008', 'En se déplaçant chez le vendeur à Nantes pour le récupérer',                              true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000008', 'En essayant d''abord le vélo dans une autre ville',                                       false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🥖 Media 5 : Carte de fidélité boulangerie (Q9-Q10)
-- ──────────────────────────────────────────────────────────────────────────

-- Q9 : repérage avec piège (avantages)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000009', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reperage_explicite',
    'Quand Camille peut-elle bénéficier de la réduction de 10% sur les viennoiseries ?',
    'L''encart vert indique « −10% sur les viennoiseries du lundi au vendredi », et l''encart rouge précise « la réduction ne s''applique pas le week-end ni sur les commandes spéciales ». La réponse C reformule ces deux informations cumulées. La réponse A est une reformulation faussée : la carte est valable jusqu''au 30 juin prochain, ce n''est pas une condition d''avantage. La réponse B inclut à tort le samedi (la réduction ne s''applique pas le week-end). La réponse D adopte une condition non mentionnée et trop restrictive.',
    '33333333-0021-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000009', 'Pendant toute la durée de validité de sa carte',                                          false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000009', 'Du lundi au samedi en boutique',                                                          false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000009', 'Du lundi au vendredi en boutique uniquement',                                              true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000009', 'Uniquement à partir de 10 visites enregistrées',                                            false, 4);

-- Q10 : inférence (limite de la carte)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000010', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Si Camille passe commande sur le site internet de la boulangerie, que se passe-t-il ?',
    'L''encart rouge indique : « Avantages valables uniquement en boutique, jamais sur les commandes en ligne. ». La réponse C reformule cette restriction. La réponse A est une reformulation faussée : les avantages ne se cumulent pas en ligne, ils ne s''appliquent pas du tout. La réponse B introduit une condition (week-end) qui n''est pas la cause réelle (c''est le canal en ligne). La réponse D est une généralisation abusive : la commande en ligne reste possible, simplement sans les avantages fidélité.',
    '33333333-0021-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000010', 'Elle bénéficie de la même réduction qu''en boutique',                                       false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000010', 'Elle bénéficie de la réduction uniquement si la commande est passée en semaine',           false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000010', 'Aucun avantage de la carte de fidélité ne s''applique sur cette commande',                  true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000010', 'Sa commande sera refusée tant qu''elle utilise sa carte de fidélité',                       false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🚗 Media 6 : Démarche carte grise en ligne (Q11-Q12)
-- ──────────────────────────────────────────────────────────────────────────

-- Q11 : détail (pièces à fournir)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000011', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Quelles pièces sont nécessaires pour commencer la démarche ?',
    'L''encart jaune liste trois pièces : pièce d''identité, justificatif de domicile de moins de 6 mois, et ancien certificat d''immatriculation si le véhicule est d''occasion. La réponse B reformule fidèlement ces trois pièces. La réponse A est une reformulation faussée : la condition d''ancienneté est de 6 mois, pas de 3 mois. La réponse C oublie le justificatif de domicile et introduit un permis de conduire jamais mentionné. La réponse D est une demi-vérité : la pièce d''identité est requise, mais les autres documents ne correspondent pas (avis d''imposition non mentionné).',
    '33333333-0021-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000011', 'Pièce d''identité et justificatif de domicile de moins de 3 mois',                          false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000011', 'Pièce d''identité, justificatif de domicile récent et ancien certificat d''immatriculation', true,  2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000011', 'Permis de conduire et ancien certificat d''immatriculation',                                 false, 3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000011', 'Pièce d''identité et avis d''imposition de l''année',                                          false, 4);

-- Q12 : inférence sur le délai et l'utilisation du véhicule
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000012', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Que peut faire le demandeur pendant qu''il attend sa carte grise définitive ?',
    'L''encart vert « bon à savoir » indique : « Vous pouvez circuler avec un certificat provisoire pendant 1 mois, en attendant la carte définitive. ». La réponse C reformule cette possibilité. La réponse A est une reformulation faussée : la durée du traitement est de 7 à 14 jours, mais le certificat provisoire permet de circuler entre-temps. La réponse B est une inversion : l''ancien certificat ne peut pas servir de titre après la vente. La réponse D adopte une formulation trop tranchée et fausse : il faut pouvoir prouver son droit de circuler, ce que permet justement le certificat provisoire.',
    '33333333-0021-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000012', 'Il doit attendre la carte définitive avant de pouvoir circuler avec son véhicule',           false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000012', 'Il peut continuer à utiliser l''ancien certificat d''immatriculation du véhicule',            false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000012', 'Il peut circuler pendant un mois avec un certificat provisoire',                              true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000012', 'Il peut circuler librement sans aucun document particulier',                                  false, 4);


-- ============================================================================
-- ❓ 4. QUESTIONS TEXTE (12) — CE B1 texte
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 1 : Pot de départ (Q13-Q14)
-- ──────────────────────────────────────────────────────────────────────────

-- Q13 : détail (qui apporte quoi)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000013', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Que doivent apporter les collègues qui viennent au pot ?',
    'Le mail indique que « Camille apporte les boissons » et que « chacun amène quelque chose à grignoter (sucré ou salé) ». Les collègues sont donc seulement chargés du grignotage. La réponse C reformule cette information. La réponse A est une inversion de locuteur : c''est Camille (et non l''ensemble du groupe) qui s''occupe des boissons. La réponse B inclut à tort le cadeau, alors que le cadeau est financé par la cagnotte gérée par Marc (15 € par personne, séparé). La réponse D oublie le grignotage et invente la vaisselle, qui est précisément ce que Thomas dispense d''apporter (« inutile de prévoir des assiettes »).',
    '44444444-0021-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000013', 'Des boissons et un cadeau personnel',                                                      false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000013', 'Quelque chose à grignoter et un cadeau personnel',                                          false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000013', 'Quelque chose à grignoter, sucré ou salé',                                                  true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000013', 'De la vaisselle et des boissons',                                                            false, 4);

-- Q14 : inférence (participation à la cagnotte sans venir)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000014', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Un collègue absent peut-il participer au cadeau ?',
    'Le mail précise : « Si vous souhaitez participer à la collecte sans pouvoir venir au pot, prévenez-le [Marc] directement. ». Une absence n''interdit donc pas la participation au cadeau, à condition de prévenir Marc. La réponse B reformule cette possibilité. La réponse A inverse la règle : la présence n''est pas requise pour participer à la cagnotte. La réponse C invente une condition (passer en main propre) non mentionnée. La réponse D est une demi-vérité : Marc gère bien la cagnotte, mais le mail indique qu''il faut justement le prévenir, pas qu''il faut s''adresser ailleurs.',
    '44444444-0021-0000-0000-000000000001',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000014', 'Non, il faut être présent au pot pour participer au cadeau',                                false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000014', 'Oui, à condition de prévenir directement Marc',                                              true,  2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000014', 'Oui, en lui donnant son argent en main propre le jour du pot',                                false, 3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000014', 'Oui, mais il doit s''adresser à Thomas directement',                                          false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 2 : Règlement de copropriété (Q15-Q16)
-- ──────────────────────────────────────────────────────────────────────────

-- Q15 : détail (horaires des travaux)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000015', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Un copropriétaire peut-il utiliser une perceuse le samedi matin ?',
    'L''article 12 précise : « Les travaux bruyants (perceuse, marteau) ne sont autorisés que du lundi au samedi, entre 9h et 12h puis entre 14h et 19h. ». Le samedi de 10h à 12h est donc autorisé. La réponse B reformule cette autorisation. La réponse A est une reformulation faussée : la perceuse est explicitement autorisée le samedi. La réponse C est une demi-vérité : les jours ouvrables sont autorisés, mais le samedi aussi. La réponse D introduit une condition (autorisation préalable) non mentionnée.',
    '44444444-0021-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000015', 'Non, les travaux bruyants sont interdits le samedi',                                        false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000015', 'Oui, entre 9h et 12h',                                                                       true,  2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000015', 'Oui, mais seulement les jours de semaine',                                                    false, 3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000015', 'Oui, à condition de prévenir le syndic au préalable',                                         false, 4);

-- Q16 : reformulation (règle sur les animaux)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000016', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reformulation',
    'Que dit le règlement à propos des animaux de compagnie ?',
    'L''article 13 indique que « la présence d''animaux est tolérée, à l''exclusion des chiens classés comme dangereux » et impose la laisse dans les parties communes. La réponse C reformule cette double règle. La réponse A est une généralisation abusive : seuls les chiens « classés comme dangereux » sont interdits, pas tous les chiens. La réponse B est une demi-vérité : la laisse est requise, mais l''interdiction des chiens dangereux est aussi importante. La réponse D inverse la règle : le texte ne demande pas d''accord écrit du syndic.',
    '44444444-0021-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000016', 'Tous les chiens sont interdits dans la copropriété',                                          false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000016', 'Les animaux sont autorisés à condition d''être tenus en laisse',                              false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000016', 'Les animaux sont acceptés sauf les chiens dangereux, et doivent être en laisse',              true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000016', 'Les animaux sont acceptés sur accord écrit du syndic uniquement',                              false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 3 : Avis client hôtel (Q17-Q18)
-- ──────────────────────────────────────────────────────────────────────────

-- Q17 : idée principale (impression générale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000017', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_idee_principale',
    'Quelle impression générale les clients ressortent-ils de leur séjour ?',
    'Les clients écrivent : « Globalement, c''était un bon séjour, même si tout n''a pas été parfait » et concluent « malgré ces désagréments, nous reviendrions ». Le bilan est donc positif mais nuancé. La réponse C reformule cette nuance. La réponse A est trop tranchée et déforme l''opinion : les clients ne sont pas pleinement satisfaits. La réponse B inverse le ton : ils ne sont pas globalement déçus, ils sont prêts à revenir. La réponse D est une reformulation faussée : ils ne déconseillent absolument pas l''hôtel.',
    '44444444-0021-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000017', 'Pleinement satisfaits, sans réserve',                                                         false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000017', 'Globalement déçus du séjour',                                                                  false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000017', 'Globalement satisfaits, malgré quelques désagréments',                                          true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000017', 'Insatisfaits au point de déconseiller l''hôtel',                                                false, 4);

-- Q18 : détail (problèmes rencontrés)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000018', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Quels problèmes les clients ont-ils rencontrés pendant leur séjour ?',
    'Le texte cite deux problèmes précis : la climatisation « en panne le premier soir, et seulement réparée le lendemain matin », et le bruit de la rue « audible dès 6h du matin, fenêtres fermées comprises ». La réponse C reformule ces deux points. La réponse A introduit un problème non mentionné (la propreté). La réponse B est une demi-vérité : la climatisation est citée, mais isolée du problème de bruit. La réponse D est une reformulation faussée : ils ont apprécié le personnel (« attentif »), ce n''est pas un problème.',
    '44444444-0021-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000018', 'Une chambre mal nettoyée et un personnel désagréable',                                       false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000018', 'Une climatisation en panne, uniquement',                                                       false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000018', 'Une climatisation tombée en panne et un bruit de rue très matinal',                            true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000018', 'Un personnel peu attentif et un petit-déjeuner médiocre',                                       false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 4 : Club de tennis (Q19-Q20)
-- ──────────────────────────────────────────────────────────────────────────

-- Q19 : détail (formules pour les nouveaux)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000019', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Que propose le club aux personnes qui hésitent encore à s''inscrire ?',
    'Le texte précise que la formule « forfait découverte 3 mois (60 €) » est destinée aux « nouveaux adhérents qui hésitent encore », et qu''« en septembre, des séances d''essai gratuites » sont proposées aux non-adhérents. La réponse B combine correctement ces deux offres. La réponse A est une généralisation abusive : la première semaine de gratuité concerne uniquement les non-adhérents en septembre. La réponse C confond les formules : 60 € est le forfait découverte, pas la licence loisir (qui est à 160 €). La réponse D mélange deux tarifs : 60 € est bien le forfait découverte, mais sa durée est de 3 mois, pas illimitée.',
    '44444444-0021-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000019', 'Une première semaine d''accès gratuit, toute l''année',                                       false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000019', 'Un forfait découverte 3 mois à 60 € et des séances d''essai gratuites en septembre',          true,  2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000019', 'Une licence loisir à 60 € au lieu de 160 €',                                                     false, 3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000019', 'Un accès illimité à 60 € pour les hésitants',                                                    false, 4);

-- Q20 : reformulation (réservation des courts)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000020', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reformulation',
    'Comment réserver un court de tennis ?',
    'Le texte précise : « La réservation se fait obligatoirement en ligne via notre site, au minimum deux jours à l''avance pour les courts couverts, et la veille pour les courts extérieurs. ». La réponse C reformule cette double règle. La réponse A est une généralisation abusive : le délai de 2 jours ne s''applique qu''aux courts couverts. La réponse B est une demi-vérité : la réservation est bien en ligne, mais pas le jour même. La réponse D inverse le canal : la réservation par téléphone n''est pas mentionnée.',
    '44444444-0021-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000020', 'En ligne, au minimum deux jours à l''avance pour tous les courts',                            false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000020', 'En ligne, jusqu''au jour même de la réservation',                                              false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000020', 'En ligne, 2 jours à l''avance pour les courts couverts, la veille pour les extérieurs',         true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000020', 'Par téléphone au moins une semaine à l''avance',                                                 false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 5 : Newsletter santé (Q21-Q22)
-- ──────────────────────────────────────────────────────────────────────────

-- Q21 : reformulation (douche avant de dormir)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000021', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reformulation',
    'Que recommande la newsletter à propos de la douche avant de dormir ?',
    'Le texte écrit : « Évitez les douches glacées juste avant de dormir : contre-intuitif, mais elles relancent l''activité du corps. Préférez une douche tiède, vingt minutes avant le coucher. ». La réponse C reformule ces deux indications. La réponse A est une reformulation faussée : il faut éviter les douches glacées (et non les recommander). La réponse B est une généralisation abusive : la douche n''est pas à proscrire en soi, c''est sa température qui compte. La réponse D inverse la causalité : la douche tiède est conseillée, pas la douche froide.',
    '44444444-0021-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000021', 'Prendre une douche froide juste avant de se coucher',                                         false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000021', 'Éviter toute douche dans l''heure qui précède le coucher',                                      false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000021', 'Prendre une douche tiède environ 20 minutes avant le coucher',                                  true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000021', 'Prendre une douche froide pour activer le corps avant le coucher',                                false, 4);

-- Q22 : repérage (rôle de l'alcool sur le sommeil)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000022', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_reperage_explicite',
    'Que dit la newsletter à propos de l''alcool et du sommeil ?',
    'Le texte indique : « L''alcool, souvent perçu comme un facilitateur d''endormissement, dégrade en réalité la qualité du sommeil profond. ». La réponse C reformule cette nuance. La réponse A reprend la perception courante (facilitateur) que la newsletter dément justement. La réponse B est une généralisation excessive : l''alcool est déconseillé sur la qualité, pas sur l''endormissement initial. La réponse D introduit une distinction (rouge/blanc) non mentionnée.',
    '44444444-0021-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000022', 'C''est un bon facilitateur d''endormissement',                                                   false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000022', 'Il empêche complètement de s''endormir',                                                          false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000022', 'Il facilite l''endormissement en apparence mais dégrade le sommeil profond',                       true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000022', 'Seul le vin rouge perturbe le sommeil, pas le vin blanc',                                          false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 6 : Info voyageurs SNCF (Q23-Q24)
-- ──────────────────────────────────────────────────────────────────────────

-- Q23 : détail (modification du train de 7h12)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000023', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_detail_specifique',
    'Que se passe-t-il avec le train de 7h12 pendant la période de travaux ?',
    'Le texte indique : « le train de 7h12 au départ de Toulouse partira exceptionnellement à 7h35, sans modification des arrêts ». Le train est donc décalé de 23 minutes, mais sans changement de parcours. La réponse C reformule cette double information. La réponse A est une reformulation faussée : le train n''est pas supprimé, il est décalé. La réponse B est une demi-vérité : le décalage est correct, mais les arrêts ne changent pas. La réponse D introduit un service routier qui ne concerne que le train de 19h40, pas celui de 7h12.',
    '44444444-0021-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000023', 'Il est supprimé et remplacé par un autocar',                                                    false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000023', 'Il part à 7h35 avec des arrêts modifiés',                                                         false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000023', 'Il part à 7h35 sans changement d''arrêts',                                                          true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000023', 'Il est remplacé par un service routier au départ d''Auch',                                         false, 4);

-- Q24 : inférence (situation des voyageurs ayant déjà acheté)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0021-0000-0000-000000000024', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B1', 'CE', 'ce_inference_intention',
    'Que doivent faire les voyageurs qui ont déjà acheté un billet pour le week-end ?',
    'Le texte dit : « Les billets déjà achetés restent valables, sans démarche supplémentaire de votre part. ». La réponse C reformule cette information. La réponse A est une reformulation faussée : aucune nouvelle réservation n''est requise. La réponse B introduit une démarche (demande de remboursement) que la SNCF ne demande pas. La réponse D est une généralisation erronée : aucun billet n''est invalidé, le service est simplement assuré par autocar.',
    '44444444-0021-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000024', 'Réserver à nouveau leur billet sur les autocars de remplacement',                              false, 1),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000024', 'Demander un remboursement avant de réutiliser leur billet',                                      false, 2),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000024', 'Conserver leur billet, qui reste valable sans démarche supplémentaire',                          true,  3),
    (gen_random_uuid(), '55555555-0021-0000-0000-000000000024', 'Considérer leur billet comme invalide et acheter un nouveau billet',                              false, 4);
