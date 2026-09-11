# Revue 3 — échantillon de 100 suggestions à 0,90 et plus

Campagne complète `PROMPT_TAG_NOTION_v4`, 624 questions dans cette tranche. Cet échantillon sert à **décider si une validation en masse est tenable** — il ne la précède pas, il la conditionne.

> 🛑 **Le modèle PROPOSE, il n'applique rien.** Aucune de ces suggestions n'a touché `civic_notion_id` — 48 questions sont taguées dans tout le dépôt, et toutes l'ont été par un geste humain.

Stratifié sur les 5 thèmes × 2 tranches de confiance, avec un tourniquet sur les notions à l'intérieur de chaque cellule : sans lui, une cellule dominée par une grosse notion ne mesurerait qu'elle.

| Thème | Tranche | Dans la campagne | Dans l'échantillon |
|---|---|---:|---:|
| Droits et devoirs | 0,90–0,94 | 36 | 5 |
| Droits et devoirs | ≥ 0,95 | 60 | 10 |
| Histoire, géo et culture | 0,90–0,94 | 28 | 4 |
| Histoire, géo et culture | ≥ 0,95 | 154 | 25 |
| Institutions | 0,90–0,94 | 58 | 9 |
| Institutions | ≥ 0,95 | 103 | 17 |
| Principes et valeurs | 0,90–0,94 | 23 | 4 |
| Principes et valeurs | ≥ 0,95 | 31 | 5 |
| Vivre en société | 0,90–0,94 | 42 | 7 |
| Vivre en société | ≥ 0,95 | 89 | 14 |

**Total : 100 questions**, aucune déjà relue.

### 1. Doit-on dire la vérité quand on est témoin devant la justice ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Oui, le faux témoignage est puni ← **bonne réponse**
- Non, on peut mentir
- Uniquement les adultes doivent dire vrai
- Uniquement les écrits sont obligatoires

**Explication de la question** — Oui. Le faux témoignage devant une juridiction est un délit puni par la loi. Tout témoin doit dire la vérité sous serment.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.90**
> Devoir de dire la vérité comme témoin.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 2. L'école publique est-elle payante en France ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Non, elle est gratuite (depuis 1881) ← **bonne réponse**
- Oui, l'inscription coûte cher
- Uniquement le lycée est gratuit
- Uniquement les enfants pauvres

**Explication de la question** — Non. L'école publique est gratuite. La gratuité a été instaurée en 1881 par les lois Jules Ferry.

**Proposition du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.90**
> Gratuité de l'école, droit social explicitement listé.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 3. L'esclavage est-il considéré comme un crime contre l'humanité en droit français ?

*Droits et devoirs · Carte de résident*

- Oui, depuis la loi Taubira de 2001 ← **bonne réponse**
- Non, c'est un simple délit
- Uniquement en outre-mer
- Uniquement pour le 19e siècle

**Explication de la question** — Oui. La loi Taubira de 2001 reconnaît la traite négrière et l'esclavage comme crimes contre l'humanité. Le 10 mai est journée nationale de commémoration.

**Proposition du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.90**
> Crime contre l'humanité, imprescriptibilité, esclavage - notion de principe.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 4. Le racisme est-il puni par la loi française ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Oui, c'est un délit puni par la loi ← **bonne réponse**
- Non, c'est une opinion protégée
- Uniquement en public
- Uniquement sur internet

**Explication de la question** — Oui. Les actes et propos racistes (injures, discriminations, provocation à la haine) sont des délits punis par la loi (loi du 29 juillet 1881 sur la liberté de la presse).

