-- ============================================================================
-- V20 : Lot 6 TCF — B2 exclusif avec distracteurs durcis
-- ============================================================================
-- 📋 24 questions B2 :
--    - 12 questions image (article presse, tribune, lettre admin, rapport, blog)
--    - 12 questions texte (passages longs 250-350 mots)
--
-- 🎯 Toutes appliquent les nouvelles règles B2 :
--    - ≥2 distracteurs piégeux sur 3
--    - Réponse JAMAIS mot pour mot dans le texte
--    - Stratégies : littéral vs implicite, vrai partout sauf ici,
--                   demi-vérité, position adjacente
--
-- 📊 Répartition des compétences :
--    - ce_ton_auteur            : 4
--    - ce_inference_intention   : 4
--    - ce_idee_principale       : 4
--    - ce_reformulation         : 4
--    - ce_detail_specifique     : 4
--    - ce_reperage_explicite    : 4
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 📄 1. PASSAGES TEXTE (12) — Plage V20 : 44444444-0020-*
-- ----------------------------------------------------------------------------
-- Les passages sont numérotés à partir de 002 (le 001 est utilisé par
-- l'échantillon V20_ECHANTILLONS pour la pharmacie A2).

INSERT INTO passages (id, type, content, theme_id) VALUES

-- ────────── Passage 1 — Travail : sens du travail (Q1-Q2) ──────────
(
    '44444444-0020-0000-0000-000000000002', 'TEXTE',
    E'Pendant des décennies, le travail a structuré nos vies bien au-delà de sa fonction économique. Source d''identité, lieu de socialisation, support d''ambition : il occupait une place quasi sacrée dans la construction de soi. Cette centralité s''effrite. Les enquêtes récentes le confirment : si l''immense majorité des actifs continuent de juger le travail important, ils sont de plus en plus nombreux à refuser qu''il occupe toute la place. Conciliation, sens, équilibre : les mots ont changé, et avec eux les attentes.\n\n' ||
    E'Faut-il s''en alarmer ? Certains économistes le pensent, redoutant une baisse de productivité collective. D''autres, au contraire, y voient l''occasion d''interroger un modèle qui valorisait l''effort pour lui-même, parfois au prix de la santé mentale et de l''engagement réel. La vérité est sans doute plus subtile : ce n''est pas le travail qui est rejeté, mais l''idée qu''il doive sacrifier le reste. Les organisations qui sauront entendre ce déplacement, sans se contenter d''ajuster à la marge, sont celles qui retiendront les talents demain.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 2 — Environnement : voiture en ville (Q3-Q4) ──────────
(
    '44444444-0020-0000-0000-000000000003', 'TEXTE',
    E'L''image de la voiture individuelle, longtemps symbole d''émancipation et de modernité, se fissure dans les grandes villes françaises. Pistes cyclables élargies, zones limitées à 30 km/h, fermeture d''artères centrales : les municipalités enchaînent les arbitrages défavorables à l''automobile. Le discours public, lui aussi, se durcit : on parle désormais de « ville respirable » plus que de « ville fluide ».\n\n' ||
    E'Pour autant, l''affaire est moins consensuelle qu''il n''y paraît. Si les habitants du centre-ville plébiscitent ces évolutions, ceux qui vivent dans les couronnes périurbaines, mal desservies par les transports collectifs, en subissent les contrecoups : trajets allongés, stationnement plus rare, factures de carburant en hausse. Le risque d''une fracture territoriale se précise, opposant une France urbaine privilégiée à une France périphérique reléguée. Les élus locaux le savent et avancent désormais avec plus de précaution. Réussir la transition, ce n''est pas seulement adopter de bonnes mesures : c''est aussi garantir qu''elles ne creusent pas, sous prétexte d''écologie, de nouvelles formes d''injustice sociale.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 3 — Médias : information continue (Q5-Q6) ──────────
(
    '44444444-0020-0000-0000-000000000004', 'TEXTE',
    E'L''information continue, longtemps présentée comme un progrès démocratique, montre aujourd''hui des effets contradictoires. Sur le papier, l''accès permanent à l''actualité devait éclairer les citoyens. Dans les faits, plusieurs études récentes pointent un phénomène inverse : à force d''être exposés en continu à des nouvelles souvent anxiogènes et décontextualisées, certains lecteurs choisissent désormais de s''en détourner, ce que les chercheurs appellent la « lassitude informationnelle ».\n\n' ||
    E'Le constat n''invalide pas le journalisme d''actualité, encore moins le rôle essentiel des rédactions. Il interroge en revanche une mécanique éditoriale qui privilégie souvent la rapidité sur la mise en perspective, et qui peine à distinguer les nouvelles importantes des simples soubresauts. Certains médias commencent d''ailleurs à expérimenter d''autres formats : moins de bulletins, plus d''enquêtes, des sélections hebdomadaires des sujets vraiment marquants. L''enjeu n''est pas de produire moins, mais de produire autrement. Reste à savoir si cette inflexion suivra, dans la durée, ou cédera à la pression économique du flux continu.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 4 — Consommation : seconde main (Q7-Q8) ──────────
(
    '44444444-0020-0000-0000-000000000005', 'TEXTE',
    E'En quelques années, le marché de la seconde main est devenu un secteur économique à part entière. Vêtements, meubles, électronique : ce qui était autrefois cantonné aux brocantes du dimanche s''est professionnalisé, structuré, parfois même industrialisé. Les plateformes spécialisées affichent des croissances à deux chiffres, et les enseignes traditionnelles ouvrent désormais leurs propres rayons d''occasion.\n\n' ||
    E'On serait tenté d''y voir un progrès écologique sans réserve. Le tableau est pourtant plus nuancé. Si l''achat d''un vêtement déjà existant évite la production d''un neuf, l''explosion du volume échangé a créé son revers : multiplication des envois, surconsommation déguisée, retours non recyclés. Certains consommateurs achètent désormais plus, parce qu''ils achètent moins cher et avec moins de culpabilité. La seconde main, conçue à l''origine comme une alternative à la surproduction, en devient parfois un prolongement déguisé. Le geste vertueux ne suffit pas ; encore faut-il qu''il s''accompagne d''une réflexion sur le rythme et le volume de nos achats, tous canaux confondus.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 5 — Santé : sport sur ordonnance (Q9-Q10) ──────────
(
    '44444444-0020-0000-0000-000000000006', 'TEXTE',
    E'La prescription d''activité physique par les médecins s''installe progressivement dans le paysage sanitaire français. Désormais inscrite dans plusieurs parcours de soins (cancer, diabète, dépression légère), elle séduit autant les patients que les professionnels. Les bénéfices, longuement documentés par la littérature scientifique, ne font plus débat : amélioration de la fatigue, réduction des récidives, mieux-être psychique.\n\n' ||
    E'Le succès du dispositif ne doit pourtant pas masquer ses limites. D''abord, il dépend largement de la motivation du patient et de son accès géographique à des structures adaptées : un kiné, un club sportif partenaire, un éducateur formé. Or ces ressources restent inégalement réparties, et le reste à charge demeure dissuasif pour les ménages modestes. Ensuite, l''ordonnance ne dispense pas d''un accompagnement humain : sans suivi régulier, l''adhésion s''effrite en quelques semaines. Promouvoir le sport-santé comme outil thérapeutique est donc une excellente intention ; le réussir suppose de penser, en amont, les conditions concrètes de son déploiement à grande échelle. Sinon, ce qui devait être un progrès collectif risque de ne profiter qu''aux mieux dotés.',
    '22222222-0000-0000-0000-000000000002'
),

-- ────────── Passage 6 — Numérique : surveillance employeurs (Q11-Q12) ──────────
(
    '44444444-0020-0000-0000-000000000007', 'TEXTE',
    E'Avec l''essor du télétravail, une question discrète mais lourde de conséquences émerge : jusqu''où un employeur peut-il aller dans le suivi numérique de ses salariés ? Capture d''écran à intervalles réguliers, mesure des frappes au clavier, analyse des temps de connexion sur les outils internes : les logiciels de surveillance se sont multipliés, vendus comme des solutions « de pilotage » ou de « productivité ».\n\n' ||
    E'Sur le plan juridique, la situation française reste protectrice. La CNIL impose une information préalable des salariés et exige que toute surveillance soit proportionnée à la finalité poursuivie. Sur le terrain pourtant, les abus se multiplient. Plusieurs syndicats alertent sur des outils déployés sans concertation, parfois à l''insu des équipes. Au-delà de la stricte légalité, c''est la nature même du lien employeur-salarié qui se trouve interrogée. Surveiller à distance, c''est aussi reconnaître implicitement qu''on doute. Or la confiance, longuement érigée comme un pilier des organisations modernes, supporte mal d''être ainsi remise en cause. À vouloir tout mesurer, on risque surtout de mesurer la perte d''engagement.',
    '22222222-0000-0000-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;


-- ----------------------------------------------------------------------------
-- 🖼️ 2. MEDIAS (6 SVG) — Plage V20 : 33333333-0020-*
-- ----------------------------------------------------------------------------
-- 6 SVG, 2 questions chacun (12 questions image au total)
-- Numérotation à partir de 003 (les 001 et 002 sont utilisés par V20_ECHANTILLONS)

INSERT INTO medias (id, type, url, alt_text, inline_svg) VALUES

-- ────────── Media 1 : Article de presse — démissions silencieuses ──────────
(
    '33333333-0020-0000-0000-000000000003',
    'IMAGE',
    NULL,
    'Article de presse en ligne intitulé "Démissions silencieuses : un phénomène mal nommé qui en dit long", traitant du désengagement progressif des salariés au travail avec une analyse critique du terme lui-même.',
    '<svg width="100%" viewBox="0 0 680 760" role="img" xmlns="http://www.w3.org/2000/svg"><title>Article de presse sur les démissions silencieuses</title><desc>Capture d''écran d''un article de presse analysant le phénomène des démissions silencieuses.</desc><rect x="0" y="0" width="680" height="760" fill="#F0F2F5"/><rect x="20" y="20" width="640" height="720" rx="6" fill="#FFFFFF" stroke="#D5D5D5" stroke-width="1"/><rect x="20" y="20" width="640" height="60" fill="#0F1839"/><text x="40" y="48" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#FFFFFF">L''Observateur</text><text x="40" y="66" font-family="Arial, sans-serif" font-size="10" fill="#A8B0C5">Économie · Travail</text><text x="640" y="56" text-anchor="end" font-family="Arial, sans-serif" font-size="11" fill="#FFFFFF" opacity="0.8">7 minutes de lecture</text><g transform="translate(40, 100)"><rect x="0" y="0" width="90" height="22" rx="2" fill="#E1372F"/><text x="45" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#FFFFFF">ANALYSE</text></g><text x="40" y="158" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#0F1839">Démissions silencieuses :</text><text x="40" y="186" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#0F1839">un phénomène mal nommé qui en dit long</text><line x1="40" y1="208" x2="120" y2="208" stroke="#E1372F" stroke-width="3"/><text x="40" y="234" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">Par Lucie Bertrand · Publié hier à 18h32</text><text x="40" y="278" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#0F1839">Importée des États-Unis, l''expression « démission silencieuse » désigne</text><text x="40" y="298" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#0F1839">ces salariés qui restent en poste mais se contentent strictement de leurs</text><text x="40" y="318" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#0F1839">missions, sans plus s''impliquer au-delà. Le terme fait recette ; il mérite</text><text x="40" y="338" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#0F1839">pourtant d''être interrogé.</text><text x="40" y="378" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">D''abord, parce qu''il n''y a là rien de bien neuf. Faire ce pour quoi on est</text><text x="40" y="396" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">payé, et seulement cela, a longtemps été la règle implicite des relations</text><text x="40" y="414" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">de travail. Ce qui change, c''est moins le comportement des salariés que</text><text x="40" y="432" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">l''attente patronale d''un engagement débordant les contrats.</text><text x="40" y="466" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Ensuite, parce que l''expression elle-même est trompeuse : on ne</text><text x="40" y="484" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">démissionne pas en restant. Ce que les enquêtes décrivent ressemble</text><text x="40" y="502" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">davantage à une forme de désengagement défensif, souvent en réaction</text><text x="40" y="520" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">à des conditions perçues comme injustes : management vertical, salaires</text><text x="40" y="538" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">stagnants, demandes opérationnelles croissantes.</text><text x="40" y="572" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Plutôt que de stigmatiser ces salariés en quête de juste contrepartie,</text><text x="40" y="590" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">les organisations gagneraient à entendre ce qu''ils disent par leur</text><text x="40" y="608" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">retrait : non pas un refus du travail, mais le refus d''un déséquilibre</text><text x="40" y="626" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">durable entre ce qui est donné et ce qui est reconnu.</text><rect x="40" y="660" width="600" height="50" rx="4" fill="#F4F8FB" stroke="#D5DDE3" stroke-width="1"/><text x="56" y="680" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#5C6573">DANS LA MÊME RUBRIQUE</text><text x="56" y="700" font-family="Arial, sans-serif" font-size="12" font-weight="600" fill="#107ACA">→ La grande démission a-t-elle vraiment eu lieu en France ?</text></svg>'
),

-- ────────── Media 2 : Tribune d'opinion — IA et créativité ──────────
(
    '33333333-0020-0000-0000-000000000004',
    'IMAGE',
    NULL,
    'Tribune d''opinion en ligne signée par une artiste, intitulée "L''intelligence artificielle ne remplacera pas la créativité, mais elle changera ce qu''on appelle ainsi", proposant une réflexion nuancée sur les outils génératifs.',
    '<svg width="100%" viewBox="0 0 680 760" role="img" xmlns="http://www.w3.org/2000/svg"><title>Tribune d''opinion sur l''IA et la créativité</title><desc>Capture d''écran d''une tribune signée par une artiste sur l''impact de l''IA générative.</desc><rect x="0" y="0" width="680" height="760" fill="#F8F6F0"/><rect x="20" y="20" width="640" height="720" rx="6" fill="#FFFEF9" stroke="#D5D5C8" stroke-width="1"/><rect x="20" y="20" width="640" height="50" fill="#1E3A8C"/><text x="40" y="50" font-family="Georgia, serif" font-size="20" font-weight="700" font-style="italic" fill="#FFFFFF">La Tribune Libre</text><text x="640" y="48" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#FFFFFF" opacity="0.8">Opinions · Idées</text><g transform="translate(40, 90)"><rect x="0" y="0" width="100" height="22" rx="2" fill="#1E3A8C"/><text x="50" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#FFFFFF">TRIBUNE</text></g><text x="40" y="148" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#0F1839">« L''intelligence artificielle ne</text><text x="40" y="172" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#0F1839">remplacera pas la créativité, mais</text><text x="40" y="196" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#0F1839">elle changera ce qu''on appelle ainsi »</text><line x1="40" y1="216" x2="180" y2="216" stroke="#1E3A8C" stroke-width="2"/><text x="40" y="244" font-family="Arial, sans-serif" font-size="12" font-style="italic" fill="#5C6573">Par Hélène Marchand, artiste plasticienne</text><text x="40" y="282" font-family="Georgia, serif" font-size="13" fill="#0F1839">Les outils génératifs nous mettent face à un trouble singulier. Avec eux,</text><text x="40" y="300" font-family="Georgia, serif" font-size="13" fill="#0F1839">la production d''images, de musiques, de textes devient un geste presque</text><text x="40" y="318" font-family="Georgia, serif" font-size="13" fill="#0F1839">trivial. Ce qui demandait une vie d''apprentissage tient désormais dans</text><text x="40" y="336" font-family="Georgia, serif" font-size="13" fill="#0F1839">quelques lignes de texte. Pour beaucoup d''artistes, ce constat brutal</text><text x="40" y="354" font-family="Georgia, serif" font-size="13" fill="#0F1839">est vécu comme une menace existentielle. Je ne le crois pas.</text><text x="40" y="388" font-family="Georgia, serif" font-size="13" fill="#0F1839">Ce que ces outils déplacent, ce n''est pas la capacité à créer, mais ce</text><text x="40" y="406" font-family="Georgia, serif" font-size="13" fill="#0F1839">qu''on choisit d''appeler de la création. Pendant longtemps, le savoir-</text><text x="40" y="424" font-family="Georgia, serif" font-size="13" fill="#0F1839">faire technique a fait office de critère. Avec l''IA, la prouesse technique</text><text x="40" y="442" font-family="Georgia, serif" font-size="13" fill="#0F1839">se banalise. Reste l''intention : le pourquoi, le sens, le regard.</text><text x="40" y="476" font-family="Georgia, serif" font-size="13" fill="#0F1839">Loin de tuer l''art, l''IA pourrait paradoxalement le purifier en le forçant</text><text x="40" y="494" font-family="Georgia, serif" font-size="13" fill="#0F1839">à se redéfinir autour de ce qu''aucune machine ne peut imiter : l''intuition</text><text x="40" y="512" font-family="Georgia, serif" font-size="13" fill="#0F1839">d''un vécu, la décision de montrer ceci plutôt que cela, la singularité</text><text x="40" y="530" font-family="Georgia, serif" font-size="13" fill="#0F1839">d''un parcours.</text><text x="40" y="564" font-family="Georgia, serif" font-size="13" fill="#0F1839">La vraie question n''est donc pas « l''IA va-t-elle remplacer les artistes »,</text><text x="40" y="582" font-family="Georgia, serif" font-size="13" fill="#0F1839">mais « que valait notre définition de l''art si une machine peut désormais</text><text x="40" y="600" font-family="Georgia, serif" font-size="13" fill="#0F1839">en produire les apparences ? » Voilà, à mes yeux, le seul débat sérieux.</text><line x1="40" y1="640" x2="640" y2="640" stroke="#D5D5C8" stroke-width="0.5"/><text x="40" y="670" font-family="Arial, sans-serif" font-size="11" font-style="italic" fill="#5C6573">Hélène Marchand expose actuellement à la galerie du Marais.</text></svg>'
),

-- ────────── Media 3 : Lettre administrative — révision de loyer ──────────
(
    '33333333-0020-0000-0000-000000000005',
    'IMAGE',
    NULL,
    'Lettre administrative d''un bailleur notifiant une révision annuelle de loyer en application de l''indice de référence, avec mention des voies de contestation et d''un complément exceptionnel pour travaux.',
    '<svg width="100%" viewBox="0 0 680 880" role="img" xmlns="http://www.w3.org/2000/svg"><title>Lettre de révision de loyer</title><desc>Lettre administrative d''un bailleur notifiant à un locataire la révision annuelle de loyer et un complément pour travaux.</desc><rect x="0" y="0" width="680" height="880" fill="#F5F5F5"/><rect x="40" y="40" width="600" height="800" fill="#FFFFFF" stroke="#D5D5D5" stroke-width="1"/><g transform="translate(60, 60)"><text x="0" y="0" font-family="Arial, sans-serif" font-size="13" font-weight="700" fill="#0F1839">SCI Les Tilleuls</text><text x="0" y="18" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">14 rue Lafayette, 75009 Paris</text><text x="0" y="34" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">contact@les-tilleuls.fr</text></g><g transform="translate(360, 60)"><text x="0" y="0" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Mme Sarah LEROUX</text><text x="0" y="16" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">22 rue des Acacias</text><text x="0" y="32" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">75011 Paris</text></g><text x="60" y="180" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">Paris, le 14 mars</text><text x="60" y="215" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#0F1839">Objet : Révision annuelle du loyer — bail signé le 1er avril 2022</text><text x="60" y="231" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">Lettre recommandée avec accusé de réception</text><text x="60" y="278" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Madame Leroux,</text><text x="60" y="312" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Conformément aux dispositions de votre bail et à la loi du 6 juillet 1989,</text><text x="60" y="330" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">nous procédons à la révision annuelle de votre loyer, sur la base de</text><text x="60" y="348" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">l''indice de référence des loyers (IRL) publié par l''INSEE.</text><rect x="60" y="370" width="540" height="100" rx="4" fill="#F4F8FB" stroke="#D5DDE3" stroke-width="1"/><text x="76" y="392" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#5C6573">DÉTAIL DE LA RÉVISION</text><text x="76" y="416" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Ancien loyer hors charges :</text><text x="540" y="416" text-anchor="end" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">820,00 €</text><text x="76" y="436" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Variation IRL appliquée (+3,5%) :</text><text x="540" y="436" text-anchor="end" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">+28,70 €</text><text x="76" y="458" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#0F1839">Nouveau loyer hors charges :</text><text x="540" y="458" text-anchor="end" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#1E3A8C">848,70 €</text><text x="60" y="498" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Cette révision prendra effet à compter du <tspan font-weight="700">1er avril prochain</tspan>.</text><text x="60" y="532" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Par ailleurs, nous souhaitons vous informer qu''un complément temporaire de</text><text x="60" y="550" font-family="Arial, sans-serif" font-size="12" fill="#0F1839"><tspan font-weight="700">15 € par mois pendant 12 mois</tspan> sera appliqué pour financer la réfection</text><text x="60" y="568" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">de la toiture de l''immeuble. Ce complément, prévu par l''article 17-1 de</text><text x="60" y="586" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">la loi, cesse automatiquement à l''issue de cette période.</text><rect x="60" y="608" width="540" height="58" rx="4" fill="#FDECEB" stroke="#E1372F" stroke-width="1"/><text x="76" y="628" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#E1372F">VOIE DE CONTESTATION</text><text x="76" y="646" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Si vous estimez cette révision irrégulière, vous disposez d''un délai de</text><text x="76" y="660" font-family="Arial, sans-serif" font-size="11" fill="#0F1839"><tspan font-weight="700">deux mois</tspan> pour saisir la commission départementale de conciliation.</text><text x="60" y="700" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Nous restons à votre disposition pour toute précision.</text><text x="60" y="730" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Cordialement,</text><text x="60" y="770" font-family="Georgia, serif" font-size="14" font-style="italic" fill="#1E3A8C">Jean-Marc Vidal</text><text x="60" y="788" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">Gérant — SCI Les Tilleuls</text></svg>'
),

-- ────────── Media 4 : Extrait de rapport — bien-être en entreprise ──────────
(
    '33333333-0020-0000-0000-000000000006',
    'IMAGE',
    NULL,
    'Extrait d''un rapport d''observatoire sur le bien-être au travail, présentant des chiffres et conclusions sur le décalage entre les actions des entreprises et les attentes réelles des salariés.',
    '<svg width="100%" viewBox="0 0 680 800" role="img" xmlns="http://www.w3.org/2000/svg"><title>Extrait de rapport sur le bien-être au travail</title><desc>Capture d''un extrait de rapport d''observatoire avec chiffres clés et synthèse.</desc><rect x="0" y="0" width="680" height="800" fill="#F2F5F8"/><rect x="20" y="20" width="640" height="760" fill="#FFFFFF" stroke="#C8D0D8" stroke-width="1"/><rect x="20" y="20" width="640" height="80" fill="#15296B"/><text x="40" y="50" font-family="Georgia, serif" font-size="14" fill="#A8B0C5">OBSERVATOIRE DU TRAVAIL — ÉDITION 2026</text><text x="40" y="80" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#FFFFFF">Bien-être au travail : ce que disent vraiment les salariés</text><g transform="translate(40, 130)"><rect x="0" y="0" width="100" height="22" rx="2" fill="#168F5B"/><text x="50" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#FFFFFF">SYNTHÈSE</text></g><text x="40" y="190" font-family="Georgia, serif" font-size="18" font-weight="700" fill="#0F1839">Un décalage croissant entre les actions menées</text><text x="40" y="214" font-family="Georgia, serif" font-size="18" font-weight="700" fill="#0F1839">et les attentes réelles des collaborateurs</text><line x1="40" y1="232" x2="160" y2="232" stroke="#168F5B" stroke-width="3"/><g transform="translate(40, 270)"><rect x="0" y="0" width="285" height="100" rx="6" fill="#E8F5EE" stroke="#168F5B" stroke-width="0.5"/><text x="20" y="32" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#168F5B">CHIFFRE CLÉ</text><text x="20" y="62" font-family="Georgia, serif" font-size="28" font-weight="700" fill="#168F5B">73%</text><text x="20" y="85" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">des salariés jugent les baby-foot</text><text x="20" y="100" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">et tables de ping-pong inutiles</text></g><g transform="translate(355, 270)"><rect x="0" y="0" width="285" height="100" rx="6" fill="#FDECEB" stroke="#E1372F" stroke-width="0.5"/><text x="20" y="32" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#E1372F">CHIFFRE CLÉ</text><text x="20" y="62" font-family="Georgia, serif" font-size="28" font-weight="700" fill="#E1372F">2 sur 3</text><text x="20" y="85" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">attendent une revalorisation</text><text x="20" y="100" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">salariale avant tout</text></g><text x="40" y="412" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Les conclusions de cette septième édition de l''observatoire sont sans</text><text x="40" y="430" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">appel : les politiques de bien-être au travail, telles qu''elles sont</text><text x="40" y="448" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">pensées par la plupart des grandes entreprises, manquent largement leur</text><text x="40" y="466" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">cible. Les dispositifs les plus visibles — espaces de détente, événements</text><text x="40" y="484" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">internes, séminaires « bonheur » — peinent à convaincre.</text><text x="40" y="518" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">À l''inverse, les attentes des salariés se cristallisent autour de trois</text><text x="40" y="536" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">axes fondamentaux : la rémunération, le respect du temps de vie</text><text x="40" y="554" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">personnelle, et la reconnaissance par le management direct du travail</text><text x="40" y="572" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">accompli.</text><text x="40" y="606" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Le rapport recommande aux directions de renoncer aux dispositifs</text><text x="40" y="624" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">cosmétiques et de réinvestir prioritairement dans ce qui structure</text><text x="40" y="642" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">durablement la qualité de vie au travail.</text><rect x="40" y="680" width="600" height="60" rx="4" fill="#F4F8FB" stroke="#D5DDE3" stroke-width="1"/><text x="56" y="704" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#5C6573">MÉTHODOLOGIE</text><text x="56" y="724" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">Enquête menée auprès de 4 200 salariés du secteur privé, de janvier à</text><text x="56" y="738" font-family="Arial, sans-serif" font-size="11" fill="#0F1839">novembre. Échantillon représentatif redressé selon l''âge, le secteur et la taille.</text></svg>'
),

-- ────────── Media 5 : Capture de blog éditorial — slow tourisme ──────────
(
    '33333333-0020-0000-0000-000000000007',
    'IMAGE',
    NULL,
    'Article de blog éditorial intitulé "Le slow tourisme, mode passagère ou vraie transition ?", interrogeant la sincérité d''une tendance touristique qui se revendique éthique.',
    '<svg width="100%" viewBox="0 0 680 760" role="img" xmlns="http://www.w3.org/2000/svg"><title>Article de blog sur le slow tourisme</title><desc>Capture d''un blog éditorial sur la tendance du slow tourisme.</desc><rect x="0" y="0" width="680" height="760" fill="#FBF8F2"/><rect x="20" y="20" width="640" height="720" rx="8" fill="#FFFFFF" stroke="#E8E0CC" stroke-width="1"/><rect x="20" y="20" width="640" height="50" fill="#168F5B"/><text x="40" y="50" font-family="Georgia, serif" font-size="18" font-weight="700" fill="#FFFFFF">Voyages &amp; Réflexions</text><text x="640" y="48" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#FFFFFF" opacity="0.8">Le blog · 3 commentaires</text><g transform="translate(40, 90)"><rect x="0" y="0" width="120" height="22" rx="11" fill="#E8F5EE"/><text x="60" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#168F5B">Tendances</text></g><text x="40" y="148" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#0F1839">Le slow tourisme :</text><text x="40" y="178" font-family="Georgia, serif" font-size="22" font-weight="700" fill="#0F1839">mode passagère ou vraie transition ?</text><line x1="40" y1="200" x2="120" y2="200" stroke="#168F5B" stroke-width="3"/><text x="40" y="228" font-family="Arial, sans-serif" font-size="12" fill="#5C6573">Sophie Aubry · Vendredi · Lecture : 6 min</text><text x="40" y="276" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Voyager moins, mais mieux. Privilégier le train, séjourner plus longtemps,</text><text x="40" y="294" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">consommer local. Le « slow tourisme » s''affiche désormais partout :</text><text x="40" y="312" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">brochures d''offices de tourisme, guides de voyage, plateformes de</text><text x="40" y="330" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">réservation. Le succès du label est incontestable. Sa portée réelle, en</text><text x="40" y="348" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">revanche, mérite qu''on s''y attarde.</text><text x="40" y="382" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Sur le papier, l''engagement écologique est sérieux. Dans les faits,</text><text x="40" y="400" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">plusieurs études récentes nuancent le tableau : pour beaucoup de voyageurs,</text><text x="40" y="418" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">le slow tourisme s''ajoute à des voyages longue distance, sans s''y</text><text x="40" y="436" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">substituer. On part en train à 200 km de chez soi pour un week-end</text><text x="40" y="454" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">« responsable », puis on prend l''avion six mois plus tard pour les vraies</text><text x="40" y="472" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">vacances. Le bilan carbone, lui, ne distingue pas la bonne conscience.</text><text x="40" y="506" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Faut-il pour autant disqualifier la démarche ? Certainement pas. Mais il</text><text x="40" y="524" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">faut sortir d''une lecture cosmétique. Un slow tourisme sincère suppose un</text><text x="40" y="542" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">arbitrage : moins de déplacements lointains, pas l''ajout d''escapades</text><text x="40" y="560" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">vertueuses entre deux long-courriers.</text><text x="40" y="594" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">La transition écologique du tourisme passera par cette honnêteté. Sinon,</text><text x="40" y="612" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">la formule restera un argument marketing rassurant, et rien de plus.</text><line x1="40" y1="650" x2="640" y2="650" stroke="#E8E0CC" stroke-width="0.5"/><g transform="translate(40, 680)"><rect x="0" y="0" width="100" height="20" rx="2" fill="#F5F0E0"/><text x="50" y="14" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#A36E0A">slow tourisme</text></g><g transform="translate(150, 680)"><rect x="0" y="0" width="80" height="20" rx="2" fill="#F5F0E0"/><text x="40" y="14" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#A36E0A">écologie</text></g></svg>'
),

-- ────────── Media 6 : Page web — formation continue ──────────
(
    '33333333-0020-0000-0000-000000000008',
    'IMAGE',
    NULL,
    'Page web d''un organisme de formation continue présentant une formation diplômante en management, avec conditions d''accès strictes (dont expérience professionnelle minimum), tarif et modalités de financement.',
    '<svg width="100%" viewBox="0 0 680 740" role="img" xmlns="http://www.w3.org/2000/svg"><title>Page web d''une formation continue en management</title><desc>Capture du site d''un organisme de formation : programme diplômant, conditions d''accès, prix, financement.</desc><rect x="0" y="0" width="680" height="740" fill="#F4F7FB"/><rect x="20" y="20" width="640" height="700" rx="8" fill="#FFFFFF" stroke="#D5DDE3" stroke-width="1"/><rect x="20" y="20" width="640" height="60" rx="8" fill="#1E3A8C"/><text x="40" y="58" font-family="Georgia, serif" font-size="20" font-weight="700" fill="#FFFFFF">FormaPro</text><text x="115" y="58" font-family="Arial, sans-serif" font-size="11" fill="#A8B0C5">— École de management</text><text x="600" y="50" text-anchor="end" font-family="Arial, sans-serif" font-size="11" fill="#FFFFFF">Catalogue 2026</text><text x="600" y="65" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#A8B0C5">Mis à jour</text><g transform="translate(40, 100)"><rect x="0" y="0" width="80" height="22" rx="11" fill="#168F5B"/><text x="40" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#FFFFFF">Diplômant</text><rect x="92" y="0" width="100" height="22" rx="11" fill="#FEF5DD"/><text x="142" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#A36E0A">Bac+5 reconnu</text><rect x="204" y="0" width="100" height="22" rx="11" fill="#E8ECF8"/><text x="254" y="15" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#1E3A8C">Niveau 7 RNCP</text></g><text x="40" y="170" font-family="Arial, sans-serif" font-size="22" font-weight="700" fill="#0F1839">Master Management des Organisations</text><text x="40" y="195" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">Formation continue pour cadres en activité — Rentrée septembre</text><text x="40" y="246" font-family="Arial, sans-serif" font-size="32" font-weight="700" fill="#1E3A8C">9 800 €</text><text x="180" y="246" font-family="Arial, sans-serif" font-size="14" fill="#5C6573">au total</text><text x="180" y="264" font-family="Arial, sans-serif" font-size="12" font-weight="600" fill="#168F5B">éligible CPF + financement employeur possible</text><line x1="40" y1="284" x2="640" y2="284" stroke="#E0E2E7" stroke-width="1"/><text x="40" y="316" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#0F1839">Conditions d''accès</text><g transform="translate(40, 340)"><circle cx="6" cy="6" r="3" fill="#1E3A8C"/><text x="20" y="10" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Diplôme de niveau Bac+3 minimum (ou équivalent VAE)</text></g><g transform="translate(40, 370)"><circle cx="6" cy="6" r="3" fill="#1E3A8C"/><text x="20" y="10" font-family="Arial, sans-serif" font-size="13" fill="#0F1839"><tspan font-weight="700">Au moins 5 ans d''expérience professionnelle</tspan> dont 2 en encadrement</text></g><g transform="translate(40, 400)"><circle cx="6" cy="6" r="3" fill="#1E3A8C"/><text x="20" y="10" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Sélection sur dossier <tspan font-weight="700">+ entretien individuel obligatoire</tspan></text></g><g transform="translate(40, 430)"><circle cx="6" cy="6" r="3" fill="#1E3A8C"/><text x="20" y="10" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">Lettre de motivation de l''employeur (si financement entreprise)</text></g><line x1="40" y1="470" x2="640" y2="470" stroke="#E0E2E7" stroke-width="1"/><text x="40" y="502" font-family="Arial, sans-serif" font-size="15" font-weight="700" fill="#0F1839">Modalités</text><text x="40" y="528" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Rythme : <tspan font-weight="700">2 jours par mois sur 18 mois</tspan> (jeudi/vendredi)</text><text x="40" y="548" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Hybride : présentiel à Paris + sessions à distance</text><text x="40" y="568" font-family="Arial, sans-serif" font-size="13" fill="#0F1839">• Promotion limitée à 24 participants pour favoriser les échanges</text><rect x="40" y="600" width="600" height="80" rx="6" fill="#FDECEB" stroke="#E1372F" stroke-width="1"/><text x="56" y="624" font-family="Arial, sans-serif" font-size="12" font-weight="700" fill="#E1372F">⚠ INSCRIPTIONS</text><text x="56" y="646" font-family="Arial, sans-serif" font-size="12" fill="#0F1839">Date limite de dépôt des dossiers : <tspan font-weight="700">15 juin</tspan>. Résultats fin juillet.</text><text x="56" y="664" font-family="Arial, sans-serif" font-size="11" fill="#5C6573">Aucun dossier ne sera accepté après cette date, y compris pour les financements CPF.</text></svg>'
)
ON CONFLICT (id) DO NOTHING;


-- ============================================================================
-- ❓ 3. QUESTIONS IMAGE (12) — CE B2 image
-- ============================================================================
-- Plage UUID : 55555555-0020-0000-... (à partir de 010 car 001-003 = échantillons)

-- ──────────────────────────────────────────────────────────────────────────
-- 📰 Media 1 : Démissions silencieuses (Q1-Q2)
-- ──────────────────────────────────────────────────────────────────────────

-- Q1 : ton de l'auteur
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000010', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Quelle position l''auteur défend-il à propos de l''expression « démission silencieuse » ?',
    'L''auteur écrit explicitement que l''expression « mérite d''être interrogée » et qu''elle est « trompeuse : on ne démissionne pas en restant ». Sa critique porte sur le terme lui-même, qu''elle juge mal nommé, et non sur le phénomène qu''il décrit (qu''elle reconnaît comme réel). La réponse B est donc correcte. La réponse A est une demi-vérité : l''auteur reconnaît le phénomène mais pas comme une menace inquiétante. La réponse C adopte une position adjacente mais inverse à l''auteur (qui défend les salariés, pas l''entreprise). La réponse D présente un raccourci littéral : l''auteur ne dit pas que le terme vient des États-Unis pour le critiquer (c''est une simple mention factuelle, pas un argument).',
    '33333333-0020-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000010', 'L''expression désigne un phénomène inquiétant qui doit alerter les entreprises',                false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000010', 'L''expression est mal choisie et masque la véritable nature du phénomène',                    true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000010', 'L''expression illustre une dérive de comportement qu''il faut corriger chez les salariés',    false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000010', 'L''expression doit être rejetée parce qu''elle vient de l''étranger',                          false, 4);

-- Q2 : reformulation des causes
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000011', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Selon l''auteure, comment expliquer le comportement décrit par cette expression ?',
    'L''auteure parle d''un « désengagement défensif » survenant « en réaction à des conditions perçues comme injustes : management vertical, salaires stagnants, demandes opérationnelles croissantes ». Elle ajoute que ces salariés expriment « non pas un refus du travail, mais le refus d''un déséquilibre durable entre ce qui est donné et ce qui est reconnu ». La réponse B reformule fidèlement cette idée. La réponse A est une demi-vérité : la rémunération est citée, mais pas seule. La réponse C inverse le propos : l''auteure ne juge pas les salariés paresseux. La réponse D adopte une position adjacente mais trop générale : l''auteure ne parle pas d''un changement de génération, mais d''un déséquilibre durable.',
    '33333333-0020-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000011', 'Par une demande de meilleure rémunération, principalement',                                                false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000011', 'Par une réaction à un déséquilibre entre engagement attendu et reconnaissance reçue',                       true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000011', 'Par une nouvelle paresse devenue acceptable socialement',                                                   false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000011', 'Par un changement générationnel : les jeunes n''ont plus la même conception du travail',                    false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🎨 Media 2 : Tribune IA et créativité (Q3-Q4)
-- ──────────────────────────────────────────────────────────────────────────

-- Q3 : thèse principale (idée principale)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000012', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quelle est la thèse principale de cette tribune ?',
    'L''auteure conclut : « la vraie question n''est donc pas l''IA va-t-elle remplacer les artistes, mais que valait notre définition de l''art si une machine peut désormais en produire les apparences ». Elle déplace le débat : ce n''est pas l''IA le sujet, mais notre façon de définir l''art. La réponse C reformule cette inversion. La réponse A est une position adjacente mais trop tranchée : l''auteure ne dit pas que l''IA est inoffensive, elle dit qu''elle pose une autre question. La réponse B est une demi-vérité : l''auteure cite bien la « purification » mais comme conséquence, pas comme thèse principale. La réponse D adopte une position contraire : l''auteure refuse explicitement de présenter l''IA comme une menace existentielle.',
    '33333333-0020-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000012', 'L''IA ne menace pas réellement les artistes, qui peuvent rester sereins',                                       false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000012', 'L''IA va purifier l''art en débarrassant les artistes du savoir-faire technique',                              false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000012', 'L''IA oblige à repenser ce que nous appelions création, plus qu''elle ne menace les créateurs',               true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000012', 'L''IA constitue une menace existentielle qu''il faut prendre au sérieux',                                      false, 4);

-- Q4 : inférence sur la définition de l'art
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000013', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
    'Que reste-t-il à l''art selon l''auteure, une fois l''IA généralisée ?',
    'L''auteure écrit : « Avec l''IA, la prouesse technique se banalise. Reste l''intention : le pourquoi, le sens, le regard », et plus loin « l''intuition d''un vécu, la décision de montrer ceci plutôt que cela, la singularité d''un parcours ». La réponse B reformule cet ensemble : intention, choix, singularité — ce qu''aucune machine ne peut reproduire. La réponse A reprend littéralement « le savoir-faire technique » alors que l''auteure dit exactement l''inverse : c''est ce qui se banalise et n''est plus distinctif. La réponse C est une demi-vérité : la créativité n''est pas refusée à l''IA, mais redéfinie. La réponse D contredit l''auteure qui ne lie pas la valeur à la rareté du résultat mais à la singularité de la démarche.',
    '33333333-0020-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000013', 'Le savoir-faire technique, longtemps son critère principal',                                       false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000013', 'L''intention, le regard du créateur et la singularité de son parcours',                            true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000013', 'L''originalité absolue, qu''aucune IA ne peut produire',                                            false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000013', 'La rareté du résultat, devenue le seul critère pertinent',                                         false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📋 Media 3 : Lettre révision de loyer (Q5-Q6)
-- ──────────────────────────────────────────────────────────────────────────

-- Q5 : repérage explicite (nouveau loyer mensuel total)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000014', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_detail_specifique',
    'Combien madame Leroux devra-t-elle payer chaque mois à compter du 1er avril ?',
    'Il faut additionner deux éléments distincts présentés dans la lettre : le nouveau loyer hors charges après révision IRL (848,70 €) et le complément temporaire pour travaux (15 € par mois pendant 12 mois). Total mensuel : 848,70 + 15 = 863,70 €. La réponse A donne le loyer après révision IRL mais oublie le complément travaux (demi-vérité). La réponse C ajoute le complément à l''ancien loyer, ce qui ignore la révision IRL (reformulation faussée). La réponse D présente la variation seule (28,70 €), qui est la hausse, pas le loyer.',
    '33333333-0020-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000014', '848,70 €',  false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000014', '863,70 €',  true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000014', '835,00 €',  false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000014', '28,70 €',   false, 4);

-- Q6 : inférence sur les recours
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000015', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
    'Que peut faire madame Leroux si elle conteste cette révision ?',
    'L''encadré « VOIE DE CONTESTATION » précise qu''elle peut « saisir la commission départementale de conciliation » dans un délai de « deux mois ». Le recours est donc administratif et limité dans le temps. La réponse A est correcte. La réponse B adopte une position adjacente plausible mais erronée : aucune mention d''un tribunal n''est faite, et le texte oriente vers une commission, pas un juge. La réponse C est trompeuse : « refuser de payer » n''est jamais évoqué comme voie légale (et c''est juridiquement risqué). La réponse D inverse la situation : le complément travaux n''est pas une renégociation à demander, c''est une décision unilatérale du bailleur encadrée par la loi.',
    '33333333-0020-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000015', 'Saisir une commission de conciliation dans un délai de deux mois',                              true,  1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000015', 'Engager directement une procédure devant le tribunal compétent',                                false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000015', 'Refuser de payer le complément tant que la procédure est en cours',                              false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000015', 'Demander une renégociation du complément travaux avec le bailleur',                              false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📊 Media 4 : Rapport bien-être au travail (Q7-Q8)
-- ──────────────────────────────────────────────────────────────────────────

-- Q7 : idée principale du rapport
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000016', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quelle conclusion centrale ce rapport met-il en évidence ?',
    'Le rapport titre « Un décalage croissant entre les actions menées et les attentes réelles des collaborateurs ». Il développe que les dispositifs visibles (baby-foot, événements, séminaires « bonheur ») sont jugés inutiles par 73 % des salariés, et que ces derniers attendent en priorité une revalorisation salariale, le respect du temps de vie personnelle et une reconnaissance managériale. La réponse C reformule cette thèse. La réponse A est une demi-vérité : la critique des dispositifs visibles existe, mais le rapport ne dit pas qu''ils sont nuisibles, juste qu''ils manquent leur cible. La réponse B est une position adjacente mais trop tranchée : le rapport recommande de réinvestir, pas de supprimer toute politique. La réponse D inverse le message : le rapport critique l''inadéquation des entreprises, pas le désintérêt des salariés.',
    '33333333-0020-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000016', 'Les dispositifs de bien-être actuels sont nuisibles à la productivité',                                       false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000016', 'Les entreprises devraient supprimer toute politique de bien-être au travail',                                  false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000016', 'Les actions menées ne répondent pas aux attentes prioritaires des salariés',                                   true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000016', 'Les salariés se désintéressent globalement des sujets de qualité de vie',                                      false, 4);

-- Q8 : reformulation des attentes des salariés
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000017', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Que recherchent prioritairement les salariés interrogés ?',
    'Le rapport identifie « trois axes fondamentaux : la rémunération, le respect du temps de vie personnelle, et la reconnaissance par le management direct du travail accompli ». La réponse B reformule cet ensemble. La réponse A est une demi-vérité : la rémunération est citée mais isolée des deux autres axes. La réponse C est une position adjacente mais erronée : le rapport critique les dispositifs cosmétiques, pas les conditions de travail au sens des équipements. La réponse D adopte une formulation trop large : « plus de flexibilité » n''est pas mentionné comme tel dans les chiffres clés.',
    '33333333-0020-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000017', 'Une augmentation salariale, principalement',                                                                false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000017', 'Une meilleure rémunération, le respect de leur vie personnelle et la reconnaissance managériale',           true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000017', 'De meilleures conditions matérielles de travail (bureaux, équipements)',                                    false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000017', 'Plus de flexibilité dans l''organisation de leur temps',                                                     false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🌿 Media 5 : Blog slow tourisme (Q9-Q10)
-- ──────────────────────────────────────────────────────────────────────────

-- Q9 : ton de l'auteure
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000018', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Quelle attitude l''auteure adopte-t-elle face au slow tourisme ?',
    'L''auteure reconnaît un « engagement écologique sérieux » sur le papier mais pointe que dans les faits, le slow tourisme « s''ajoute à des voyages longue distance, sans s''y substituer ». Elle conclut : « Faut-il pour autant disqualifier la démarche ? Certainement pas. Mais il faut sortir d''une lecture cosmétique ». Sa position est donc critique mais constructive : elle ne rejette pas, elle exige de la cohérence. La réponse B reformule cette nuance. La réponse A est une position adjacente trop tranchée (l''auteure ne disqualifie pas la démarche). La réponse C inverse le propos (l''auteure n''est pas enthousiaste). La réponse D est une demi-vérité : l''auteure critique l''usage cosmétique mais ne le réduit pas à du « pur marketing ».',
    '33333333-0020-0000-0000-000000000007',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000018', 'Elle rejette le slow tourisme comme une fausse solution écologique',                                          false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000018', 'Elle reconnaît la démarche mais en pointe les usages cosmétiques',                                            true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000018', 'Elle défend chaleureusement le slow tourisme comme un vrai progrès',                                          false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000018', 'Elle considère le slow tourisme comme un pur argument marketing sans intérêt',                                false, 4);

-- Q10 : inférence sur le comportement des voyageurs
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000019', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
    'Quel comportement de voyageur l''auteure critique-t-elle implicitement ?',
    'L''auteure écrit : « le slow tourisme s''ajoute à des voyages longue distance, sans s''y substituer. On part en train à 200 km de chez soi pour un week-end responsable, puis on prend l''avion six mois plus tard pour les vraies vacances ». Le comportement critiqué est donc celui d''un cumul plutôt que d''un arbitrage. La réponse C reformule cette logique. La réponse A est une demi-vérité : le voyageur paresseux n''est pas évoqué. La réponse B confond le contenu (le voyage) et le critère (l''écologie). La réponse D propose une position adjacente mais inverse : l''auteure ne critique pas l''absence de voyage, mais l''ajout d''un voyage « propre » à des voyages polluants.',
    '33333333-0020-0000-0000-000000000007',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000019', 'Le voyageur qui se contente de destinations proches par paresse',                                              false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000019', 'Le voyageur qui choisit ses destinations sans tenir compte de l''écologie',                                    false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000019', 'Le voyageur qui ajoute le slow tourisme à ses long-courriers au lieu de les remplacer',                        true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000019', 'Le voyageur qui renonce à voyager au nom de l''écologie',                                                      false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 🎓 Media 6 : Formation continue management (Q11-Q12)
-- ──────────────────────────────────────────────────────────────────────────

-- Q11 : repérage avec piège (qui peut candidater)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000020', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reperage_explicite',
    'Quel profil peut postuler à cette formation ?',
    'La page exige quatre conditions cumulatives : Bac+3 minimum, « au moins 5 ans d''expérience professionnelle dont 2 en encadrement », sélection sur dossier ET entretien individuel obligatoire. La réponse B respecte tous ces critères (Bac+3 OK, 6 ans dont 3 d''encadrement OK). La réponse A échoue sur l''encadrement (1 an seulement, alors que 2 sont exigés). La réponse C échoue sur le diplôme (Bac+2 ne suffit pas, même avec une longue expérience — la page mentionne la VAE comme équivalence possible mais elle n''est pas demandée ici). La réponse D échoue sur l''expérience d''encadrement (4 ans d''expérience totale, dont aucune en encadrement déclarée).',
    '33333333-0020-0000-0000-000000000008',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000020', 'Un titulaire d''un Master avec 5 ans d''expérience dont 1 an d''encadrement',                                     false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000020', 'Un titulaire d''un Bac+3 avec 6 ans d''expérience dont 3 ans d''encadrement',                                    true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000020', 'Un titulaire d''un BTS avec 10 ans d''expérience et 5 ans d''encadrement',                                       false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000020', 'Un titulaire d''un Master avec 4 ans d''expérience dans des fonctions techniques',                               false, 4);

-- Q12 : détail spécifique (modalité financière)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, media_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000021', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_detail_specifique',
    'Que peut-on déduire de la mention « éligible CPF + financement employeur possible » ?',
    'La mention indique deux voies cumulables ou alternatives : utiliser le compte personnel de formation (CPF) du candidat, et/ou demander un financement à son employeur. Aucune des deux n''est obligatoire, et elles peuvent se combiner. La réponse B reformule cette flexibilité. La réponse A est une position adjacente trop restrictive : aucune des deux n''est obligatoire. La réponse C inverse la logique : la mention rend possible plusieurs solutions, sans imposer le financement personnel. La réponse D est une demi-vérité : l''employeur peut financer, mais ce n''est pas mentionné comme obligatoire pour autant — c''est une « possibilité ».',
    '33333333-0020-0000-0000-000000000008',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000021', 'Le candidat doit obligatoirement mobiliser son CPF ET un financement employeur',                                 false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000021', 'Le candidat peut financer la formation par son CPF, par son employeur, ou en combinant les deux',                 true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000021', 'Le candidat doit financer lui-même la formation sur ses fonds propres',                                            false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000021', 'L''employeur du candidat est obligatoirement impliqué dans le financement',                                        false, 4);


-- ============================================================================
-- ❓ 4. QUESTIONS TEXTE (12) — CE B2 texte
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 1 : Sens du travail (Q13-Q14)
-- ──────────────────────────────────────────────────────────────────────────

-- Q13 : ton de l'auteur
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000030', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Quelle position l''auteur défend-il face à l''évolution du rapport au travail ?',
    'L''auteur écrit : « ce n''est pas le travail qui est rejeté, mais l''idée qu''il doive sacrifier le reste » et appelle les organisations à « entendre ce déplacement, sans se contenter d''ajuster à la marge ». Sa position est donc d''accompagner le changement plutôt que de le combattre. La réponse B reformule cette posture. La réponse A est une position adjacente mais inverse : l''auteur ne juge pas alarmiste, au contraire. La réponse C est une demi-vérité : l''auteur cite cette inquiétude mais s''en distancie ensuite. La réponse D contredit l''auteur qui ne dit pas que le travail garde sa place sacrée — il dit l''inverse, que cette centralité s''effrite.',
    '44444444-0020-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000030', 'Il s''inquiète d''une baisse durable de la productivité collective',                                       false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000030', 'Il appelle les organisations à entendre l''évolution plutôt qu''à la contrer',                            true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000030', 'Il craint que les jeunes générations refusent désormais de travailler',                                    false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000030', 'Il défend la centralité historique du travail dans la construction de soi',                                false, 4);

-- Q14 : reformulation des attentes
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000031', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Selon l''auteur, qu''est-ce qui a changé dans le rapport au travail ?',
    'L''auteur écrit que les actifs « refusent qu''il occupe toute la place » et résume : « Conciliation, sens, équilibre : les mots ont changé, et avec eux les attentes ». Plus loin : « ce n''est pas le travail qui est rejeté, mais l''idée qu''il doive sacrifier le reste ». La réponse C reformule exactement ce déplacement. La réponse A est une demi-vérité : la baisse d''importance est nuancée par l''auteur (« la majorité continuent de juger le travail important »). La réponse B est une position adjacente erronée : c''est l''attente patronale qui est jugée excessive, pas l''attente salariale. La réponse D adopte une formulation trop tranchée : l''auteur ne parle pas de génération en particulier, mais d''une évolution générale.',
    '44444444-0020-0000-0000-000000000002',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000031', 'Le travail a perdu toute importance dans la vie des actifs',                                          false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000031', 'Les salariés exigent désormais des rémunérations plus élevées',                                       false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000031', 'Le travail reste important, mais ne doit plus occuper toute la place',                                true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000031', 'Les jeunes refusent désormais le travail tel qu''il était pensé avant',                                false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 2 : Voiture en ville (Q15-Q16)
-- ──────────────────────────────────────────────────────────────────────────

-- Q15 : idée principale
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000032', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quelle est l''idée centrale développée dans ce texte ?',
    'L''auteur décrit la limitation de la voiture en ville, mais insiste sur « le risque d''une fracture territoriale » entre centre et périphérie, et conclut : « réussir la transition, ce n''est pas seulement adopter de bonnes mesures : c''est aussi garantir qu''elles ne creusent pas, sous prétexte d''écologie, de nouvelles formes d''injustice sociale ». Il défend donc une transition qui doit être socialement juste. La réponse B reformule cette thèse. La réponse A est une position adjacente trop tranchée : l''auteur ne critique pas les mesures, il appelle à les compléter. La réponse C est une demi-vérité : il décrit le succès en centre-ville mais sa thèse principale dépasse ce constat. La réponse D inverse le propos : l''auteur ne défend pas la voiture, il défend l''équité de la transition.',
    '44444444-0020-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000032', 'Les politiques anti-voitures sont une erreur qu''il faudrait corriger rapidement',                                false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000032', 'La transition écologique urbaine doit éviter de créer de nouvelles injustices sociales',                          true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000032', 'Les habitants du centre-ville approuvent globalement les nouvelles politiques de mobilité',                       false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000032', 'La voiture individuelle reste indispensable et son éviction sera contre-productive',                              false, 4);

-- Q16 : inférence sur les habitants des couronnes
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000033', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
    'Pourquoi les habitants des couronnes périurbaines vivent-ils mal ces politiques ?',
    'Le texte précise que ces habitants sont « mal desservis par les transports collectifs » et que les nouvelles politiques se traduisent pour eux par « trajets allongés, stationnement plus rare, factures de carburant en hausse ». Leur situation est donc subie : ils dépendent de la voiture par défaut d''alternatives. La réponse C reformule cette logique. La réponse A est une position adjacente mais réductrice : ce n''est pas une question de principe écologique, c''est une contrainte pratique. La réponse B inverse la logique : ils ne sont pas hostiles à l''écologie, ils subissent un effet collatéral. La réponse D est une demi-vérité : les factures de carburant augmentent, mais ce n''est pas la cause unique.',
    '44444444-0020-0000-0000-000000000003',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000033', 'Ils sont attachés par principe à la voiture comme symbole de liberté',                                            false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000033', 'Ils rejettent la transition écologique imposée par les municipalités',                                            false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000033', 'Ils dépendent de la voiture faute d''alternatives de transport adaptées',                                          true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000033', 'Ils sont uniquement préoccupés par la hausse du prix du carburant',                                                false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 3 : Information continue (Q17-Q18)
-- ──────────────────────────────────────────────────────────────────────────

-- Q17 : ton de l'auteur
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000034', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Comment l''auteur juge-t-il le journalisme d''information continue ?',
    'L''auteur écrit : « Le constat n''invalide pas le journalisme d''actualité, encore moins le rôle essentiel des rédactions. Il interroge en revanche une mécanique éditoriale qui privilégie souvent la rapidité sur la mise en perspective ». Il distingue donc le métier (qu''il défend) de la mécanique éditoriale dominante (qu''il critique). La réponse C reformule cette distinction. La réponse A inverse partiellement le propos : l''auteur ne rejette pas le journalisme, il critique son fonctionnement actuel. La réponse B est une position adjacente erronée : l''auteur valorise le journalisme, pas la « lassitude informationnelle ». La réponse D est une demi-vérité : il évoque des tentatives positives mais ne les juge pas suffisantes.',
    '44444444-0020-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000034', 'Il rejette globalement ce type de journalisme et appelle à le réformer',                                          false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000034', 'Il approuve la lassitude des lecteurs qui se détournent des médias',                                              false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000034', 'Il défend le journalisme tout en critiquant sa mécanique éditoriale dominante',                                  true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000034', 'Il salue les expérimentations en cours comme la solution déjà trouvée',                                            false, 4);

-- Q18 : inférence sur la lassitude informationnelle
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000035', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_inference_intention',
    'Comment l''auteur explique-t-il la « lassitude informationnelle » ?',
    'L''auteur écrit que cette lassitude vient de l''exposition « en continu à des nouvelles souvent anxiogènes et décontextualisées » et que la mécanique éditoriale « privilégie souvent la rapidité sur la mise en perspective ». La cause est donc structurelle : le format même de l''information continue, pas son contenu en soi. La réponse B reformule cette analyse. La réponse A est une demi-vérité : l''auteur ne dit pas que les lecteurs sont devenus paresseux. La réponse C inverse la causalité : l''auteur ne dit pas que les journalistes manquent de talent, mais que le format les contraint. La réponse D est une position adjacente erronée : l''auteur ne pointe pas le manque de fiabilité, mais l''absence de mise en perspective.',
    '44444444-0020-0000-0000-000000000004',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000035', 'Les lecteurs sont devenus paresseux et préfèrent les divertissements',                                            false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000035', 'Le format même de l''information continue, anxiogène et sans recul, finit par épuiser',                            true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000035', 'Le manque de talent des journalistes contemporains détourne le public',                                          false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000035', 'Les médias manquent de fiabilité, ce qui décourage les citoyens',                                                 false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 4 : Seconde main (Q19-Q20)
-- ──────────────────────────────────────────────────────────────────────────

-- Q19 : idée principale (paradoxe)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000036', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quel paradoxe le texte met-il en évidence concernant la seconde main ?',
    'L''auteur écrit : « La seconde main, conçue à l''origine comme une alternative à la surproduction, en devient parfois un prolongement déguisé », car « certains consommateurs achètent désormais plus, parce qu''ils achètent moins cher et avec moins de culpabilité ». La réponse C reformule ce paradoxe. La réponse A est une position adjacente erronée : l''auteur ne nie pas l''intérêt écologique. La réponse B est une demi-vérité : le marché s''est industrialisé, mais ce n''est pas le paradoxe central. La réponse D est une formulation trop tranchée : l''auteur ne dit pas que la seconde main est néfaste, mais qu''elle peut être déviée de son objectif.',
    '44444444-0020-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000036', 'Acheter d''occasion n''a aucun impact écologique réel',                                                            false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000036', 'Le marché de la seconde main s''est industrialisé comme le neuf',                                                  false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000036', 'Une démarche pensée pour réduire la surconsommation peut au contraire l''entretenir',                              true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000036', 'L''achat d''occasion est globalement néfaste pour l''environnement',                                                false, 4);

-- Q20 : détail spécifique (comportement consommateur)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000037', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_detail_specifique',
    'Quel comportement adoptent certains consommateurs face à l''offre d''occasion ?',
    'L''auteur précise : « Certains consommateurs achètent désormais plus, parce qu''ils achètent moins cher et avec moins de culpabilité ». L''effet pervers tient à la conjonction de deux ressorts : prix bas + bonne conscience. La réponse B reformule cette double cause. La réponse A est une demi-vérité : le prix bas est cité, mais isolément. La réponse C est une position adjacente erronée : l''auteur ne dit pas qu''ils achètent autant qu''avant, il dit qu''ils achètent plus. La réponse D inverse le propos : il n''est pas question d''un retour au neuf, mais d''une consommation accrue de seconde main.',
    '44444444-0020-0000-0000-000000000005',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000037', 'Ils achètent davantage parce que les prix sont bas',                                                              false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000037', 'Ils achètent plus car le prix bas et la bonne conscience se cumulent',                                            true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000037', 'Ils maintiennent un niveau d''achat comparable à celui du neuf',                                                    false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000037', 'Ils délaissent l''occasion pour revenir progressivement au neuf',                                                  false, 4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 5 : Sport sur ordonnance (Q21-Q22)
-- ──────────────────────────────────────────────────────────────────────────

-- Q21 : reformulation (limites)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000038', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Quelles limites du « sport sur ordonnance » l''auteur identifie-t-il ?',
    'L''auteur évoque trois limites cumulées : la dépendance « à la motivation du patient et à son accès géographique à des structures adaptées », « le reste à charge » dissuasif pour les ménages modestes, et le besoin d''un « accompagnement humain » sans lequel l''adhésion s''effrite. La réponse B reformule cet ensemble. La réponse A est une position adjacente erronée : l''auteur ne remet pas en cause l''efficacité scientifique du dispositif (« les bénéfices ne font plus débat »). La réponse C est une demi-vérité : l''accès géographique est cité, mais isolé des autres limites. La réponse D contredit l''auteur, qui souligne au contraire que les professionnels apprécient le dispositif.',
    '44444444-0020-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000038', 'Le manque de preuves scientifiques de son efficacité',                                                            false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000038', 'L''inégale accessibilité, le coût pour le patient et le besoin d''un suivi humain',                                 true,  2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000038', 'L''éloignement géographique des structures partenaires, uniquement',                                              false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000038', 'Le manque d''adhésion des professionnels de santé au dispositif',                                                  false, 4);

-- Q22 : ton de l'auteur
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000039', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_ton_auteur',
    'Quelle position l''auteur adopte-t-il face au dispositif ?',
    'L''auteur écrit : « Promouvoir le sport-santé comme outil thérapeutique est donc une excellente intention ; le réussir suppose de penser, en amont, les conditions concrètes de son déploiement à grande échelle. Sinon, ce qui devait être un progrès collectif risque de ne profiter qu''aux mieux dotés ». Sa position est favorable au principe, mais exigeante sur les conditions. La réponse D reformule cette nuance. La réponse A est une demi-vérité : la critique des inégalités existe, mais l''auteur ne juge pas le dispositif inéquitable « par nature ». La réponse B est une position adjacente trop enthousiaste. La réponse C contredit l''auteur, qui défend le dispositif sur le principe.',
    '44444444-0020-0000-0000-000000000006',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000039', 'Il dénonce un dispositif structurellement inéquitable',                                                          false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000039', 'Il salue sans réserve une innovation thérapeutique majeure',                                                      false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000039', 'Il rejette le dispositif comme un effet de mode sans efficacité réelle',                                          false, 3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000039', 'Il approuve le principe mais alerte sur les conditions concrètes de réussite',                                    true,  4);

-- ──────────────────────────────────────────────────────────────────────────
-- 📄 Passage 6 : Surveillance des employeurs (Q23-Q24)
-- ──────────────────────────────────────────────────────────────────────────

-- Q23 : idée principale
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000040', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_idee_principale',
    'Quel message principal le texte cherche-t-il à transmettre ?',
    'L''auteur conclut : « Surveiller à distance, c''est aussi reconnaître implicitement qu''on doute. Or la confiance, longuement érigée comme un pilier des organisations modernes, supporte mal d''être ainsi remise en cause. À vouloir tout mesurer, on risque surtout de mesurer la perte d''engagement ». Le message est donc que la surveillance fait peser une menace sur la relation de confiance et l''engagement. La réponse C reformule cette idée. La réponse A est une demi-vérité : la dimension juridique est évoquée mais n''est pas le message central. La réponse B est une position adjacente trop tranchée : l''auteur ne défend pas le télétravail en soi. La réponse D contredit l''auteur qui critique la généralisation de ces outils.',
    '44444444-0020-0000-0000-000000000007',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000040', 'La surveillance des télétravailleurs est juridiquement encadrée en France',                                       false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000040', 'Le télétravail doit être défendu comme un acquis pour les salariés',                                              false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000040', 'La surveillance numérique érode la confiance et finit par fragiliser l''engagement',                               true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000040', 'Les outils de pilotage améliorent la productivité des équipes',                                                   false, 4);

-- Q24 : reformulation (paradoxe final)
INSERT INTO questions (
    id, module, theme_id, difficulty, question_type, competence_code,
    statement, explanation, passage_id,
    is_active, created_at, updated_at
) VALUES (
    '55555555-0020-0000-0000-000000000041', 'TCF',
    '22222222-0000-0000-0000-000000000002', 'B2', 'CE', 'ce_reformulation',
    'Que veut dire l''auteur en concluant « à vouloir tout mesurer, on risque surtout de mesurer la perte d''engagement » ?',
    'L''auteur joue sur le double sens du verbe « mesurer » : les outils de surveillance prétendent mesurer la productivité, mais en réalité, ils provoquent un désengagement qui apparaît alors dans les indicateurs. La conséquence visée se retourne contre celui qui la met en place. La réponse C reformule ce retournement. La réponse A confond mesure (l''outil) et productivité (l''effet attendu) : l''auteur ne dit pas que la mesure améliore la productivité. La réponse B est une demi-vérité : l''outil détecte effectivement quelque chose, mais c''est l''effet pervers de son existence. La réponse D est une position adjacente trop simpliste : l''auteur ne dit pas que la surveillance est inutile, mais qu''elle est contre-productive.',
    '44444444-0020-0000-0000-000000000007',
    true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
);
INSERT INTO choices (id, question_id, label, is_correct, display_order) VALUES
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000041', 'Mesurer la productivité finit toujours par l''améliorer',                                                         false, 1),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000041', 'Les outils de surveillance permettent de détecter le désengagement existant',                                     false, 2),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000041', 'En cherchant à tout contrôler, l''employeur provoque lui-même le désengagement qu''il croit mesurer',                true,  3),
    (gen_random_uuid(), '55555555-0020-0000-0000-000000000041', 'Les outils de mesure sont inutiles car ils ne donnent aucune information',                                          false, 4);
