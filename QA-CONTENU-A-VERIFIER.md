# QA de contenu — questions à vérifier sur le fond

🛑 **Ce n'est pas une liste de taxonomie.** Le rattachement à une notion de ces
questions est **déjà tranché** et n'est pas rouvert ici. Ce fichier recense les
questions dont l'ÉNONCÉ, les PROPOSITIONS ou l'EXPLICATION méritent un contrôle
éditorial — libellé daté, réponse discutable, formulation ambiguë. Mélanger les
deux vérifications, c'est se condamner à rouvrir un référentiel pour un
problème de rédaction.

**Quand la traiter** : après le tagging, pas pendant.

| # | Question | Nature du doute |
|---|---|---|
| 1 | École des hauts fonctionnaires | énoncé au présent, école renommée en 2022 |
| 2 | Général de la guerre de Cent Ans | Jeanne d'Arc n'était pas générale |
| 3 | Nombre de référendums | bonne réponse « environ 10 » |
| 4 | Ministre fondateur de la Sécurité sociale | l'explication contredit l'énoncé |
| 5 | Slogan de la Révolution de 1789 | la devise n'est pas de 1789 |
| 6 | Institution gérant le budget | singulier pour trois institutions |
| 7 | Texte garantissant droits et libertés | deux exemplaires, deux bonnes réponses différentes |

🛑 **Les 25 corrections factuelles du 2026-09-11 ne sont PAS dans cette liste** :
elles ont été prouvées sur source officielle et appliquées par la migration
`V295`. Ce fichier ne garde que ce qui **reste à trancher**.

---

### 1. « Quelle école prestigieuse française forme les hauts fonctionnaires de l'État ? »

| | |
|---|---|
| **Thème** | `CIV_INSTITUTIONS` *(déplacée depuis Histoire-Géo par V288)* |
| **Notion** | `inst_gouvernement` — **tranché, ne pas rouvrir** |
| **Signalée par** | confiance du modèle à **0,55**, la plus basse de la reprise du 2026-09-11 |

**Ce que contient la question aujourd'hui.** Bonne réponse : « L'ENA, devenue
INSP en 2022 ». Explication : *« L'ENA (École nationale d'administration), créée
en 1945, a formé les hauts fonctionnaires français. Remplacée en 2022 par l'INSP
(Institut national du service public). »*

**Ce qui est à vérifier.** L'énoncé est au **présent** — « forme » — alors que
l'école qu'il désigne n'existe plus sous ce nom depuis 2022. La bonne réponse
rattrape le décalage en nommant les deux, mais un candidat qui connaît l'INSP
et pas son histoire lit une question dont la réponse littérale est fausse. Deux
issues possibles, et c'est un arbitrage éditorial :

- reformuler l'énoncé au passé (« quelle école a longtemps formé… ») ;
- ou le porter au présent sur l'INSP, et faire de l'ENA la mention historique.

⚠️ **La faible confiance du modèle ne prouve pas ce défaut** — elle a seulement
attiré l'œil dessus. Le défaut, lui, se lit dans le texte.

🛑 **Le verdict taxonomique de toutes ces questions est rendu et n'est pas
rouvert ici.** Leur notion figure en regard pour information seulement.

### 2. « Quel général est associé à la guerre de Cent Ans ? »

`CIV_HISTOIRE_GEO` · `hg_revolution` — bonne réponse : *Jeanne d'Arc (aux côtés
de Charles VII)*.

**Le défaut.** L'énoncé demande un **général**. Jeanne d'Arc n'en était pas un :
ni grade, ni commandement au sens militaire de l'époque. L'explication est
d'ailleurs plus prudente que la question — elle dit « a joué un rôle décisif »,
pas « commandait ». Un candidat qui cherche un chef de guerre peut écarter la
bonne réponse **pour la bonne raison**. Reformuler vers « quelle figure » ou
« quel personnage ».

### 3. « Combien y a-t-il eu de référendums sous la Ve République ? »

`CIV_INSTITUTIONS` · `inst_elections` — bonne réponse : *Environ 10 référendums
depuis 1958*.

**Le défaut.** Un QCM dont la bonne réponse commence par « environ » demande au
candidat de deviner l'imprécision attendue. Le compte exact est connu et
vérifiable : il vaut mieux poser un nombre ferme, ou changer la question pour ce
qu'elle teste réellement — les **sujets** soumis à référendum, que l'explication
énumère déjà.

### 4. « Quel ministre, en 1945, a participé à la fondation de la Sécurité sociale ? »

`CIV_HISTOIRE_GEO` · `hg_conquetes_droits` — bonne réponse : *Pierre Laroque
(avec Ambroise Croizat)*.

🛑 **L'énoncé se contredit avec sa propre explication.** Il demande un
**ministre** ; l'explication répond que Pierre Laroque était **haut
fonctionnaire**, et que le ministre du Travail de l'époque était Ambroise
Croizat. La question dit donc une chose et sa correction le contraire. Deux
sorties : nommer Croizat si l'on tient au mot « ministre », ou remplacer
« ministre » par « haut fonctionnaire » si l'on tient à Laroque.

