# Contrôle — les 34 questions que `batch-v4.sh` sélectionnerait

Établi **sans aucun appel LLM**. Le « thème à la suggestion » est reconstruit
depuis les fichiers de lot de la campagne (`campagne-v4/`), qui portent le
code du thème dans leur nom : c'est la seule trace de cet état, la table des
suggestions ne le mémorise pas.

🛑 **Les 34 sont exactement les 34 réponses « aucune notion » de la campagne.**
Aucune autre question n'est éligible. C'est ce qui rendait mon comptage
précédent faux : je cherchais une suggestion rattachée à une notion pour
reconnaître une question déplacée, alors qu'une réponse « aucune notion » ne
pointe vers aucune notion.

## DOIT_ETRE_REPROPOSEE — 20

| Question | Thème à la suggestion | Thème actuel | Suggestion v4 | Verdict | Pourquoi la requête la retient |
|---|---|---|---|---|---|
| Quelle école prestigieuse française forme les hauts fonctionnaires de l'État ? | Histoire-Géo | Institutions | `AUCUNE  0.80` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Dans quel type de régime les dirigeants sont-ils choisis par les citoyens ? | Institutions | Principes | `AUCUNE  0.60` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Quel article de la DDHC consacre le principe de la souveraineté nationale ? | Institutions | Droits/devoirs | `AUCUNE  0.60` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Quel traité a créé l'Union européenne sous sa forme actuelle ? | Institutions | Histoire-Géo | `AUCUNE  0.70` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Quel traité a fondé la Communauté économique européenne en 1957 ? | Institutions | Histoire-Géo | `AUCUNE  0.70` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| À partir de quel âge l'instruction est-elle obligatoire en France ? | Principes | Société | `AUCUNE  0.90` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Combien y a-t-il eu de Républiques en France depuis 1792 ? | Principes | Histoire-Géo | `AUCUNE  0.65` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| De quand date la Constitution de la Ve République ? | Principes | Histoire-Géo | `AUCUNE  0.75` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Depuis quand le suffrage universel masculin existe-t-il en France ? | Principes | Histoire-Géo | `AUCUNE  0.60` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Depuis quelle année les femmes ont-elles le droit de vote en France ? | Principes | Histoire-Géo | `AUCUNE  0.60` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| En quelle année la première République française a-t-elle été proclamée ? | Principes | Histoire-Géo | `AUCUNE  0.60` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| L'homophobie (propos ou actes haineux envers les personnes homosexuelles) est-elle un délit ? | Principes | Droits/devoirs | `AUCUNE  0.75` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Le drapeau européen est-il aussi affiché sur les bâtiments officiels français ? | Principes | Institutions | `AUCUNE  0.85 + pv_symboles_devise  0.30` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Le racisme est-il puni par la loi en France ? | Principes | Droits/devoirs | `AUCUNE  0.75` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Que permet le principe de laïcité ? | Principes | Droits/devoirs | `AUCUNE  0.75 + pv_laicite  0.40` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Quel droit est garanti par la laïcité ? | Principes | Droits/devoirs | `AUCUNE  0.75 + pv_laicite  0.40` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Quel est l'un des rôles des associations ? | Principes | Société | `AUCUNE  0.60` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Quel homme politique a fondé la Ve République ? | Principes | Histoire-Géo | `AUCUNE  0.60` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Quelle proposition est correcte ? La liberté d'expression : | Principes | Droits/devoirs | `AUCUNE  0.85 + pv_libertes_ddhc  0.30` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |
| Le tabac est-il interdit aux mineurs en France ? | Société | Droits/devoirs | `AUCUNE  0.60` | — | « aucune notion » produite dans un AUTRE thème : inapplicable ici |

## ORPHELINE_A_CONFIRMER — 14

| Question | Thème à la suggestion | Thème actuel | Suggestion v4 | Verdict | Pourquoi la requête la retient |
|---|---|---|---|---|---|
| Que peut faire un citoyen face à un mauvais fonctionnement d'un service public ? | Droits/devoirs | Droits/devoirs | `AUCUNE  0.70` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Quel événement tragique a marqué Paris le 13 novembre 2015 ? | Histoire-Géo | Histoire-Géo | `AUCUNE  0.60` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Quel sommet mondial s'est tenu à Paris en décembre 2015 sur le climat ? | Histoire-Géo | Histoire-Géo | `AUCUNE  0.80` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Quel traité a mis fin à la guerre de Trente Ans (1648) ? | Histoire-Géo | Histoire-Géo | `AUCUNE  0.85` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Quelle institution promeut la langue française dans le monde ? | Histoire-Géo | Histoire-Géo | `AUCUNE  0.60` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Que désigne l'INSEE ? | Institutions | Institutions | `AUCUNE  0.60` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Que désigne la notion de 'service public' en droit administratif français ? | Institutions | Institutions | `AUCUNE  0.60` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Que prévoit la loi pour assurer la transparence de la vie publique ? | Institutions | Institutions | `AUCUNE  0.60` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Quels principes régissent le service public en France ? | Institutions | Institutions | `AUCUNE  0.60` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Quelle autorité peut être saisie gratuitement en cas de discrimination ? | Principes | Principes | `AUCUNE  0.60` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Qu'est-ce qu'un dossier de surendettement ? | Société | Société | `AUCUNE  0.50` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Que désigne la 'caution' dans la location d'un logement ? | Société | Société | `AUCUNE  0.50` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Quel âge minimum pour entrer en boîte de nuit en France ? | Société | Société | `AUCUNE  0.50` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |
| Quel établissement gère le prêt de livres gratuitement ? | Société | Société | `AUCUNE  0.60` | — | « aucune notion » SANS verdict humain : la règle ne peut pas la déclarer applicable |

## ANOMALIE_DE_SELECTION — 0

_Aucune._

