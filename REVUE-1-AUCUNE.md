# Revue 1 — les 34 « aucune notion »

Campagne complète `PROMPT_TAG_NOTION_v4`, 791 questions. Le modèle conclut ici qu'**aucune notion de son thème ne convient**. C'est le signal le plus dense de la campagne, et il ne parle presque jamais du référentiel : il parle du **rangement du corpus**.

> 🛑 **Le modèle PROPOSE, il n'applique rien.** Aucune de ces suggestions n'a touché `civic_notion_id` — 48 questions sont taguées dans tout le dépôt, et toutes l'ont été par un geste humain.

Le verdict proposé est **déduit de la rationale que le modèle a déjà écrite** — aucun appel supplémentaire. `MAUVAIS_THEME` quand il nomme une notion ou un thème de destination, `VRAIE_ORPHELINE` sinon.

🛑 Trois lignes portent une destination BARRÉE : le modèle en nommait une, le propriétaire l'a refusée le 2026-09-11. Les trois tiennent au même constat — « Défenseur des droits / recours face à l'administration » forme un groupe de trois questions, avec celle du pilote restée en suspens, et trois questions ne font pas une notion.

⚠️ Deux lignes portent la mention *(lu dans la prose)* : le modèle y nomme sa destination en toutes lettres sans écrire le code. Je les ai inscrites à la main plutôt que d'élargir la détection — une regex sur les libellés aurait aussi attrapé des mentions de passage et fabriqué de fausses destinations. Ce sont les lignes à contester en premier.

| Thème | Cas | Dont mauvais thème | Dont orphelines |
|---|---:|---:|---:|
| Principes et valeurs | 15 | 14 | 1 |
| Institutions | 8 | 4 | 4 |
| Vivre en société | 5 | 1 | 4 |
| Histoire, géo et culture | 5 | 1 | 4 |
| Droits et devoirs | 1 | 0 | 1 |

## Principes et valeurs — 15 cas

| Question | Confiance | Raison donnée par le modèle | Destination nommée | Verdict proposé |
|---|---:|---|---|---|
| À partir de quel âge l'instruction est-elle obligatoire en France ? | 0.90 | Question sur l'obligation scolaire, relève de CIV_SOCIETE (éducation), pas du référentiel symboles/valeurs. | Vivre en société | **MAUVAIS_THEME** |
| Le drapeau européen est-il aussi affiché sur les bâtiments officiels français ? | 0.85 | Symboles européens (drapeau UE) → inst_ue, hors référentiel. | `inst_ue` (Institutions) | **MAUVAIS_THEME** |
| Quelle proposition est correcte ? La liberté d'expression : | 0.85 | Régime juridique et limites concrètes de la liberté d'expression → dd_libertes_limites, hors référentiel. | `dd_libertes_limites` (Droits et devoirs) | **MAUVAIS_THEME** |
| De quand date la Constitution de la Ve République ? | 0.75 | Date Constitution 1958, relève plutôt de hg_republiques (hors référentiel). | `hg_republiques` (Histoire, géo et culture) | **MAUVAIS_THEME** |
| L'homophobie (propos ou actes haineux envers les personnes homosexuelles) est-elle un délit ? | 0.75 | Sanction pénale de l'homophobie → dd_interdits_quotidien, hors référentiel. | `dd_interdits_quotidien` (Droits et devoirs) | **MAUVAIS_THEME** |
| Le racisme est-il puni par la loi en France ? | 0.75 | Sanction pénale du racisme → dd_interdits_quotidien, hors référentiel. | `dd_interdits_quotidien` (Droits et devoirs) | **MAUVAIS_THEME** |
| Que permet le principe de laïcité ? | 0.75 | Droit individuel de croire ou non → dd_libertes_limites, hors référentiel selon frontière laïcité. | `dd_libertes_limites` (Droits et devoirs) | **MAUVAIS_THEME** |
| Quel droit est garanti par la laïcité ? | 0.75 | Droit individuel de conscience/religion → dd_libertes_limites, hors référentiel. | `dd_libertes_limites` (Droits et devoirs) | **MAUVAIS_THEME** |
| Combien y a-t-il eu de Républiques en France depuis 1792 ? | 0.65 | Chronologie des cinq républiques → hg_republiques, hors référentiel. | `hg_republiques` (Histoire, géo et culture) | **MAUVAIS_THEME** |
| Depuis quand le suffrage universel masculin existe-t-il en France ? | 0.60 | Repère historique daté (1848) → hg_conquetes_droits, hors référentiel. | `hg_conquetes_droits` (Histoire, géo et culture) | **MAUVAIS_THEME** |
| Depuis quelle année les femmes ont-elles le droit de vote en France ? | 0.60 | Date historique du droit de vote des femmes → relève de hg_conquetes_droits, hors référentiel. | `hg_conquetes_droits` (Histoire, géo et culture) | **MAUVAIS_THEME** |
| En quelle année la première République française a-t-elle été proclamée ? | 0.60 | Date de proclamation de la Ire République → hg_republiques, hors référentiel. | `hg_republiques` (Histoire, géo et culture) | **MAUVAIS_THEME** |
| Quel est l'un des rôles des associations ? | 0.60 | Rôle des associations, relève plutôt de CIV_SOCIETE. | Vivre en société | **MAUVAIS_THEME** |
| Quel homme politique a fondé la Ve République ? | 0.60 | Personnage historique fondateur de la Ve République → hg_republiques, hors référentiel. | `hg_republiques` (Histoire, géo et culture) | **MAUVAIS_THEME** |
| Quelle autorité peut être saisie gratuitement en cas de discrimination ? | 0.60 | Défenseur des droits, institution → hors référentiel du thème. | 🛑 *Défenseur des droits : n'entre pas dans « dd_police_justice ».* | **VRAIE_ORPHELINE** |