**Proposition du modèle — `dd_interdits_quotidien`** (Ce qui est interdit au quotidien, et ce qu'on risque) · confiance **0.90**
> Propos et actes racistes comme interdit concret sanctionné.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 5. Quel article de la CEDH protège le droit à un procès équitable ?

*Droits et devoirs · Naturalisation*

- L'article 6 ← **bonne réponse**
- L'article 1er
- L'article 12
- L'article 30

**Explication de la question** — L'article 6 de la CEDH garantit le droit à un procès équitable : tribunal indépendant et impartial, jugement public dans un délai raisonnable, présomption d'innocence, droits de la défense.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.90**
> Procès équitable, droit procédural opposable.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 6. Doit-on payer ses impôts en France ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Oui, c'est un devoir civique ← **bonne réponse**
- Non, c'est facultatif
- Uniquement les riches
- Uniquement les fonctionnaires

**Explication de la question** — Oui. Payer ses impôts est une obligation civique. C'est inscrit dans la Déclaration de 1789 (article 13) : la contribution commune est indispensable au fonctionnement de l'État.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.95**
> Obligation individuelle de payer ses impôts.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 7. Combien d'heures peut-on travailler maximum par semaine en France ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- 35 heures légales, 48 heures maximum absolu ← **bonne réponse**
- 20 heures maximum
- 60 heures légales
- Aucune limite

**Explication de la question** — La durée légale du travail est de 35 heures par semaine. Au-delà, ce sont des heures supplémentaires (majorées). Le plafond absolu est de 48 heures hebdomadaires.

**Proposition du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.95**
> Durée légale du travail, droit social explicitement listé.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 8. La peine de mort est :

*Droits et devoirs · Carte de résident*

- Abolie en France depuis 1981 ← **bonne réponse**
- En vigueur pour les crimes graves
- Appliquée uniquement dans certaines régions
- Prévue par la Constitution actuelle

**Explication de la question** — La peine de mort a été abolie en France le 9 octobre 1981 par la loi Badinter. Son abolition est inscrite dans la Constitution depuis 2007.

**Proposition du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.95**
> Abolition de la peine de mort est un principe pénal fondamental.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 9. A-t-on le droit de fumer dans les lieux publics fermés en France ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Non, c'est interdit depuis 2008 ← **bonne réponse**
- Oui, partout
- Uniquement le soir
- Uniquement les hommes

**Explication de la question** — Non. Depuis 2008, il est interdit de fumer dans tous les lieux publics fermés (restaurants, bars, transports, bureaux). Des espaces extérieurs peuvent être aménagés.

**Proposition du modèle — `dd_interdits_quotidien`** (Ce qui est interdit au quotidien, et ce qu'on risque) · confiance **0.95**
> Interdiction concrète de fumer dans les lieux publics.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 10. Concernant les droits individuels, quelle affirmation est exacte ?

*Droits et devoirs · Carte de résident*

- Ils sont reconnus à tous, dans les limites posées par la loi ← **bonne réponse**
- Ils n'existent pas en France
- Ils sont réservés aux Français
- Ils sont absolus, sans aucune limite

**Explication de la question** — Les droits individuels (liberté, sûreté, propriété) sont reconnus à toute personne en France. Ils peuvent être limités par la loi pour protéger l'ordre public et les droits d'autrui.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.95**
> Droits individuels (liberté, sûreté, propriété) avec limites légales.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 11. L'aide juridictionnelle existe-t-elle pour les justiciables modestes ?

*Droits et devoirs · Carte de résident*

- Oui, sous conditions de ressources ← **bonne réponse**
- Non, c'est payé par tous
- Uniquement pour les retraités
- Uniquement pour les Français

**Explication de la question** — Oui. L'aide juridictionnelle, totale ou partielle, est accordée aux personnes dont les revenus ne dépassent pas un certain plafond. Elle permet de payer les frais d'avocat et de procès.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.95**
> Aide juridictionnelle, accès à la justice pour les justiciables modestes.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 12. Comment la France peut-elle être condamnée par la Cour européenne des droits de l'homme ?

*Droits et devoirs · Naturalisation*

- Sur recours individuel après épuisement des recours internes ← **bonne réponse**
- Automatiquement chaque année
- Par décision du Parlement européen
- Jamais

**Explication de la question** — Sur recours individuel d'une personne ayant épuisé ses voies de recours internes, la CEDH peut déclarer que la France a violé la Convention. La France doit alors modifier sa pratique et indemniser le requérant.

**Proposition du modèle — `dd_protection_europeenne`** (Les droits protégés au-delà de la France : CEDH, Union européenne) · confiance **0.95**
> Saisine de la CEDH après épuisement des recours internes.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 13. En quelle année la Déclaration des droits de l'homme et du citoyen a-t-elle été adoptée ?

*Droits et devoirs · Carte de résident*

- 1789 ← **bonne réponse**
- 1789 (année de la Révolution française)
- 1804
- 1848

**Explication de la question** — La Déclaration des droits de l'homme et du citoyen a été adoptée le 26 août 1789, pendant la Révolution française.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.97**
> Date d'adoption de la DDHC, texte fondateur.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 14. Filmer ou photographier une personne sans son accord est-il autorisé ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Non, le droit à l'image protège chacun ← **bonne réponse**
- Oui, sans condition
- Oui, dans la rue uniquement
- Oui, si la personne est connue

**Explication de la question** — Non, en général. Toute personne a droit à son image. Diffuser ou utiliser l'image de quelqu'un sans son accord est une atteinte à la vie privée, punie par la loi.

**Proposition du modèle — `dd_vie_privee_famille`** (Vie privée, image, données personnelles et vie de famille) · confiance **0.95**
> Droit à l'image, protection de la vie privée.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 15. Doit-on respecter les consignes de tri des déchets ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Oui, c'est une obligation civique et légale ← **bonne réponse**
- Non, c'est facultatif
- Uniquement les week-ends
- Uniquement le verre

**Explication de la question** — Oui. Le tri sélectif est obligatoire dans la plupart des communes. Ne pas respecter le tri ou déposer des déchets hors des bacs prévus est une infraction passible d'amende.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.95**
> Devoir de tri des déchets, cité explicitement dans la frontière.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 16. Quel célèbre cuisinier français a popularisé la gastronomie au XXe siècle ?

*Histoire, géo et culture · Carte de résident*

- Paul Bocuse ← **bonne réponse**
- Gustave Eiffel
- Marie Curie
- Charles de Gaulle

**Explication de la question** — Paul Bocuse (1926-2018), surnommé 'le pape de la gastronomie', était l'un des chefs les plus influents du XXe siècle. Il a reçu de nombreuses étoiles Michelin et a formé des générations de cuisiniers.

**Proposition du modèle — `hg_art_de_vivre`** (Gastronomie, sport et art de vivre) · confiance **0.90**
> Paul Bocuse, figure de la gastronomie française.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 17. Qui était Louis Braille ?

*Histoire, géo et culture · Carte de résident*

- L'inventeur de l'écriture en relief pour les aveugles ← **bonne réponse**
- Un peintre
- Un compositeur
- Un explorateur

**Explication de la question** — Louis Braille (1809-1852), français devenu aveugle après un accident, a inventé vers 1825 le système d'écriture en relief portant son nom, utilisé par les aveugles dans le monde entier.

**Proposition du modèle — `hg_arts_sciences`** (Artistes et savants français) · confiance **0.90**
> Louis Braille, inventeur/savant français.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 18. Que célèbre-t-on le 14 juillet ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- La fête nationale (prise de la Bastille 1789) ← **bonne réponse**
- La fin de la Seconde Guerre mondiale
- La fête des Mères
- L'anniversaire du président

**Explication de la question** — Le 14 juillet, fête nationale, commémore la prise de la Bastille (14 juillet 1789), symbole de la Révolution française.

**Proposition du modèle — `hg_fetes_jours_feries`** (Fêtes et jours fériés en France) · confiance **0.90**
> Ce que célèbre le 14 juillet, question sur le jour férié.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 19. Qu'est-ce que Paris ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- La capitale de la France ← **bonne réponse**
- Une région
- Un fleuve
- Un département d'outre-mer

**Explication de la question** — Paris est la capitale de la France, la ville la plus peuplée du pays (environ 2,1 millions d'habitants intra-muros, plus de 12 millions pour l'aire urbaine).

**Proposition du modèle — `hg_geographie`** (Géographie de la France et outre-mer) · confiance **0.90**
> Statut de Paris comme capitale, situer sur la carte.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 20. Comment appelle-t-on en France un pain long et croustillant typique ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- La baguette ← **bonne réponse**
- La galette
- Le bagel
- Le pain de mie

**Explication de la question** — La baguette est le pain emblématique de la France. Inscrite au patrimoine culturel immatériel de l'UNESCO en 2022.

**Proposition du modèle — `hg_art_de_vivre`** (Gastronomie, sport et art de vivre) · confiance **0.95**
> Baguette, produit alimentaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 21. Laquelle de ces personnes a été une chanteuse française célèbre ?

*Histoire, géo et culture · Carte de résident*

- Édith Piaf ← **bonne réponse**
- Marie Curie
- Jeanne d'Arc
- Simone Veil

**Explication de la question** — Plusieurs chanteuses françaises célèbres : Édith Piaf, Dalida, Mireille Mathieu, Barbara, Catherine Deneuve, Vanessa Paradis, Mylène Farmer, Patricia Kaas.

**Proposition du modèle — `hg_arts_sciences`** (Artistes et savants français) · confiance **0.96**
> Chanteuse française célèbre.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 22. Depuis quelle année l'école publique est-elle gratuite ?

*Histoire, géo et culture · Naturalisation*

- 1881 ← **bonne réponse**
- 1789
- 1905
- 1968

**Explication de la question** — L'école publique est gratuite depuis 1881, grâce à la loi Jules Ferry. L'instruction est devenue obligatoire et laïque en 1882.

**Proposition du modèle — `hg_conquetes_droits`** (Les conquêtes sociales et les transformations de la société) · confiance **0.97**
> École gratuite = droit acquis.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 23. En quelle année a été créée la Communauté Économique Européenne (CEE) ?

*Histoire, géo et culture · Naturalisation*

- 1957 ← **bonne réponse**
- 1945
- 1989
- 2002

**Explication de la question** — La CEE a été créée en 1957 par le traité de Rome, signé par 6 pays fondateurs : France, Allemagne, Italie, Belgique, Pays-Bas, Luxembourg. Elle est devenue l'Union européenne en 1993.

**Proposition du modèle — `hg_europe`** (La construction européenne) · confiance **0.95**
> Création de la CEE, traité de Rome.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 24. Quand célèbre-t-on Noël ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Le 25 décembre ← **bonne réponse**
- Le 1er janvier
- Le 31 octobre
- Le 14 février

**Explication de la question** — Noël est célébré le 25 décembre. C'est une fête chrétienne, mais aussi un jour férié en France et une fête familiale célébrée par beaucoup de Français quelle que soit leur religion.

**Proposition du modèle — `hg_fetes_jours_feries`** (Fêtes et jours fériés en France) · confiance **0.97**
> Date de Noël

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 25. Combien de régions compte la France métropolitaine depuis 2016 ?

*Histoire, géo et culture · Naturalisation*

- 13 régions ← **bonne réponse**
- 22 régions
- 10 régions
- 27 régions

**Explication de la question** — Depuis la réforme territoriale de 2016, la France métropolitaine compte 13 régions (contre 22 auparavant). S'ajoutent les régions d'outre-mer.

**Proposition du modèle — `hg_geographie`** (Géographie de la France et outre-mer) · confiance **0.97**
> Découpage régional de la France.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 26. Comment s'appelait l'État français pendant la Seconde Guerre mondiale, dirigé par Pétain ?

*Histoire, géo et culture · Carte de résident*

- Le régime de Vichy ← **bonne réponse**
- La IIIe République
- La France libre
- L'Empire napoléonien

**Explication de la question** — Le régime de Vichy (1940-1944), dirigé par le maréchal Philippe Pétain, a collaboré avec l'Allemagne nazie. Sa devise était 'Travail, Famille, Patrie'.

**Proposition du modèle — `hg_guerres_resistance`** (Les guerres du XXᵉ siècle et la décolonisation) · confiance **0.95**
> Régime de Vichy pendant la Seconde Guerre mondiale.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 27. Lequel de ces écrivains est français ?

*Histoire, géo et culture · Carte de résident*

- Victor Hugo ← **bonne réponse**
- William Shakespeare
- Goethe
- Cervantes

**Explication de la question** — Parmi les grands écrivains français : Victor Hugo, Émile Zola, Marcel Proust, Albert Camus, Simone de Beauvoir, Antoine de Saint-Exupéry, Marguerite Duras.

**Proposition du modèle — `hg_litterature`** (Les grands écrivains français) · confiance **0.97**
> Reconnaître un écrivain français.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 28. Que désigne le 'Second Empire' français ?

*Histoire, géo et culture · Naturalisation*

- Le régime de Napoléon III (1852-1870) ← **bonne réponse**
- Le règne de Louis XIV
- La Restauration
- Le régime de Vichy

**Explication de la question** — Le Second Empire (1852-1870) fut le régime de Napoléon III (Louis-Napoléon Bonaparte, neveu de Napoléon Ier). Il a transformé Paris (travaux Haussmann) avant de tomber à Sedan en 1870.

**Proposition du modèle — `hg_napoleon_xixe`** (Napoléon et la France au XIXᵉ siècle) · confiance **0.97**
> Second Empire de Napoléon III, régime non républicain du XIXe.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 29. Dans quelle ville française se trouve la tour Eiffel ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- À Paris ← **bonne réponse**
- À Lyon
- À Marseille
- À Bordeaux

**Explication de la question** — La tour Eiffel se trouve à Paris. Construite par Gustave Eiffel pour l'Exposition universelle de 1889, elle est l'un des monuments les plus visités au monde.

**Proposition du modèle — `hg_patrimoine`** (Monuments et sites emblématiques) · confiance **0.96**
> Monument bâti et sa localisation.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 30. Combien de républiques la France a-t-elle connues à ce jour ?

*Histoire, géo et culture · Carte de résident*

- Cinq républiques ← **bonne réponse**
- Trois républiques
- Sept républiques
- Une seule

**Explication de la question** — La France a connu 5 républiques : Ire (1792-1804), IIe (1848-1852), IIIe (1870-1940), IVe (1946-1958) et Ve (depuis 1958).

**Proposition du modèle — `hg_republiques`** (Les cinq républiques) · confiance **0.97**
> Décompte des cinq républiques.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 31. En quelle année a commencé la Révolution française ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- 1789 ← **bonne réponse**
- 1815
- 1870
- 1958

**Explication de la question** — La Révolution française a commencé en 1789, marquée par la prise de la Bastille le 14 juillet 1789 et la Déclaration des droits de l'homme et du citoyen le 26 août 1789.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.97**
> Début de la Révolution française

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 32. Quel fromage français est produit en Normandie ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Le camembert ← **bonne réponse**
- Le parmesan
- Le cheddar
- La feta

**Explication de la question** — Le camembert est un fromage normand emblématique, fabriqué à base de lait de vache. La Normandie produit aussi le livarot, le pont-l'évêque, le neufchâtel.

**Proposition du modèle — `hg_art_de_vivre`** (Gastronomie, sport et art de vivre) · confiance **0.95**
> Fromage régional, produit culinaire français.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 33. Quel chien français est associé à Louis Pasteur ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Le chien vacciné contre la rage (Pasteur, 1885) ← **bonne réponse**
- Le berger allemand
- Le caniche royal
- Aucun chien spécifique

**Explication de la question** — Louis Pasteur (1822-1895), chimiste et biologiste français, a inventé le vaccin contre la rage en 1885. Il a aussi mis au point la pasteurisation.

**Proposition du modèle — `hg_arts_sciences`** (Artistes et savants français) · confiance **0.95**
> Pasteur, savant français.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 34. Depuis quelle année l'école publique est-elle gratuite en France ?

*Histoire, géo et culture · Naturalisation*

- 1881 (loi Ferry) ← **bonne réponse**
- 1789
- 1905
- 1958

**Explication de la question** — L'école publique est gratuite en France depuis 1881 (loi Ferry du 16 juin 1881). L'obligation et la laïcité ont suivi en 1882.

**Proposition du modèle — `hg_conquetes_droits`** (Les conquêtes sociales et les transformations de la société) · confiance **0.95**
> Gratuité de l'école, droit acquis (loi Ferry 1881).

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 35. En quelle année a été créée la Communauté économique européenne (CEE) ?

*Histoire, géo et culture · Naturalisation*

- 1957 (traité de Rome) ← **bonne réponse**
- 1945
- 1968
- 1992

**Explication de la question** — La CEE a été créée en 1957 par le traité de Rome, signé par 6 pays fondateurs (France, Allemagne, Italie, Belgique, Pays-Bas, Luxembourg).

**Proposition du modèle — `hg_europe`** (La construction européenne) · confiance **0.97**
> Création de la CEE, traité de Rome.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 36. Quand célèbre-t-on Noël en France ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Le 25 décembre ← **bonne réponse**
- Le 1er janvier
- Le 14 juillet
- Le 11 novembre

**Explication de la question** — Noël est célébré le 25 décembre. C'est une fête chrétienne célébrant la naissance de Jésus, devenue aussi une fête populaire et familiale en France.

**Proposition du modèle — `hg_fetes_jours_feries`** (Fêtes et jours fériés en France) · confiance **0.97**
> Date de la fête de Noël.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 37. Combien la France a-t-elle de côtes maritimes (en simplifié) ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Trois grandes façades maritimes ← **bonne réponse**
- Aucune
- Une seule
- Dix différentes

**Explication de la question** — La France a trois façades maritimes : mer du Nord/Manche au nord, océan Atlantique à l'ouest, mer Méditerranée au sud, plus les outre-mer.

**Proposition du modèle — `hg_geographie`** (Géographie de la France et outre-mer) · confiance **0.96**
> Façades maritimes de la France.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 38. Comment s'appelait le mouvement de Charles de Gaulle pendant la Seconde Guerre mondiale ?

*Histoire, géo et culture · Carte de résident*

- La France libre ← **bonne réponse**
- Le Front populaire
- La Commune
- La Sainte Alliance

**Explication de la question** — La France libre (puis France combattante) fut le mouvement de résistance fondé par Charles de Gaulle depuis Londres après l'appel du 18 juin 1940.

**Proposition du modèle — `hg_guerres_resistance`** (Les guerres du XXᵉ siècle et la décolonisation) · confiance **0.95**
> La France libre de De Gaulle, mouvement de Résistance.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 39. Quel écrivain a écrit 'À la recherche du temps perdu' ?

*Histoire, géo et culture · Carte de résident*

- Marcel Proust ← **bonne réponse**
- Victor Hugo
- Émile Zola
- Albert Camus

**Explication de la question** — Marcel Proust (1871-1922) a écrit 'À la recherche du temps perdu', vaste roman en 7 volumes publié entre 1913 et 1927, considéré comme une œuvre majeure de la littérature mondiale.

**Proposition du modèle — `hg_litterature`** (Les grands écrivains français) · confiance **0.98**
> Marcel Proust, écrivain.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 40. Quel coup d'État a porté Napoléon Bonaparte au pouvoir ?

*Histoire, géo et culture · Naturalisation*

- Le coup d'État du 18 brumaire (1799) ← **bonne réponse**
- La prise de la Bastille
- La nuit du 4 août
- La révolution de 1848

**Explication de la question** — Le coup d'État du 18 brumaire an VIII (9 novembre 1799) a porté Napoléon Bonaparte au pouvoir. Il a mis fin au Directoire et installé le Consulat, prélude à l'Empire (1804).

**Proposition du modèle — `hg_napoleon_xixe`** (Napoléon et la France au XIXᵉ siècle) · confiance **0.97**
> 18 brumaire, prise de pouvoir de Bonaparte, ferme la Révolution.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 41. Dans quelle ville se trouve la tour Eiffel ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Paris ← **bonne réponse**
- Lyon
- Marseille
- Bordeaux

**Explication de la question** — La tour Eiffel se trouve à Paris, sur le Champ-de-Mars. Construite par Gustave Eiffel pour l'Exposition universelle de 1889.

**Proposition du modèle — `hg_patrimoine`** (Monuments et sites emblématiques) · confiance **0.97**
> Monument tour Eiffel

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 42. Combien y a-t-il eu de républiques en France ?

*Histoire, géo et culture · Carte de résident*

- 5 républiques ← **bonne réponse**
- 3 républiques
- 1 seule république
- 10 républiques

**Explication de la question** — La France a connu cinq républiques : Ire (1792), IIe (1848), IIIe (1870), IVe (1946), Ve (1958, actuelle).

**Proposition du modèle — `hg_republiques`** (Les cinq républiques) · confiance **0.97**
> Décompte des républiques.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 43. En quelle année a débuté la Révolution française ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- 1789 ← **bonne réponse**
- 1689
- 1848
- 1914

**Explication de la question** — La Révolution française débute en 1789. La prise de la Bastille a lieu le 14 juillet 1789.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.97**
> Date de début de la Révolution française.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 44. Quel produit alimentaire est emblématique de la France ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- La baguette de pain ← **bonne réponse**
- Le riz blanc
- Le hamburger
- Le sushi

**Explication de la question** — Plusieurs produits sont emblématiques de la cuisine française : la baguette de pain, le fromage (camembert, brie, roquefort), le vin, le foie gras, les croissants.

**Proposition du modèle — `hg_art_de_vivre`** (Gastronomie, sport et art de vivre) · confiance **0.95**
> Baguette, produit alimentaire emblématique.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 45. Combien la France compte-t-elle de départements (métropole et outre-mer) ?

*Institutions · Naturalisation*

- 101 ← **bonne réponse**
- 50
- 500
- 13

**Explication de la question** — La France compte 101 départements : 96 en métropole (avec la Corse divisée en deux) et 5 départements d'outre-mer (Guadeloupe, Martinique, Guyane, La Réunion, Mayotte).

**Proposition du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.90**
> Nombre de départements, échelon territorial.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 46. En quoi consiste le 'contrôle a posteriori' des lois ?

*Institutions · Naturalisation*

- Contestation d'une loi en vigueur via QPC (2008) ← **bonne réponse**
- Réécriture spontanée d'une loi
- Vérification annuelle par l'ONU
- Sondage des citoyens

**Explication de la question** — Le contrôle a posteriori, par voie de Question prioritaire de constitutionnalité (QPC), permet de contester une loi déjà en vigueur si elle porte atteinte aux droits constitutionnels. Créé en 2008.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.90**
> QPC, contrôle a posteriori du Conseil constitutionnel.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 47. En général, qui a le droit de voter aux élections nationales françaises ?

*Institutions · Carte de résident*

- Les citoyens français majeurs avec droits civiques ← **bonne réponse**
- Tous les habitants, français ou non
- Uniquement les contribuables
- Uniquement les hommes

**Explication de la question** — Seuls les citoyens français majeurs jouissant de leurs droits civiques peuvent voter aux élections nationales. Les ressortissants européens peuvent voter aux municipales et européennes.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.90**
> Qui a le droit de vote.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 48. Quelle est la différence entre un décret et une loi ?

*Institutions · Naturalisation*

- La loi est votée par le Parlement, le décret est pris par l'exécutif ← **bonne réponse**
- Aucune différence
- Le décret est supérieur à la loi
- La loi est religieuse, le décret est civil

**Explication de la question** — La loi est votée par le Parlement, le décret est pris par le pouvoir exécutif (président ou Premier ministre). Les décrets précisent l'application des lois ou interviennent dans le domaine réglementaire.

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.90**
> Décret = acte de l'exécutif.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 49. Combien de députés composent l'Assemblée nationale ?

*Institutions · Naturalisation*

- 577 députés ← **bonne réponse**
- 348 députés
- 500 députés
- 1000 députés

**Explication de la question** — L'Assemblée nationale compte 577 députés, élus pour 5 ans au suffrage universel direct, chacun dans une circonscription.

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.90**
> Effectif de l'Assemblée nationale, caractéristique de l'institution.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 50. Comment s'appelle l'organe qui juge le président en cas de manquement grave à ses devoirs ?

*Institutions · Naturalisation*

- La Haute Cour ← **bonne réponse**
- La Cour de cassation
- Le tribunal de Paris
- Le conseil municipal

**Explication de la question** — La Haute Cour, composée des membres du Parlement (Assemblée + Sénat), peut destituer le président en cas de manquement incompatible avec l'exercice du mandat (article 68).

**Proposition du modèle — `inst_president`** (Le président de la République) · confiance **0.90**
> Haute Cour juge le président, relève de ses limites institutionnelles.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 51. Avec une carte d'identité française, peut-on voyager librement dans l'Union européenne ?

*Institutions · Carte de séjour pluriannuelle*

- Oui, dans la majorité des pays européens ← **bonne réponse**
- Non, il faut toujours un passeport
- Uniquement le visa diplomatique
- Uniquement avec un guide officiel

**Explication de la question** — Oui. La libre circulation dans l'espace Schengen et l'Union européenne permet aux citoyens français de voyager avec une simple carte d'identité dans la plupart des pays européens.

**Proposition du modèle — `inst_ue`** (L'Union européenne) · confiance **0.90**
> Libre circulation, Schengen.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 52. Combien y a-t-il de départements en France ?

*Institutions · Naturalisation*

- 101 départements (96 en métropole, 5 outre-mer) ← **bonne réponse**
- 50
- 83
- 120

**Explication de la question** — La France compte 101 départements : 96 en métropole et 5 outre-mer (Guadeloupe, Martinique, Guyane, La Réunion, Mayotte).

**Proposition du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.90**
> Nombre de départements, échelon territorial.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 53. Est-ce que le président de la République a tous les pouvoirs ?

*Institutions · Carte de résident*

- Non, les pouvoirs sont séparés ← **bonne réponse**
- Oui, il décide de tout
- Oui, il peut modifier seul la Constitution
- Oui, sauf en cas de guerre

**Explication de la question** — Non. Les pouvoirs sont séparés : le président partage le pouvoir exécutif avec le gouvernement, le Parlement vote les lois, et la justice est indépendante.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.90**
> Séparation des pouvoirs, principe constitutionnel.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 54. Combien de régions compte la France métropolitaine depuis 2016 ?

*Institutions · Carte de résident*

- 13 régions ← **bonne réponse**
- 22 régions
- 5 régions
- 95 régions

**Explication de la question** — Depuis 2016, la France métropolitaine compte 13 régions (contre 22 auparavant), suite à la réforme territoriale.

**Proposition du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.95**
> Nombre de régions françaises depuis 2016.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 55. Combien de membres compte le Conseil constitutionnel ?

*Institutions · Naturalisation*

- 9 membres nommés (plus les anciens présidents de droit) ← **bonne réponse**
- 27 membres élus
- 100 membres
- 1 seul juge

**Explication de la question** — Le Conseil constitutionnel compte 9 membres nommés (3 par le président, 3 par le président de l'Assemblée, 3 par le président du Sénat), plus les anciens présidents de la République de droit.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.96**
> Composition du Conseil constitutionnel.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 56. Que signifie "suffrage universel" ?

*Institutions · Naturalisation*

- Tous les citoyens majeurs ont le droit de vote ← **bonne réponse**
- Le vote est obligatoire pour tous
- Seuls les hommes peuvent voter
- Le vote des étrangers est autorisé

**Explication de la question** — Le suffrage universel signifie que tous les citoyens majeurs ont le droit de voter, sans condition de fortune, de sexe ou d'éducation. En France : universel masculin en 1848, étendu aux femmes en 1944.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.95**
> Définition du suffrage universel, encadrement du vote.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 57. Comment appelle-t-on l'ensemble formé par le Premier ministre et les ministres ?

*Institutions · Carte de séjour pluriannuelle*

- Le gouvernement ← **bonne réponse**
- Le Parlement
- Le Sénat
- La justice

**Explication de la question** — Le Premier ministre et les ministres forment ensemble le gouvernement, qui dirige l'administration de l'État.

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.97**
> Composition du gouvernement : Premier ministre et ministres.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 58. L'autorité judiciaire est exercée par :

*Institutions · Carte de résident*

- Les juges et les magistrats ← **bonne réponse**
- Les députés et sénateurs
- Les ministres
- Le président seul

**Explication de la question** — L'autorité judiciaire est exercée par les juges et magistrats, dans les tribunaux. Ils sont indépendants des pouvoirs exécutif et législatif.

**Proposition du modèle — `inst_justice`** (La justice, les tribunaux et les magistrats) · confiance **0.95**
> Magistrats et juges exercent l'autorité judiciaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 59. Combien y a-t-il de sénateurs en France ?

*Institutions · Carte de résident*

- 348 sénateurs ← **bonne réponse**
- 577 sénateurs
- 100 sénateurs
- 50 sénateurs

**Explication de la question** — Le Sénat français compte 348 sénateurs, élus pour 6 ans au suffrage universel indirect.

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.97**
> Effectif du Sénat, fait partie du référentiel bicamérisme.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 60. Combien de fois l'article 16 de la Constitution a-t-il été utilisé depuis 1958 ?

*Institutions · Naturalisation*

- Une seule fois (en 1961) ← **bonne réponse**
- Jamais
- Dix fois
- À chaque crise

**Explication de la question** — L'article 16 (pouvoirs exceptionnels) n'a été appliqué qu'une seule fois, par Charles de Gaulle du 23 avril au 29 septembre 1961, lors du putsch des généraux à Alger.

**Proposition du modèle — `inst_president`** (Le président de la République) · confiance **0.95**
> Usage historique de l'article 16 par le président.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 61. Au 1er janvier 2025, combien d'États membres compte l'Union européenne ?

*Institutions · Naturalisation*

- 27 ← **bonne réponse**
- 15
- 50
- 12

**Explication de la question** — Au 1er janvier 2025, l'Union européenne compte 27 États membres. Le Royaume-Uni en est sorti en 2020 (Brexit).

**Proposition du modèle — `inst_ue`** (L'Union européenne) · confiance **0.97**
> Nombre d'États membres de l'UE.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 62. Comment appelle-t-on les bâtiments où se réunissent les conseillers municipaux ?

*Institutions · Carte de séjour pluriannuelle*

- La mairie (ou hôtel de ville) ← **bonne réponse**
- La cathédrale
- Le stade municipal
- Le bureau de poste

**Explication de la question** — Les conseils municipaux se réunissent dans la mairie (ou hôtel de ville pour les grandes communes), siège officiel de la commune.

**Proposition du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.95**
> Mairie, conseil municipal, commune.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 63. Comment s'appelle la Constitution actuelle de la France ?

*Institutions · Carte de résident*

- La Constitution de la Ve République ← **bonne réponse**
- La Constitution de 1789
- La Constitution européenne
- La Constitution de l'Empire

**Explication de la question** — La Constitution actuelle est celle de la Ve République, adoptée le 4 octobre 1958.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.95**
> Nom de la Constitution actuelle.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 64. Quel âge permet d'être électeur en France ?

*Institutions · Naturalisation*

- 18 ans (avec conditions de nationalité et d'inscription) ← **bonne réponse**
- 16 ans
- 21 ans
- 25 ans

**Explication de la question** — Il faut avoir 18 ans (majorité civique) pour pouvoir voter en France, sous condition d'être français (sauf élections européennes/municipales pour les ressortissants UE) et inscrit sur les listes électorales.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.95**
> Âge et conditions pour être électeur.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 65. Comment appelle-t-on la résidence officielle du Premier ministre ?

*Institutions · Carte de séjour pluriannuelle*

- Matignon ← **bonne réponse**
- L'Élysée
- Le Louvre
- Versailles

**Explication de la question** — La résidence officielle du Premier ministre est l'hôtel Matignon. On parle souvent de "Matignon" pour désigner le Premier ministre et ses services.

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.95**
> Matignon = résidence du Premier ministre, gouvernement.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 66. Qu'est-ce que l'ordre administratif distingue de l'ordre judiciaire ?

*Institutions · Naturalisation*

- L'ordre administratif juge les litiges avec l'administration ← **bonne réponse**
- Aucune distinction
- L'ordre administratif juge les crimes
- L'ordre administratif est européen

**Explication de la question** — L'ordre administratif (Conseil d'État, tribunaux administratifs) juge les litiges impliquant l'administration. L'ordre judiciaire juge les litiges entre particuliers et les affaires pénales.

**Proposition du modèle — `inst_justice`** (La justice, les tribunaux et les magistrats) · confiance **0.95**
> Ordre administratif vs judiciaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 67. En cas de désaccord persistant entre Assemblée nationale et Sénat, qui tranche ?

*Institutions · Carte de résident*

- L'Assemblée nationale ← **bonne réponse**
- Le Sénat
- Le président seul
- Le Conseil constitutionnel

**Explication de la question** — L'Assemblée nationale a le dernier mot en cas de désaccord persistant. Cette procédure est prévue par la Constitution.

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.95**
> Navette et dernier mot de l'Assemblée, travail parlementaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 68. Combien faut-il de parrainages d'élus pour être candidat à la présidentielle ?

*Institutions · Carte de résident*

- 500 parrainages d'élus ← **bonne réponse**
- 100 parrainages
- 5 000 parrainages
- Aucun parrainage requis

**Explication de la question** — Il faut 500 parrainages d'élus (maires, députés, sénateurs, conseillers régionaux/départementaux) d'au moins 30 départements différents.

**Proposition du modèle — `inst_president`** (Le président de la République) · confiance **0.95**
> Parrainages requis pour candidature présidentielle.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 69. Combien d'États font partie de l'Union européenne au 1er janvier 2025 ?

*Institutions · Naturalisation*

- 27 États ← **bonne réponse**
- 15 États
- 28 États
- 50 États

**Explication de la question** — L'Union européenne compte 27 États membres depuis le retrait du Royaume-Uni (Brexit) en 2020.

**Proposition du modèle — `inst_ue`** (L'Union européenne) · confiance **0.95**
> Nombre d'États membres de l'UE.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 70. Comment appelle-t-on les regroupements de communes pour gérer ensemble certains services ?

*Institutions · Carte de résident*

- Les intercommunalités ← **bonne réponse**
- Les paroisses
- Les cantons
- Les districts religieux

**Explication de la question** — Les intercommunalités (communautés de communes, d'agglomération, urbaines, métropoles) mutualisent des services (transports, déchets, urbanisme).

**Proposition du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.95**
> Intercommunalités liées à la commune.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 71. Le principe d'égalité signifie que :

*Principes et valeurs · Carte de résident*

- La loi est la même pour tous, sans discrimination ← **bonne réponse**
- Tout le monde doit posséder les mêmes biens
- Les hommes et les femmes ont des rôles différents
- Les Français ont plus de droits que les étrangers

**Explication de la question** — Le principe d'égalité garantit que la loi s'applique de la même manière à tous, sans discrimination liée à l'origine, au sexe, à la religion ou aux opinions.

**Proposition du modèle — `pv_egalite_non_discrimination`** (Égalité et refus des discriminations) · confiance **0.90**
> Loi même pour tous, non-discrimination.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 72. En quelle année a été votée la loi interdisant les signes religieux ostensibles à l'école publique ?

*Principes et valeurs · Naturalisation*

- 2004 ← **bonne réponse**
- 1905
- 1989
- 2010

**Explication de la question** — La loi du 15 mars 2004 interdit le port de signes religieux ostensibles (voile, kippa, grande croix...) dans les écoles, collèges et lycées publics.

**Proposition du modèle — `pv_laicite`** (La laïcité) · confiance **0.90**
> Loi de 2004 sur signes religieux à l'école, règle de laïcité.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 73. Qu'est-ce que la Déclaration des droits de l'homme et du citoyen ?

*Principes et valeurs · Carte de résident*

- Un texte de 1789 qui proclame les droits fondamentaux ← **bonne réponse**
- Une loi récente sur l'immigration
- Un traité militaire
- Un texte religieux

**Explication de la question** — Adoptée le 26 août 1789, c'est un texte fondateur de la Révolution qui proclame les droits naturels et l'égalité des hommes. Elle a aujourd'hui valeur constitutionnelle.

**Proposition du modèle — `pv_libertes_ddhc`** (Les libertés fondamentales et la Déclaration de 1789) · confiance **0.90**
> Présentation générale de la DDHC comme texte fondateur des libertés.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 74. Dans quelles occasions La Marseillaise est-elle chantée ?

*Principes et valeurs · Carte de séjour pluriannuelle*

- Cérémonies officielles et événements sportifs internationaux ← **bonne réponse**
- Uniquement le 14 juillet
- Uniquement dans les écoles
- À la fin de chaque journal télévisé

**Explication de la question** — La Marseillaise est jouée lors des cérémonies officielles (commémorations, prises de fonction), des événements sportifs internationaux et de la fête nationale.

**Proposition du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.90**
> Occasions de chanter l'hymne national.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.00**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 75. Parmi ces critères, lequel ne peut PAS justifier un traitement défavorable selon la loi française ?

*Principes et valeurs · Carte de résident*

- L'origine de la personne ← **bonne réponse**
- L'expérience professionnelle
- Les diplômes obtenus
- Les compétences techniques

**Explication de la question** — La loi interdit toute discrimination fondée sur l'origine, le sexe, la religion, l'orientation sexuelle, l'âge, le handicap, l'état de santé, l'apparence... (plus de 20 critères).

**Proposition du modèle — `pv_egalite_non_discrimination`** (Égalité et refus des discriminations) · confiance **0.95**
> Critères de discrimination prohibés.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 76. Qu'est-ce que la laïcité ?

*Principes et valeurs · Carte de résident*

- La séparation entre l'État et les religions ← **bonne réponse**
- L'interdiction de toutes les religions
- L'obligation de pratiquer une religion
- Le respect d'une religion d'État

**Explication de la question** — La laïcité est la séparation entre l'État et les religions. L'État est neutre, ne reconnaît aucun culte et garantit la liberté de conscience de chacun.

**Proposition du modèle — `pv_laicite`** (La laïcité) · confiance **0.97**
> Définition de la séparation État/religions.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.00**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 77. Qu'est-ce qu'une République ?

*Principes et valeurs · Carte de résident*

- Un régime où le pouvoir appartient au peuple, pas à un roi ← **bonne réponse**
- Une monarchie héréditaire
- Un régime militaire
- Un État religieux

**Explication de la question** — Une République est un régime politique dans lequel le pouvoir n'appartient ni à une famille royale ni à une personne unique, mais au peuple, qui l'exerce par ses représentants élus.

**Proposition du modèle — `pv_republique_democratie`** (La République : régime, démocratie, souveraineté) · confiance **0.95**
> Définition du régime républicain et souveraineté populaire.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.00**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 78. "Liberté, égalité, fraternité", c'est :

*Principes et valeurs · Carte de séjour pluriannuelle*

- La devise de la République française ← **bonne réponse**
- Le titre de l'hymne national
- Une chanson populaire
- Une loi récente

**Explication de la question** — "Liberté, Égalité, Fraternité" est la devise officielle de la République française depuis 1880, reprise dans les Constitutions de 1946 et 1958.

**Proposition du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.97**
> Devise nommée.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 79. Qu'est-ce qu'une discrimination ?

*Principes et valeurs · Carte de résident*

- Traiter quelqu'un moins bien à cause d'un critère interdit ← **bonne réponse**
- Respecter les préférences de chacun
- Faire payer un impôt
- Inviter ses amis à une fête privée

**Explication de la question** — Une discrimination consiste à traiter une personne moins bien qu'une autre dans une situation comparable, sur la base d'un critère interdit par la loi (origine, sexe, religion, handicap, âge...).

**Proposition du modèle — `pv_egalite_non_discrimination`** (Égalité et refus des discriminations) · confiance **0.95**
> Définition générale de la discrimination.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 80. Le port du casque est-il obligatoire à vélo en France ?

*Vivre en société · Carte de séjour pluriannuelle*

- Obligatoire pour les moins de 12 ans, recommandé pour les adultes ← **bonne réponse**
- Obligatoire pour tous
- Interdit à tous
- Uniquement la nuit

**Explication de la question** — Le port du casque à vélo est obligatoire pour les enfants de moins de 12 ans (conducteur ou passager). Pour les adultes, il est seulement recommandé mais très conseillé.

**Proposition du modèle — `vs_deplacements_route`** (Se déplacer : permis, sécurité routière, transports) · confiance **0.90**
> Équipement obligatoire (casque) pour se déplacer.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 81. Que désigne la cantine scolaire en France ?

*Vivre en société · Carte de séjour pluriannuelle*

- Le service de restauration scolaire ← **bonne réponse**
- Une salle de sport
- Une bibliothèque
- Un théâtre

**Explication de la question** — La cantine scolaire est le service de restauration proposé dans les écoles. Elle est généralement gérée par la commune. Son coût est souvent ajusté selon les revenus des familles.

**Proposition du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.90**
> Cantine scolaire fait partie du système scolaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 82. Comment s'appelle le document officiel d'état civil prouvant la naissance ?

*Vivre en société · Carte de séjour pluriannuelle*

- L'acte de naissance ← **bonne réponse**
- Le permis de conduire
- Le passeport
- Le carnet de santé

**Explication de la question** — L'acte de naissance est le document officiel établi par la mairie à la déclaration de naissance. Il est ensuite nécessaire pour de nombreuses démarches (carte d'identité, passeport, mariage).

**Proposition du modèle — `vs_famille_etat_civil`** (La famille, le couple et l'état civil) · confiance **0.93**
> Acte de naissance, document d'état civil.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 83. Le voyage en avion nécessite-t-il un document d'identité ?

*Vivre en société · Carte de séjour pluriannuelle*

- Oui, pièce d'identité obligatoire ← **bonne réponse**
- Non, jamais
- Uniquement pour l'international
- Uniquement pour les hommes

**Explication de la question** — Oui. Pour tout voyage en avion (intérieur ou international), il faut présenter une pièce d'identité (carte d'identité, passeport). Pour l'international hors UE, un passeport est généralement obligatoire.

**Proposition du modèle — `vs_papiers_identite`** (Ses papiers et les guichets de l'administration) · confiance **0.90**
> Document d'identité pour voyager, entre dans papiers_identite.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 84. Qu'est-ce qu'un HLM ?

*Vivre en société · Carte de séjour pluriannuelle*

- Un logement social à loyer modéré ← **bonne réponse**
- Une grande villa
- Un hôtel
- Une boutique

**Explication de la question** — Un HLM (Habitation à loyer modéré) est un logement social, dont le loyer est plafonné et dont l'attribution est réservée aux personnes aux revenus modestes.

**Proposition du modèle — `vs_protection_sociale_aides`** (La protection sociale et les aides) · confiance **0.93**
> HLM, cité explicitement dans la frontière.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 85. Pourquoi certaines vaccinations sont-elles obligatoires en France ?

*Vivre en société · Carte de résident*

- Pour protéger l'individu et l'immunité collective ← **bonne réponse**
- Pour des raisons économiques
- Pour vendre des médicaments
- Sans raison particulière

**Explication de la question** — Les vaccinations obligatoires protègent l'individu et l'ensemble de la population (immunité collective). Depuis 2018, 11 vaccins sont obligatoires pour les nourrissons (rougeole, tétanos, etc.).

**Proposition du modèle — `vs_sante_soins`** (Se soigner : médecin, Sécu, remboursements) · confiance **0.90**
> Vaccinations obligatoires, citées explicitement.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 86. Quel niveau de français est exigé pour la carte de résident ?

*Vivre en société · Carte de résident*

- Le niveau B1 (depuis 2026) ← **bonne réponse**
- Aucun niveau requis
- Le niveau A2
- Le niveau C2

**Explication de la question** — Depuis 2026, le niveau B1 (utilisateur indépendant) est requis pour la carte de résident. Auparavant, c'était A2.

**Proposition du modèle — `vs_sejour_asile`** (Le séjour des étrangers et l'asile) · confiance **0.93**
> Niveau de français pour carte de résident.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 87. Quel est l'âge minimum pour conduire une voiture en France ?

*Vivre en société · Carte de séjour pluriannuelle*

- 18 ans (avec quelques exceptions) ← **bonne réponse**
- 16 ans
- 21 ans
- 25 ans

**Explication de la question** — L'âge minimum pour conduire une voiture (permis B) est de 18 ans. Une conduite accompagnée est possible dès 15 ans, mais l'examen n'est passé qu'à partir de 17 ans dans certains cas.

**Proposition du modèle — `vs_deplacements_route`** (Se déplacer : permis, sécurité routière, transports) · confiance **0.95**
> Âge minimum permis de conduire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 88. Après l'école élémentaire, dans quel établissement vont les élèves ?

*Vivre en société · Carte de résident*

- Au collège (de la 6e à la 3e) ← **bonne réponse**
- Directement à l'université
- Au lycée directement
- Aucun établissement

**Explication de la question** — Après l'école élémentaire (CP à CM2), les élèves entrent au collège (6e à 3e), puis au lycée (2nde à Terminale). Le collège accueille tous les enfants jusqu'au brevet.

**Proposition du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.97**
> Cycle scolaire collège.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 89. Qu'est-ce que le 'service civique' en France ?

*Vivre en société · Carte de résident*

- Un engagement volontaire des jeunes pour l'intérêt général ← **bonne réponse**
- Le service militaire obligatoire
- Un stage obligatoire
- Un mariage civil

**Explication de la question** — Le service civique est un engagement volontaire de 6 à 12 mois (jeunes 16-25 ans, 30 ans pour personnes en situation de handicap) pour une mission d'intérêt général. Indemnisé par l'État. Différents domaines : solidarité, environnement, culture.

**Proposition du modèle — `vs_emploi_formation`** (Chercher un emploi, se former, créer son activité) · confiance **0.95**
> Service civique cité explicitement dans la frontière.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 90. L'autorité parentale prévoit l'obligation :

*Vivre en société · Carte de résident*

- De protéger, nourrir, éduquer et instruire les enfants ← **bonne réponse**
- De choisir un métier pour ses enfants
- De marier ses enfants
- De rendre les enfants très riches

**Explication de la question** — L'autorité parentale impose aux parents de protéger, éduquer, instruire et assurer l'entretien de leurs enfants jusqu'à leur majorité (18 ans).

**Proposition du modèle — `vs_famille_etat_civil`** (La famille, le couple et l'état civil) · confiance **0.95**
> Autorité parentale et obligations envers les enfants.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 91. Que désigne l'examen civique obligatoire pour la naturalisation depuis 2026 ?

*Vivre en société · Naturalisation*

- Un QCM de 40 questions à passer avec au moins 32/40 ← **bonne réponse**
- Un examen militaire
- Un test médical
- Un sport

**Explication de la question** — Depuis le 1er janvier 2026, les candidats au CSP, CR ou à la naturalisation doivent réussir un examen civique (QCM de 40 questions, 32 bonnes réponses minimum) sur la France et ses valeurs.

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.97**
> Examen civique 2026 pour naturalisation, explicitement dans la notion.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 92. Combien de temps est valable une carte nationale d'identité française ?

*Vivre en société · Carte de séjour pluriannuelle*

- 15 ans pour les majeurs (10 ans pour mineurs) ← **bonne réponse**
- 5 ans pour tous
- À vie
- 1 an renouvelable

**Explication de la question** — Une carte nationale d'identité française est valable 15 ans pour les majeurs (depuis 2014), 10 ans pour les mineurs. Pour voyager hors UE, certains pays exigent une carte non périmée.

**Proposition du modèle — `vs_papiers_identite`** (Ses papiers et les guichets de l'administration) · confiance **0.97**
> Validité carte nationale d'identité.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 93. Qu'est-ce que la sécurité sociale en France ?

*Vivre en société · Carte de résident*

- L'organisme de protection sociale (maladie, retraite, famille, AT) ← **bonne réponse**
- Un service de police
- Une banque
- Un parti politique

**Explication de la question** — La Sécurité sociale (créée en 1945) regroupe les régimes de protection sociale : maladie, vieillesse (retraite), famille (allocations), accidents du travail. Elle est financée par les cotisations sociales.

**Proposition du modèle — `vs_protection_sociale_aides`** (La protection sociale et les aides) · confiance **0.95**
> Sécurité sociale, filet social, financement par cotisations.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 94. Auprès de quel organisme demande-t-on le remboursement de ses frais de santé ?

*Vivre en société · Carte de résident*

- L'Assurance Maladie (CPAM) ← **bonne réponse**
- La mairie
- Le commissariat
- Le tribunal

**Explication de la question** — C'est l'Assurance Maladie (Caisse primaire d'assurance maladie - CPAM) qui rembourse les frais de santé. La carte Vitale facilite ces remboursements.

**Proposition du modèle — `vs_sante_soins`** (Se soigner : médecin, Sécu, remboursements) · confiance **0.96**
> Remboursement des frais de santé via CPAM.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 95. Qu'est-ce que l'OFII ?

*Vivre en société · Carte de résident*

- L'Office français de l'immigration et de l'intégration ← **bonne réponse**
- Un syndicat
- Une banque
- Un musée

**Explication de la question** — L'Office français de l'immigration et de l'intégration (OFII) accompagne les étrangers en France : visites médicales, contrat d'intégration républicaine (CIR), formations linguistiques et civiques.

**Proposition du modèle — `vs_sejour_asile`** (Le séjour des étrangers et l'asile) · confiance **0.97**
> OFII cité explicitement dans la frontière.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 96. Qu'est-ce que la rupture conventionnelle ?

*Vivre en société · Carte de résident*

- Accord amiable pour rompre un CDI avec indemnités et droit chômage ← **bonne réponse**
- Une démission simple
- Un licenciement abusif
- Un contrat imposé

**Explication de la question** — La rupture conventionnelle est un accord entre l'employeur et le salarié pour mettre fin au CDI à l'amiable. Le salarié a droit à une indemnité et au chômage. Procédure encadrée.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.95**
> Rupture conventionnelle est un mode de rupture du contrat individuel.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 97. Qu'est-ce qu'un comité social et économique (CSE) ?

*Vivre en société · Carte de résident*

- L'instance représentative du personnel en entreprise ← **bonne réponse**
- Un comité des fêtes
- Un syndicat patronal
- Une association sportive

**Explication de la question** — Le CSE est l'instance représentative du personnel dans les entreprises de 11 salariés et plus. Il porte les préoccupations des salariés, gère les œuvres sociales, est consulté sur les grandes décisions.

**Proposition du modèle — `vs_travail_entreprise`** (Les salariés dans l'entreprise) · confiance **0.97**
> CSE, instance représentative collective explicitement citée.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 98. Que désigne un numéro d'urgence en France ?

*Vivre en société · Carte de séjour pluriannuelle*

- Un numéro gratuit pour joindre les secours 24h/24 ← **bonne réponse**
- Un numéro payant
- Un numéro réservé aux fonctionnaires
- Un numéro européen uniquement

**Explication de la question** — Un numéro d'urgence est un numéro court, gratuit, accessible 24h/24, qui permet d'appeler les services de secours (police 17, pompiers 18, SAMU 15, urgence européenne 112).

**Proposition du modèle — `vs_urgences_secours`** (Urgences, secours et forces de l'ordre) · confiance **0.95**
> Définition générale des numéros d'urgence.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 99. Quel âge minimum pour passer le permis de conduire (B) ?

*Vivre en société · Carte de séjour pluriannuelle*

- 18 ans pour conduire seul (17 en conduite accompagnée) ← **bonne réponse**
- 16 ans
- 21 ans
- Pas d'âge minimum

**Explication de la question** — Le permis B se passe à partir de 17 ans en conduite accompagnée, et 18 ans en filière classique. Pour conduire seul, il faut 18 ans dans tous les cas.

**Proposition du modèle — `vs_deplacements_route`** (Se déplacer : permis, sécurité routière, transports) · confiance **0.97**
> Permis B, âge minimum, cité explicitement.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 100. Combien y a-t-il d'années au collège ?

*Vivre en société · Carte de séjour pluriannuelle*

- 4 années (6e, 5e, 4e, 3e) ← **bonne réponse**
- 3 années
- 6 années
- 2 années

**Explication de la question** — Le collège dure 4 ans : 6e, 5e, 4e, 3e. A la fin de la 3e, les élèves passent le diplôme national du brevet (DNB).

**Proposition du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.97**
> Durée du collège, cycle scolaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