### 5. « Quel slogan symbolise la Révolution de 1789 ? »

`CIV_PRINCIPES` · `pv_symboles_devise` — bonne réponse : *Liberté, Égalité,
Fraternité*.

**Le défaut.** La formule n'était pas le slogan **de 1789** : elle se fixe
progressivement et ne devient devise officielle qu'avec la IIᵉ, puis la IIIᵉ
République. L'explication le dit à demi-mot — « héritage des principes de la
Révolution » — mais l'énoncé, lui, date la formule de 1789. À réancrer : « quelle
devise est issue des principes de la Révolution ».

### 6. « Quelle institution gère les finances et le budget de l'État ? »

`CIV_INSTITUTIONS` · `inst_gouvernement` — bonne réponse : *Préparé par le
gouvernement, voté par le Parlement, contrôlé par la Cour des comptes*.

**Le défaut.** L'énoncé demande **une** institution au singulier, la réponse en
nomme **trois**, chacune sur un rôle différent. Ce n'est pas une question à
réponse unique mais une question de chaîne budgétaire déguisée. Soit on demande
« qui **prépare** le budget ? », soit on assume « quelles institutions
interviennent, et à quel titre ? » — et alors le singulier doit disparaître de
l'énoncé.

### 7. « Parmi ces textes, lequel garantit les droits et libertés en France ? »

`CIV_DROITS_DEVOIRS` · `dd_textes_fondateurs` — **tranché, ne pas rouvrir**.

**Le défaut, trouvé pendant la déduplication.** Cette question existait en
**deux exemplaires au libellé strictement identique**, dans le même thème et la
même mention — mais avec **deux bonnes réponses différentes** :

- « La Déclaration des droits de l'homme et du citoyen »
- « La Constitution et la Déclaration de 1789 »

Les deux sont défendables, et c'est bien le problème : un candidat qui répond
correctement à l'une se trompe à l'autre. La déduplication a gardé la seconde,
plus complète — la DDHC ne garantit les droits que parce que le bloc de
constitutionnalité l'a intégrée. **Mais le choix mérite une confirmation
éditoriale**, et surtout : si cette divergence existe sur une question, elle
peut exister ailleurs sans qu'un doublon vienne la révéler.


---

## Doutes de la QA factuelle — non corrigés, faute de source qui tranche

🛑 **Rien ici n'a été modifié en base.** On ne remplace pas un fait douteux par
un autre : ces six points attendent un arbitrage ou une source.

### 8. L'altitude du mont Blanc — le corpus se contredit

Deux questions donnent **4 808 m** et **4 809 m**. L'altitude mesurée varie avec
l'enneigement — 4 805,59 m à la campagne de septembre 2023 — et les relevés
récents publiés divergent entre eux. 🛑 **Le vrai défaut n'est pas le chiffre,
c'est la contradiction interne** : quelle que soit la valeur retenue, les deux
questions doivent dire la même chose. Une troisième voie : reformuler sans
chiffre.

### 9. Nouvelle-Calédonie — suites de l'accord de Bougival

« Collectivité sui generis, trois référendums en 2018, 2020 et 2021, tous
rejetés » est exact. Mais les suites institutionnelles de l'accord de juillet
2025 n'ont pas été vérifiées. À contrôler avant de considérer la question
comme à jour.

### 10. RSA jeunes — incomplet plutôt que faux

La condition des deux ans travaillés sur trois est confirmée. La question ignore
en revanche la conditionnalité de 15 à 20 heures d'activité hebdomadaires,
généralisée au 1er janvier 2025.

### 11. `service-public.fr` — domaine migré

Le domaine officiel est désormais **`service-public.gouv.fr`** ; l'ancien
renvoie une redirection permanente. Ce n'est pas faux, c'est daté — et à
répercuter **partout où le produit cite ce domaine**, pas seulement dans cette
question.

### 12. Défaite de Sedan — 1er ou 2 septembre 1870 ?

Le corpus date la défaite du 1er septembre. La bataille court sur les 1er et 2
septembre, la capitulation est du 2. Non vérifié sur source officielle.

### 13. Nombre de vaccins obligatoires — deux sources publiques divergent

Vaccination Info Service (Santé publique France) annonce **12**, ameli.fr
annonce **13** tout en n'en listant que 12. `V295` a retenu **12**. Si ce
chiffre doit figurer tel quel dans une explication, il faut trancher — ou
écrire la liste plutôt que le compte.

---

## Ce que la QA a mis au jour et qui dépasse ces questions

**Le ministère publie la liste officielle des questions de connaissance de
l'examen 2026**, par mention, sur `formation-civique.interieur.gouv.fr`. Les
bonnes réponses n'y figurent pas, mais **les intitulés officiels si** — c'est le
référentiel contre lequel ce corpus devrait être aligné, et il est gratuit.
C'est probablement le chantier suivant le plus rentable.