## Institutions — 8 cas

| Question | Confiance | Raison donnée par le modèle | Destination nommée | Verdict proposé |
|---|---:|---|---|---|
| Quel traité a créé l'Union européenne sous sa forme actuelle ? | 0.70 | Traité de Maastricht relève de l'histoire de la construction européenne (hg_europe), hors référentiel. | `hg_europe` (Histoire, géo et culture) | **MAUVAIS_THEME** |
| Quel traité a fondé la Communauté économique européenne en 1957 ? | 0.70 | Traité de Rome relève de l'histoire de la construction européenne (hg_europe), hors référentiel. | `hg_europe` (Histoire, géo et culture) | **MAUVAIS_THEME** |
| Dans quel type de régime les dirigeants sont-ils choisis par les citoyens ? | 0.60 | Notion générale de démocratie, hors référentiel institutionnel français précis. | `pv_republique_democratie` (Principes et valeurs) ⚠️ *(lu dans la prose, pas écrit en code)* | **MAUVAIS_THEME** |
| Que désigne l'INSEE ? | 0.60 | L'INSEE est un organisme statistique, ne correspond à aucune notion institutionnelle du référentiel. | — | **VRAIE_ORPHELINE** |
| Que désigne la notion de 'service public' en droit administratif français ? | 0.60 | Notion générale de service public en droit administratif, ne correspond pas précisément aux institutions listées. | — | **VRAIE_ORPHELINE** |
| Que prévoit la loi pour assurer la transparence de la vie publique ? | 0.60 | Transparence de la vie publique/HATVP relève plutôt de CIV_DROITS_DEVOIRS ou d'un autre thème, pas des institutions listées. | 🛑 *Institution de contrôle de la vie publique : reste dans les institutions.* | **VRAIE_ORPHELINE** |
| Quel article de la DDHC consacre le principe de la souveraineté nationale ? | 0.60 | Article de la DDHC sur la souveraineté nationale relève plutôt d'un thème sur les droits/textes fondateurs, hors référentiel institutions. | `dd_textes_fondateurs` (Droits et devoirs) ⚠️ *(lu dans la prose, pas écrit en code)* | **MAUVAIS_THEME** |
| Quels principes régissent le service public en France ? | 0.60 | Principes du service public (lois de Rolland) hors périmètre précis des notions institutionnelles. | — | **VRAIE_ORPHELINE** |

## Vivre en société — 5 cas

| Question | Confiance | Raison donnée par le modèle | Destination nommée | Verdict proposé |
|---|---:|---|---|---|
| Le tabac est-il interdit aux mineurs en France ? | 0.60 | Interdiction de vente de tabac aux mineurs, relève plutôt des interdits du quotidien (dd_interdits_quotidien), hors référentiel. | `dd_interdits_quotidien` (Droits et devoirs) | **MAUVAIS_THEME** |
| Quel établissement gère le prêt de livres gratuitement ? | 0.60 | Bibliothèque/médiathèque, service culturel hors référentiel. | — | **VRAIE_ORPHELINE** |
| Qu'est-ce qu'un dossier de surendettement ? | 0.50 | Surendettement ne correspond à aucune notion du référentiel. | — | **VRAIE_ORPHELINE** |
| Que désigne la 'caution' dans la location d'un logement ? | 0.50 | Caution locative ne relève d'aucune notion du référentiel (logement hors HLM). | — | **VRAIE_ORPHELINE** |
| Quel âge minimum pour entrer en boîte de nuit en France ? | 0.50 | Âge légal pour entrer en boîte de nuit, ne relève d'aucune notion du référentiel scolaire/social. | — | **VRAIE_ORPHELINE** |

## Histoire, géo et culture — 5 cas

| Question | Confiance | Raison donnée par le modèle | Destination nommée | Verdict proposé |
|---|---:|---|---|---|
| Quel traité a mis fin à la guerre de Trente Ans (1648) ? | 0.85 | Traités de Westphalie 1648, hors périmètre du référentiel (avant la Révolution, diplomatie internationale). | — | **VRAIE_ORPHELINE** |
| Quel sommet mondial s'est tenu à Paris en décembre 2015 sur le climat ? | 0.80 | La COP21 est un sommet international contemporain, hors du référentiel histoire-géo fourni (thème environnement/international). | — | **VRAIE_ORPHELINE** |
| Quelle école prestigieuse française forme les hauts fonctionnaires de l'État ? | 0.80 | L'ENA/INSP est une institution administrative actuelle, hors référentiel histoire-géo (relève d'un thème institutions). | `inst_gouvernement` (Institutions) ⚠️ *(lu dans la prose, pas écrit en code)* | **MAUVAIS_THEME** |
| Quel événement tragique a marqué Paris le 13 novembre 2015 ? | 0.60 | Attentats de 2015 ne correspondent à aucune notion du référentiel (hors périmètre thématique historique). | — | **VRAIE_ORPHELINE** |
| Quelle institution promeut la langue française dans le monde ? | 0.60 | Institution de la langue française - relève plutôt d'un autre thème (langue/institutions), hors référentiel HG. | — | **VRAIE_ORPHELINE** |

## Droits et devoirs — 1 cas

| Question | Confiance | Raison donnée par le modèle | Destination nommée | Verdict proposé |
|---|---:|---|---|---|
| Que peut faire un citoyen face à un mauvais fonctionnement d'un service public ? | 0.70 | Saisine du Défenseur des droits relève plutôt de CIV_SOCIETE ou institutions, hors référentiel. | 🛑 *Même groupe « Défenseur des droits / recours » : pas un sujet de vie quotidienne.* | **VRAIE_ORPHELINE** |

