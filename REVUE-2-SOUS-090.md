# Revue 2 — les 133 suggestions sous 0,90

Campagne complète `PROMPT_TAG_NOTION_v4`. Le pilote a mesuré **44,4 % de justesse** dans cette zone contre 97,6 % au-dessus : elle se relit intégralement, elle ne se valide jamais en masse.

> 🛑 **Le modèle PROPOSE, il n'applique rien.** Aucune de ces suggestions n'a touché `civic_notion_id` — 48 questions sont taguées dans tout le dépôt, et toutes l'ont été par un geste humain.

⚠️ Les questions « aucune notion » n'y sont **pas** : elles sont traitées dans `REVUE-1-AUCUNE.md`. Les relire deux fois n'apporterait rien.

Ordre : confiance croissante — c'est là que ta relecture compte le plus.

## Les très incertaines — sous 0,70 · 12 questions

### 1. L'école publique en France est-elle gratuite ?

*Principes et valeurs · Carte de séjour pluriannuelle*

- Oui, gratuite et laïque ← **bonne réponse**
- Non, il faut payer chaque année
- Oui, mais uniquement pour les Français
- Uniquement de la maternelle au CM2

**Explication de la question** — Oui. L'école publique est gratuite, laïque et obligatoire depuis les lois Jules Ferry (1881-1882). C'est un fondement de la République.

**Proposition du modèle — `pv_laicite`** (La laïcité) · confiance **0.55**
> École publique gratuite et laïque, mêle service public éducatif et laïcité mais surtout gratuité hors référentiel; alternative laïcité par mention du mot.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 2. Le droit de grève est-il reconnu en France ?

*Principes et valeurs · Carte de résident*

- Oui, c'est un droit constitutionnel encadré par la loi ← **bonne réponse**
- Non, c'est interdit en France
- Oui, mais uniquement les samedis
- Non, sauf pour les agriculteurs

**Explication de la question** — Oui. Le droit de grève a valeur constitutionnelle (Préambule de 1946). Il est encadré par la loi, notamment dans les services publics (préavis, service minimum).

**Proposition du modèle — `pv_libertes_ddhc`** (Les libertés fondamentales et la Déclaration de 1789) · confiance **0.55**
> Droit de grève encadré, frontière avec régime juridique concret.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.45**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 3. Qu'est-ce que la double peine pour un étranger ?

*Droits et devoirs · Carte de résident*

- Une peine de prison suivie d'une expulsion du territoire ← **bonne réponse**
- Deux peines successives à domicile
- Une amende doublée
- Une peine annulée

**Explication de la question** — La double peine désigne la situation où un étranger condamné à une peine de prison est ensuite expulsé du territoire français. La loi de 2003 a limité cette pratique mais pas supprimée.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.55**
> Procédure pénale et conséquence pour étranger condamné.

**Alternative du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 4. En quelle année la loi de séparation des Églises et de l'État a-t-elle été votée ?

*Principes et valeurs · Carte de résident*

- 1905 ← **bonne réponse**
- 1789
- 1848
- 1944

**Explication de la question** — La loi de separation des Églises et de l'État a été adoptée le 9 décembre 1905. Elle a établi la laïcité en France et la liberté de conscience.

**Proposition du modèle — `pv_laicite`** (La laïcité) · confiance **0.60**
> La date de la loi de 1905 est explicitement exclue vers hg_conquetes_droits selon la frontière, donc incertitude.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 5. La liberté syndicale est-elle reconnue en France ?

*Principes et valeurs · Carte de résident*

- Oui, chacun peut adhérer ou non à un syndicat ← **bonne réponse**
- Non, les syndicats sont interdits
- Oui, mais uniquement dans le public
- Non, sauf pour les cadres

**Explication de la question** — Oui. Tout salarié peut adhérer librement à un syndicat, en créer un ou ne pas s'affilier. La loi protège les représentants syndicaux dans l'entreprise.

**Proposition du modèle — `pv_libertes_ddhc`** (Les libertés fondamentales et la Déclaration de 1789) · confiance **0.60**
> Liberté syndicale comme principe, mais pourrait relever du régime juridique concret.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 6. Le mariage entre deux personnes de même sexe est-il autorisé en France ?

*Principes et valeurs · Carte de résident*

- Oui, depuis 2013 ← **bonne réponse**
- Non, c'est interdit
- Oui, mais uniquement dans certaines communes
- Non, sauf autorisation religieuse

**Explication de la question** — Oui. Depuis la loi du 17 mai 2013, deux personnes de même sexe peuvent se marier en France et adopter des enfants ensemble.

**Proposition du modèle — `pv_egalite_non_discrimination`** (Égalité et refus des discriminations) · confiance **0.60**
> Mariage pour tous relève de l'égalité/non-discrimination, mais aussi du droit civil.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 7. Le mariage entre personnes du même sexe a-t-il une valeur dans toute l'Union européenne ?

*Droits et devoirs · Naturalisation*

- Cela dépend de chaque État membre ← **bonne réponse**
- Oui, c'est uniforme dans toute l'UE
- Non, c'est interdit partout en Europe
- Uniquement dans les pays scandinaves

**Explication de la question** — Pas obligatoirement. Chaque État membre choisit s'il légalise le mariage homosexuel. Toutefois, la libre circulation des couples mariés (et leur reconnaissance) progresse.

**Proposition du modèle — `dd_protection_europeenne`** (Les droits protégés au-delà de la France : CEDH, Union européenne) · confiance **0.60**
> Mariage homosexuel dans l'UE, portée européenne du droit.

**Alternative du modèle — `dd_vie_privee_famille`** (Vie privée, image, données personnelles et vie de famille) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 8. Les dirigeants sont élus par les citoyens dans :

*Institutions · Carte de séjour pluriannuelle*

- Une démocratie ← **bonne réponse**
- Une dictature
- Une monarchie absolue
- Une théocratie

**Explication de la question** — Dans une démocratie, les dirigeants sont élus par les citoyens lors d'élections libres. La France est une démocratie représentative.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.60**
> Notion générale de démocratie liée aux élections des dirigeants.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 9. Que signifie le principe d''égalité réelle' ?

*Droits et devoirs · Naturalisation*

- Corriger les inégalités de fait par des politiques publiques ← **bonne réponse**
- Faire tous identiques
- Supprimer la propriété
- Donner plus aux puissants

**Explication de la question** — L'égalité réelle (par opposition à l'égalité formelle) vise à corriger les inégalités de fait, par des politiques publiques (éducation prioritaire, parité, accessibilité handicap, discrimination positive).

**Proposition du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.60**
> Égalité réelle par politiques sociales.

**Alternative du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 10. Quel principe constitutionnel garantit l'égalité entre hommes et femmes pour les mandats électoraux ?

*Droits et devoirs · Naturalisation*

- La parité (Constitution depuis 1999) ← **bonne réponse**
- L'unicité du suffrage
- La proportionnelle intégrale
- Aucun principe particulier

**Explication de la question** — La parité, inscrite dans la Constitution depuis 1999 (article 1er), impose aux partis politiques de favoriser l'égal accès des femmes et des hommes aux mandats électifs et aux fonctions électives.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.60**
> Principe constitutionnel d'égalité, proche de l'égalité comme principe de texte.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 11. Quel âge permet l'apprentissage en alternance en France ?

*Vivre en société · Carte de résident*

- À partir de 16 ans (parfois 15) ← **bonne réponse**
- 12 ans
- 21 ans
- Aucune limite

**Explication de la question** — L'apprentissage est ouvert aux jeunes dès 16 ans (parfois dès 15 ans en fin de 3e). L'âge limite a été porté à 29 ans révolus (avec exceptions). L'apprenti partage son temps entre entreprise et CFA.

**Proposition du modèle — `vs_emploi_formation`** (Chercher un emploi, se former, créer son activité) · confiance **0.60**
> Âge pour l'apprentissage, entre formation et statut scolaire.

**Alternative du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 12. Qui a été le premier président de la Ve République élu au suffrage universel direct ?

*Institutions · Naturalisation*

- Charles de Gaulle (1965) ← **bonne réponse**
- Vincent Auriol
- François Mitterrand
- Georges Pompidou

**Explication de la question** — Charles de Gaulle a été le premier président élu au suffrage universel direct en 1965, après la révision constitutionnelle de 1962.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.60**
> Élection présidentielle au suffrage direct

**Alternative du modèle — `inst_president`** (Le président de la République) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

## Les hésitantes — 0,70 à 0,89 · 121 questions

### 13. "La France est une République indivisible, ..., démocratique et sociale". Completez cette phrase extraite de l'article 1er de la Constitution :

*Principes et valeurs · Naturalisation*

- laïque ← **bonne réponse**
- religieuse
- monarchique
- fédérale

**Explication de la question** — L'article 1er de la Constitution définit la France comme une République "indivisible, laïque, démocratique et sociale". La laïcité est l'un des quatre principes fondamentaux.

**Proposition du modèle — `pv_republique_democratie`** (La République : régime, démocratie, souveraineté) · confiance **0.70**
> Article 1er, adjectifs de la République incluant laïcité.

**Alternative du modèle — `pv_laicite`** (La laïcité) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 14. En quelle année la loi de séparation des Églises et de l'État a-t-elle été votée ?

*Principes et valeurs · Naturalisation*

- 1905 ← **bonne réponse**
- 1789
- 1958
- 1881

**Explication de la question** — La loi de séparation des Églises et de l'État a été votée le 9 décembre 1905. Elle a posé les bases de la laïcité française.

**Proposition du modèle — `pv_laicite`** (La laïcité) · confiance **0.70**
> Date de la loi de 1905, mais frontière indique que la date comme repère historique va vers hg_conquetes_droits.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 15. L'école publique en France est-elle laïque ?

*Principes et valeurs · Carte de séjour pluriannuelle*

- Oui, depuis les lois Ferry (1881-1882) ← **bonne réponse**
- Non, elle suit la religion catholique
- Cela varie selon les villes
- Uniquement les jours fériés

**Explication de la question** — Oui. L'école publique est laïque depuis les lois Ferry (1881-1882). Cela signifie qu'elle est neutre vis-à-vis des religions et qu'il est interdit d'y afficher des signes religieux ostensibles.

**Proposition du modèle — `pv_laicite`** (La laïcité) · confiance **0.70**
> Neutralité de l'école publique face aux religions, relève de la laïcité comme obligation de l'État.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 16. Le droit à un recours effectif est-il garanti ?

*Droits et devoirs · Naturalisation*

- Oui, article 13 de la CEDH ← **bonne réponse**
- Non, c'est facultatif
- Uniquement pour les Français
- Uniquement pour les Européens

**Explication de la question** — Oui. Article 13 de la CEDH : toute personne dont les droits ont été violés a droit à un recours effectif devant une instance nationale. Garantie aussi par la Constitution et le droit européen.

**Proposition du modèle — `dd_protection_europeenne`** (Les droits protégés au-delà de la France : CEDH, Union européenne) · confiance **0.70**
> Article 13 CEDH, recours effectif.

**Alternative du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.55**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 17. Parmi ces droits, lequel est considéré comme un droit fondamental ?

*Droits et devoirs · Carte de résident*

- Le droit à la liberté ← **bonne réponse**
- Le droit de gagner aux jeux d'argent
- Le droit de stationnement gratuit
- Le droit d'avoir un animal exotique

**Explication de la question** — Le droit à la vie, à la liberté et à la sûreté sont des droits fondamentaux, reconnus notamment par la Déclaration de 1789 et la Constitution.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.70**
> Droit fondamental à la liberté, contenu du droit.

**Alternative du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 18. Qu'est-ce que la liberté d'aller et venir ?

*Principes et valeurs · Carte de résident*

- Le droit de circuler librement et de choisir son domicile ← **bonne réponse**
- L'obligation de demander un visa pour changer de ville
- Le droit réservé aux fonctionnaires
- Le droit de conduire sans permis

**Explication de la question** — C'est le droit de circuler librement sur le territoire français, de choisir son lieu de résidence et, pour les citoyens, de quitter et de revenir dans le pays.

**Proposition du modèle — `pv_libertes_ddhc`** (Les libertés fondamentales et la Déclaration de 1789) · confiance **0.70**
> Liberté d'aller et venir comme principe.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 19. Qu'est-ce qui est traditionnellement organisé sur les Champs-Élysées le 14 juillet pour célébrer la fête nationale ?

*Principes et valeurs · Carte de séjour pluriannuelle*

- Un défilé militaire ← **bonne réponse**
- Un marché de Noël
- Une course cycliste
- Un concert de musique classique

**Explication de la question** — Un défilé militaire est organisé chaque année sur les Champs-Élysées à Paris, en présence du président de la République. C'est la plus ancienne et la plus grande parade militaire d'Europe.

**Proposition du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.70**
> Défilé militaire du 14 juillet, associé à la fête nationale symbole.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 20. Que signifie l'expression 'cohabitation' en politique française ?

*Institutions · Naturalisation*

- Président et Premier ministre de bords opposés ← **bonne réponse**
- Deux présidents simultanés
- Un partage de l'Élysée
- Un meeting commun

**Explication de la question** — La cohabitation désigne la situation où le président de la République et le Premier ministre appartiennent à des bords politiques opposés. Trois cohabitations ont eu lieu : 1986-88, 1993-95, 1997-2002.

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.70**
> Cohabitation entre président et Premier ministre, relation exécutif.

**Alternative du modèle — `inst_president`** (Le président de la République) · confiance **0.65**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 21. Quel document présente les droits et devoirs des personnes résidant en France ?

*Droits et devoirs · Carte de résident*

- Le Livret du citoyen ← **bonne réponse**
- Le Code de la route
- La Bible
- Le Code Napoléon

**Explication de la question** — Le Livret du citoyen (et la Charte des droits et devoirs du citoyen français pour les naturalisations) présente les droits et devoirs essentiels des résidents en France.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.70**
> Charte des droits et devoirs du citoyen citée explicitement dans la frontière.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 22. Quel général est associé à la guerre de Cent Ans ?

*Histoire, géo et culture · Carte de résident*

- Jeanne d'Arc (aux côtés de Charles VII) ← **bonne réponse**
- Napoléon Bonaparte
- De Gaulle
- Louis XIV

**Explication de la question** — La guerre de Cent Ans (1337-1453) a opposé la France à l'Angleterre. Jeanne d'Arc a joué un rôle décisif en aidant Charles VII à être sacré roi à Reims en 1429.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.70**
> Jeanne d'Arc, figure de l'Ancien Régime mentionnée dans le référentiel de la Révolution.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.30**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 23. Quel pays est un pays fondateur de l'Union européenne ?

*Institutions · Carte de résident*

- La France ← **bonne réponse**
- L'Espagne
- La Pologne
- La Grèce

**Explication de la question** — Les 6 pays fondateurs (CEE 1957) sont : France, Allemagne, Italie, Belgique, Pays-Bas et Luxembourg.

**Proposition du modèle — `inst_ue`** (L'Union européenne) · confiance **0.70**
> Pays fondateur de l'UE, proche de l'histoire mais reste institutionnel.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.30**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 24. Quels droits la citoyenneté française permet-elle d'exercer ?

*Droits et devoirs · Carte de résident*

- Voter, être éligible, bénéficier de la protection de l'État ← **bonne réponse**
- Aucun droit particulier
- Uniquement le droit de porter le drapeau
- Le droit à un revenu universel

**Explication de la question** — La citoyenneté française donne droit de vote et d'éligibilité à toutes les élections, droit à la protection de l'État (à l'étranger), droit d'occuper des fonctions publiques.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.70**
> Droits liés à la citoyenneté, proche des devoirs du citoyen.

**Alternative du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 25. À quelle valeur de la République le bénévolat et le service civique sont-ils liés ?

*Principes et valeurs · Carte de résident*

- La fraternité ← **bonne réponse**
- La laïcité
- La propriété privée
- La liberté de la presse

**Explication de la question** — Le bénévolat et le service civique sont des engagements pour aider les autres : ils sont une expression concrète de la fraternité.

**Proposition du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.70**
> Mot 'fraternité' de la devise, sens du mot.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.30**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 26. Combien de tours comporte l'élection présidentielle française ?

*Institutions · Carte de séjour pluriannuelle*

- Deux tours ← **bonne réponse**
- Un seul tour
- Trois tours
- Aucun tour, c'est une nomination

**Explication de la question** — L'élection présidentielle comporte deux tours. Si aucun candidat n'obtient plus de 50% des voix au premier tour, les deux candidats arrivés en tête s'affrontent au second tour.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.75**
> Nombre de tours du scrutin présidentiel, vu du côté du scrutin.

**Alternative du modèle — `inst_president`** (Le président de la République) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 27. L'apatridie est-elle protégée par le droit français ?

*Droits et devoirs · Naturalisation*

- Oui, statut d'apatride accordé par l'OFPRA ← **bonne réponse**
- Non, ils sont expulsés
- Ils ne peuvent pas exister
- Uniquement les enfants

**Explication de la question** — Oui. La Convention de 1954 et le droit français protègent les apatrides (personnes sans nationalité). L'OFPRA peut leur accorder un statut leur permettant de séjourner et de circuler.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.75**
> Protection des apatrides, droit d'asile associé.

**Alternative du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 28. La protection des enfants est-elle un devoir en France ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Oui, et le 119 permet de signaler ← **bonne réponse**
- Non, c'est aux parents seulement
- Uniquement les enseignants
- Uniquement les voisins

**Explication de la question** — Oui. Tous les adultes ont l'obligation de protéger les enfants et de signaler toute situation de maltraitance. Le numéro 119 est dédié à l'enfance en danger.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.75**
> Devoir de protéger l'enfant, signalement.

**Alternative du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 29. Le droit à la présomption d'innocence figure-t-il dans la DDHC ?

*Droits et devoirs · Carte de résident*

- Oui, article 9 de la DDHC ← **bonne réponse**
- Non, c'est une invention récente
- Non, c'est un principe religieux
- Oui, mais réservé aux Français

**Explication de la question** — Oui. L'article 9 dispose : 'Tout homme étant présumé innocent jusqu'à ce qu'il ait été déclaré coupable...' C'est un principe fondamental du droit pénal français.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.75**
> Article 9 DDHC cité, mais contenu proche présomption innocence procédurale.

**Alternative du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 30. Qu'est-ce que la liberté de la presse ?

*Principes et valeurs · Carte de résident*

- Le droit pour les médias d'informer librement ← **bonne réponse**
- Le droit de mentir publiquement
- Le monopole de l'État sur les journaux
- L'obligation de lire la presse chaque jour

**Explication de la question** — C'est le droit pour les journalistes et les médias d'informer librement, sans censure préalable. La loi de 1881 protège cette liberté fondamentale, avec des limites (diffamation, vie privée).

**Proposition du modèle — `pv_libertes_ddhc`** (Les libertés fondamentales et la Déclaration de 1789) · confiance **0.75**
> Liberté de la presse comme principe général.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 31. Qu'est-ce que la liberté de réunion ?

*Principes et valeurs · Carte de résident*

- Le droit de se rassembler pacifiquement ← **bonne réponse**
- L'obligation de participer aux fêtes officielles
- Le droit de bloquer une rue sans déclaration
- Le droit de créer une milice privée

**Explication de la question** — C'est le droit de se rassembler pacifiquement (manifestations, réunions publiques ou privées), sous réserve du respect de l'ordre public.

**Proposition du modèle — `pv_libertes_ddhc`** (Les libertés fondamentales et la Déclaration de 1789) · confiance **0.75**
> Liberté de réunion comme principe.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 32. Qu'est-ce que le 'droit international humanitaire' ?

*Droits et devoirs · Naturalisation*

- Les règles applicables en cas de conflit armé ← **bonne réponse**
- Le droit du commerce mondial
- Le droit de l'environnement
- Le droit familial international

**Explication de la question** — Le droit international humanitaire (Conventions de Genève de 1949) régit la conduite des conflits armés : protection des civils, des prisonniers, des blessés, et restriction des méthodes de guerre.

**Proposition du modèle — `dd_protection_europeenne`** (Les droits protégés au-delà de la France : CEDH, Union européenne) · confiance **0.75**
> Droit international humanitaire, cadre international.

**Alternative du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 33. Qu'est-ce que le 'parcours du combattant' administratif ?

*Vivre en société · Carte de séjour pluriannuelle*

- Les nombreuses démarches administratives à effectuer ← **bonne réponse**
- Une formation militaire
- Un sport olympique
- Un examen scolaire

**Explication de la question** — L'expression décrit (informellement) les nombreuses démarches administratives parfois complexes (cartes d'identité, permis, allocations, retraites). Le site service-public.fr regroupe les démarches.

**Proposition du modèle — `vs_papiers_identite`** (Ses papiers et les guichets de l'administration) · confiance **0.75**
> Démarches administratives générales, guichets de l'administration.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 34. Que doit-on faire si on connait un enfant en danger ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Le signaler (119, services sociaux, police) ← **bonne réponse**
- Rien faire
- Le signaler dans 6 mois
- Demander à la famille

**Explication de la question** — Il faut le signaler immédiatement. On peut appeler le 119 (enfance en danger), contacter une assistante sociale ou la police. Le silence peut être puni.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.75**
> Devoir de signaler un enfant en danger.

**Alternative du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 35. Que permet la citoyenneté française ?

*Droits et devoirs · Carte de résident*

- D'avoir des droits politiques (voter, être élu) et des devoirs ← **bonne réponse**
- D'être dispensé d'impôts
- D'être au-dessus des lois
- De voyager partout sans visa

**Explication de la question** — La citoyenneté française donne des droits (voter, être élu, exercer certaines fonctions) et des devoirs (respecter la loi, payer ses impôts, défense, jury d'assises).

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.75**
> Droits ET devoirs de la citoyenneté, plutôt vu côté devoirs/citoyenneté globale.

**Alternative du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 36. Que signifie la liberté ?

*Principes et valeurs · Carte de résident*

- Le droit de faire ce que la loi permet, dans le respect des autres ← **bonne réponse**
- Le droit de faire absolument tout ce que l'on veut
- L'obligation d'obéir au gouvernement
- Le droit réservé aux citoyens français

**Explication de la question** — La liberté est le droit de faire ce que les lois permettent, dans le respect des libertés des autres. Article 4 de la Déclaration des droits de l'homme et du citoyen de 1789.

**Proposition du modèle — `pv_libertes_ddhc`** (Les libertés fondamentales et la Déclaration de 1789) · confiance **0.75**
> Définition de la liberté comme principe, mais proche du régime juridique.

**Alternative du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 37. Quel impôt finance les services publics locaux ?

*Institutions · Naturalisation*

- L'impôt sur le revenu
- Les taxes locales ← **bonne réponse**
- La TVA
- Aucun impôt

**Explication de la question** — Les collectivités sont financées par les impôts locaux.

**Proposition du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.75**
> Impôts locaux finançant les services publics locaux, liés à l'autonomie financière des collectivités.

**Alternative du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 38. Quel philosophe français existentialiste a refusé le prix Nobel en 1964 ?

*Histoire, géo et culture · Naturalisation*

- Jean-Paul Sartre ← **bonne réponse**
- Albert Camus
- André Malraux
- Raymond Aron

**Explication de la question** — Jean-Paul Sartre (1905-1980), philosophe existentialiste et écrivain, a refusé le prix Nobel de littérature qui lui était décerné en 1964. Il était le compagnon de Simone de Beauvoir.

**Proposition du modèle — `hg_litterature`** (Les grands écrivains français) · confiance **0.75**
> Sartre, philosophe-écrivain, prix Nobel de littérature refusé.

**Alternative du modèle — `hg_arts_sciences`** (Artistes et savants français) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 39. Quel référendum de 1962 a transformé l'élection du président ?

*Institutions · Naturalisation*

- Le référendum de 1962 sur le suffrage direct ← **bonne réponse**
- Le référendum sur l'Algérie
- Le référendum sur Maastricht
- Le référendum sur l'euro

**Explication de la question** — Le référendum du 28 octobre 1962 a instauré l'élection du président au suffrage universel direct, sur l'initiative de Charles de Gaulle.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.75**
> Référendum sur le suffrage universel direct, relève des élections/référendum.

**Alternative du modèle — `inst_president`** (Le président de la République) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 40. Quelle est la durée du mandat des conseillers municipaux ?

*Institutions · Carte de résident*

- 6 ans ← **bonne réponse**
- 5 ans
- 4 ans
- 3 ans

**Explication de la question** — Les conseillers municipaux sont élus pour 6 ans. Le maire qu'ils élisent a la même durée de mandat.

**Proposition du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.75**
> Durée du mandat des conseillers municipaux, élections locales.

**Alternative du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 41. Quelle est la durée du mandat des conseillers régionaux ?

*Institutions · Carte de résident*

- 6 ans ← **bonne réponse**
- 5 ans
- 7 ans
- 9 ans

**Explication de la question** — Comme les conseillers départementaux et municipaux, les conseillers régionaux sont élus pour 6 ans.

**Proposition du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.75**
> Durée du mandat des conseillers régionaux, élections locales.

**Alternative du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 42. Quelle est la mission principale du pouvoir exécutif ?

*Institutions · Carte de résident*

- Faire appliquer les lois et diriger la politique de l'État ← **bonne réponse**
- Voter les lois
- Juger les délinquants
- Réviser la Constitution

**Explication de la question** — Le pouvoir exécutif est chargé de faire appliquer les lois et de conduire la politique de la nation. Il est exercé par le président de la République et le gouvernement.

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.75**
> Mission du pouvoir exécutif, appliqué par gouvernement/président.

**Alternative du modèle — `inst_president`** (Le président de la République) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 43. Quelle liberté permet à chacun d'exprimer ses idées ?

*Principes et valeurs · Carte de résident*

- La liberté d'expression ← **bonne réponse**
- La liberté de circulation
- La liberté du commerce
- La liberté de propriété

**Explication de la question** — La liberté d'expression permet à chacun d'exprimer ses opinions, par la parole, l'écrit, l'image. Elle est garantie par la Déclaration des droits de l'homme et du citoyen de 1789.

**Proposition du modèle — `pv_libertes_ddhc`** (Les libertés fondamentales et la Déclaration de 1789) · confiance **0.75**
> Liberté d'expression comme principe proclamé, référence DDHC.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.20**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 44. Quelle région est célébrée pour ses vins (Bordeaux, etc.) ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- La Nouvelle-Aquitaine (région de Bordeaux) ← **bonne réponse**
- L'Île-de-France
- Le Nord
- La Bretagne

**Explication de la question** — La Nouvelle-Aquitaine, autour de Bordeaux, est une des plus grandes régions viticoles de France. D'autres régions viticoles célèbres : Bourgogne, Champagne, Alsace, vallée du Rhône.

**Proposition du modèle — `hg_art_de_vivre`** (Gastronomie, sport et art de vivre) · confiance **0.75**
> Question sur produit (vin) mais formulée en région; frontière ambigüe.

**Alternative du modèle — `hg_geographie`** (Géographie de la France et outre-mer) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 45. Quelle révision constitutionnelle de 2008 a renforcé le rôle du Parlement ?

*Institutions · Naturalisation*

- La révision constitutionnelle du 23 juillet 2008 ← **bonne réponse**
- La révision de 1962
- La révision de 1992
- Aucune révision n'a renforcé le Parlement

**Explication de la question** — La révision constitutionnelle du 23 juillet 2008 a renforcé le Parlement (contrôle de l'ordre du jour partiellement partagé, encadrement du 49.3, création de la QPC) et limite le président (2 mandats consécutifs maximum).

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.75**
> Révision de 2008 renforçant le Parlement.

**Alternative du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.70**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 46. Quelles sont les valeurs républicaines auxquelles le nouveau Français doit adhérer ?

*Vivre en société · Naturalisation*

- Liberté, Égalité, Fraternité, Laïcité, Démocratie, égalité F/H ← **bonne réponse**
- L'obéissance absolue
- La soumission à une religion
- Aucune valeur

**Explication de la question** — Les valeurs républicaines : Liberté, Égalité, Fraternité, Laïcité, Démocratie, État de droit, respect des autres, séparation des pouvoirs, égalité femmes-hommes, refus des violences et discriminations.

**Proposition du modèle — `vs_nationalite_francaise`** (Devenir français) · confiance **0.75**
> Valeurs auxquelles le candidat à la naturalisation doit adhérer.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 47. Qui détient le pouvoir exécutif en France ?

*Institutions · Carte de résident*

- Le président et le gouvernement ← **bonne réponse**
- Le Parlement uniquement
- Les juges
- Le Conseil constitutionnel

**Explication de la question** — Le pouvoir exécutif est détenu par le président de la République et le gouvernement (Premier ministre et ministres).

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.75**
> Identification du pouvoir exécutif dans la séparation des pouvoirs.

**Alternative du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 48. Qui possède le pouvoir exécutif ?

*Institutions · Carte de résident*

- Le président et le gouvernement ← **bonne réponse**
- L'Assemblée nationale et le Sénat
- Les tribunaux
- Le Conseil constitutionnel

**Explication de la question** — Le pouvoir exécutif est détenu par le président de la République et le gouvernement (Premier ministre et ministres).

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.75**
> Identification du titulaire du pouvoir exécutif, niveau séparation des pouvoirs.

**Alternative du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 49. Qui était Joséphine Baker ?

*Histoire, géo et culture · Naturalisation*

- Une artiste, résistante, entrée au Panthéon en 2021 ← **bonne réponse**
- Une scientifique française
- Une exploratrice
- Une religieuse

**Explication de la question** — Joséphine Baker (1906-1975) était une artiste franco-américaine, danseuse et chanteuse, mais aussi résistante pendant la Seconde Guerre mondiale. Entrée au Panthéon en 2021.

**Proposition du modèle — `hg_arts_sciences`** (Artistes et savants français) · confiance **0.75**
> Artiste et résistante, entrée au Panthéon

**Alternative du modèle — `hg_guerres_resistance`** (Les guerres du XXᵉ siècle et la décolonisation) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 50. Une loi votée par le Parlement entre-t-elle en vigueur immédiatement ?

*Institutions · Naturalisation*

- Non, elle doit être promulguée et publiée au Journal officiel ← **bonne réponse**
- Oui, immédiatement au vote
- Après 1 an obligatoirement
- Après accord du pape

**Explication de la question** — Non. Une fois la loi votée, le président dispose de 15 jours pour la promulguer. Elle entre en vigueur après sa publication au Journal officiel, parfois après parution des décrets d'application.

**Proposition du modèle — `inst_president`** (Le président de la République) · confiance **0.75**
> Promulgation par le président, relevé de la frontière parlement.

**Alternative du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 51. Comment les députés français sont-ils choisis ?

*Institutions · Carte de séjour pluriannuelle*

- Par les citoyens français au suffrage direct ← **bonne réponse**
- Par le président de la République
- Par les sénateurs
- Par les maires

**Explication de la question** — Les députés sont élus directement par les citoyens français, au suffrage universel direct, dans le cadre de leur circonscription.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.80**
> Mode d'élection des députés, vu de l'électeur.

**Alternative du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 52. L'incitation à la haine raciale est-elle réprimée en France ?

*Droits et devoirs · Carte de résident*

- Oui, c'est un délit puni par la loi ← **bonne réponse**
- Non, c'est de l'opinion
- Uniquement les insultes directes
- Uniquement en public

**Explication de la question** — Oui. La provocation à la haine, la discrimination ou la violence en raison de l'origine, de la religion ou du sexe est un délit puni par la loi de 1881 sur la presse (1 an de prison, 45 000 EUR d'amende).

**Proposition du modèle — `dd_interdits_quotidien`** (Ce qui est interdit au quotidien, et ce qu'on risque) · confiance **0.80**
> Propos et actes racistes listés comme interdits quotidiens.

**Alternative du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 53. Le 11 novembre est un jour férié. À quoi correspond cette date ?

*Histoire, géo et culture · Carte de résident*

- L'armistice de 1918 (fin de la Première Guerre mondiale) ← **bonne réponse**
- La fin de la Seconde Guerre mondiale
- La fête nationale
- La fête de la République

**Explication de la question** — Le 11 novembre commémore l'armistice de 1918, qui a mis fin à la Première Guerre mondiale, et rend hommage aux soldats morts pour la France.

**Proposition du modèle — `hg_fetes_jours_feries`** (Fêtes et jours fériés en France) · confiance **0.80**
> _Le modèle n'a pas justifié cette alternative séparément._

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.70**
> 11 novembre comme jour férié exclu de hg_guerres_resistance, relève de hg_fetes_jours_feries mais frontière indique l'inverse pour l'événement lui-même; question porte sur ce que commémore le jour férié.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 54. Les citoyens européens résidant en France peuvent-ils être candidats aux municipales ?

*Institutions · Carte de résident*

- Oui, mais pas comme maire ou adjoint ← **bonne réponse**
- Non, c'est interdit
- Oui, à toutes les fonctions
- Uniquement après 30 ans

**Explication de la question** — Oui, sauf au poste de maire ou d'adjoint. Ils peuvent aussi voter aux municipales et européennes en France.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.80**
> Droit de vote et candidature des ressortissants UE aux municipales.

**Alternative du modèle — `inst_collectivites`** (Les collectivités territoriales : commune, département, région) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 55. Que désigne le 'CESU' ?

*Vivre en société · Carte de résident*

- Chèque emploi service universel pour services à domicile ← **bonne réponse**
- Un chèque restaurant
- Un chèque vacances
- Un syndicat

**Explication de la question** — Le CESU (Chèque emploi service universel) facilite l'emploi d'un salarié à domicile (garde d'enfant, ménage, soutien). Il simplifie les démarches administratives et offre des avantages fiscaux.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.80**
> CESU est explicitement cité dans la frontière de cette notion.

**Alternative du modèle — `vs_emploi_formation`** (Chercher un emploi, se former, créer son activité) · confiance **0.30**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 56. Que se passe-t-il si un ministre ne respecte pas la loi ?

*Institutions · Naturalisation*

- Il peut être jugé comme tout citoyen ← **bonne réponse**
- Rien, il a l'immunité totale
- Il perd seulement son poste
- Il décide lui-même de sa sanction

**Explication de la question** — Un ministre, comme tout citoyen, est soumis à la loi. Il peut être jugé par la Cour de justice de la République pour les actes commis dans ses fonctions.

**Proposition du modèle — `inst_justice`** (La justice, les tribunaux et les magistrats) · confiance **0.80**
> Responsabilité pénale du ministre, jugement par la Cour de justice de la République.

**Alternative du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 57. Que signifie le mot "fraternité" dans la devise française ?

*Principes et valeurs · Carte de résident*

- La solidarité et l'entraide entre les citoyens ← **bonne réponse**
- Le lien familial entre frères et sœurs uniquement
- L'appartenance à la même religion
- Le service militaire obligatoire

**Explication de la question** — La fraternité représente la solidarité et l'entraide entre les citoyens. Elle implique le respect, la tolérance et le devoir d'aider les autres.

**Proposition du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.80**
> Sens du mot fraternité de la devise, un des trois mots.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 58. Quel architecte a conçu la pyramide du Louvre ?

*Histoire, géo et culture · Carte de résident*

- Ieoh Ming Pei (1989) ← **bonne réponse**
- Gustave Eiffel
- Le Corbusier
- Auguste Perret

**Explication de la question** — Ieoh Ming Pei (1917-2019), architecte sino-américain, a conçu la pyramide du Louvre, inaugurée en 1989 pour le bicentenaire de la Révolution.

**Proposition du modèle — `hg_patrimoine`** (Monuments et sites emblématiques) · confiance **0.80**
> Pyramide du Louvre, monument, mais question porte sur l'architecte.

**Alternative du modèle — `hg_arts_sciences`** (Artistes et savants français) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 59. Combien de types d'élections principales un citoyen peut-il voter en France ?

*Institutions · Carte de résident*

- Au moins six types différents ← **bonne réponse**
- Une seule élection
- Aucune
- Uniquement la présidentielle

**Explication de la question** — Un citoyen peut voter aux présidentielles, législatives, régionales, départementales, municipales et européennes : six types directs (plus le référendum).

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.85**
> Types d'élections auxquelles un citoyen peut voter.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 60. Combien y a-t-il eu de référendums sous la Ve République ?

*Institutions · Naturalisation*

- Environ 10 référendums depuis 1958 ← **bonne réponse**
- Aucun référendum
- Plus de 100
- Un seul référendum

**Explication de la question** — Sous la Ve République, environ 10 référendums ont été organisés au niveau national, sur des sujets tels que l'Algérie, l'élection du président, l'Europe, le quinquennat ou les traités européens.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.85**
> Référendums sous la Ve République.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 61. Comment qualifier le régime politique de la France aujourd'hui ?

*Institutions · Carte de résident*

- Une république démocratique semi-présidentielle ← **bonne réponse**
- Une monarchie constitutionnelle
- Un État fédéral
- Une dictature militaire

**Explication de la question** — La France est une république parlementaire et semi-présidentielle. Le président partage le pouvoir exécutif avec un gouvernement responsable devant l'Assemblée nationale.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.85**
> Qualification du régime politique de la France, relève de la Constitution/séparation des pouvoirs.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 62. Comment s'appelle l'argent que l'État collecte auprès des citoyens et entreprises ?

*Institutions · Carte de séjour pluriannuelle*

- Les impôts ← **bonne réponse**
- Les dons
- Les héritages
- Les pourboires

**Explication de la question** — L'argent que l'État collecte est appelé "impôts". Les impôts financent les services publics (écoles, hôpitaux, police, routes...).

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.85**
> Collecte de l'impôt par l'État, budgétisation.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 63. Comment un employeur doit-il fixer le salaire d'un salarié ?

*Vivre en société · Carte de résident*

- Respecter le SMIC, la convention collective et le contrat ← **bonne réponse**
- Comme il veut, sans règle
- Au moins 5000 EUR pour tous
- Aléatoire selon l'humeur

**Explication de la question** — Le salaire doit respecter le SMIC (minimum légal), la convention collective applicable (qui peut fixer un minimum supérieur), et le contrat de travail. Il doit être versé mensuellement.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.85**
> SMIC et salaire, contrat individuel; convention collective mentionnée mais accessoire.

**Alternative du modèle — `vs_travail_entreprise`** (Les salariés dans l'entreprise) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 64. Concernant les partis politiques, quelle proposition est correcte ?

*Institutions · Carte de résident*

- Plusieurs partis politiques peuvent exister librement ← **bonne réponse**
- Il n'y a qu'un seul parti autorisé
- Les partis politiques sont interdits
- Seuls les ministres peuvent créer un parti

**Explication de la question** — Les partis politiques se forment librement et concourent à l'expression du suffrage (article 4 de la Constitution). Le multipartisme est garanti.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.85**
> Pluralisme des partis politiques, encadrement de la vie politique.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 65. En quelle année la France a-t-elle perdu l'Alsace-Lorraine, récupérée en 1918 ?

*Histoire, géo et culture · Naturalisation*

- En 1871 (après la guerre franco-prussienne) ← **bonne réponse**
- En 1789
- En 1815
- En 1940

**Explication de la question** — L'Alsace-Lorraine a été annexée par l'Allemagne après la défaite de 1870-1871 (traité de Francfort, 1871). Elle a été restituée à la France après la Première Guerre mondiale (traité de Versailles, 1919).

**Proposition du modèle — `hg_napoleon_xixe`** (Napoléon et la France au XIXᵉ siècle) · confiance **0.85**
> Perte de l'Alsace-Lorraine liée à la défaite de 1870, chute du Second Empire.

**Alternative du modèle — `hg_republiques`** (Les cinq républiques) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 66. La Constitution prévoit-elle un partage entre domaine de la loi et domaine du règlement ?

*Institutions · Naturalisation*

- Oui, articles 34 (loi) et 37 (règlement) ← **bonne réponse**
- Non, tout est législatif
- Non, tout est réglementaire
- Uniquement en Belgique

**Explication de la question** — Oui. L'article 34 énumère les domaines réservés au Parlement (lois). L'article 37 confie au gouvernement les autres domaines (règlements).

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.85**
> Partage loi/règlement relève du gouvernement selon frontière.

**Alternative du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 67. Le droit à un procès équitable est-il garanti en France ?

*Droits et devoirs · Carte de résident*

- Oui, garanti par la Constitution et la CEDH ← **bonne réponse**
- Non, c'est une formalité
- Uniquement pour les Français
- Uniquement en matière civile

**Explication de la question** — Oui. Il est garanti par la Constitution, la DDHC et la Convention européenne des droits de l'homme (article 6). Il comprend l'accès au juge, l'égalité des armes, la présomption d'innocence, le droit à la défense.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.85**
> Procès équitable, procédure judiciaire française.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 68. Le harcèlement moral au travail est-il sanctionné ?

*Droits et devoirs · Carte de résident*

- Oui, c'est un délit puni pénalement ← **bonne réponse**
- Non, c'est libre
- Uniquement entre supérieurs
- Uniquement les femmes y ont droit

**Explication de la question** — Oui. Le harcèlement moral est un délit puni par le Code du travail et le Code pénal (article 222-33-2). La victime peut saisir les prud'hommes et porter plainte.

**Proposition du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.85**
> Harcèlement moral au travail, protection sociale du salarié.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 69. Le harcèlement sexuel est-il interdit en France ?

*Droits et devoirs · Carte de résident*

- Oui, c'est un délit grave puni pénalement ← **bonne réponse**
- Non, c'est toléré
- Uniquement physique
- Uniquement avec menaces explicites

**Explication de la question** — Oui. Le harcèlement sexuel est un délit (article 222-33 du Code pénal) puni de 2 ans de prison et 30 000 EUR d'amende, plus selon les circonstances (mineur, autorité, etc.).

**Proposition du modèle — `dd_interdits_quotidien`** (Ce qui est interdit au quotidien, et ce qu'on risque) · confiance **0.85**
> Harcèlement sexuel listé explicitement comme interdit quotidien.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 70. Le président de la République française dispose-t-il de pouvoirs sans limite ?

*Institutions · Carte de résident*

- Non, ses pouvoirs sont limités par la Constitution ← **bonne réponse**
- Oui, il a tous les pouvoirs
- Oui, sauf en période de paix
- Oui, jusqu'au prochain référendum

**Explication de la question** — Non. Le président détient des pouvoirs importants mais limités par la Constitution, la séparation des pouvoirs, le contrôle du Parlement et la justice. Il n'est pas un monarque absolu.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.85**
> Question sur la limitation des pouvoirs par la Constitution et la séparation des pouvoirs.

**Alternative du modèle — `inst_president`** (Le président de la République) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 71. Le travail au noir (non déclaré) est-il légal en France ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Non, c'est interdit et puni ← **bonne réponse**
- Oui, c'est libre
- Uniquement quelques heures
- Uniquement entre proches

**Explication de la question** — Non. Le travail dissimulé (sans déclaration ni cotisations) est interdit et puni par la loi, autant pour l'employeur que pour le salarié. Cela prive aussi de droits sociaux.

**Proposition du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.85**
> Travail dissimulé, cité dans la notion droits sociaux.

**Alternative du modèle — `dd_interdits_quotidien`** (Ce qui est interdit au quotidien, et ce qu'on risque) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 72. Le viol est-il un crime en droit français ?

*Droits et devoirs · Carte de résident*

- Oui, c'est un crime jugé en cour d'assises ← **bonne réponse**
- Non, c'est un simple délit
- Uniquement entre étrangers
- Uniquement avec violence visible

**Explication de la question** — Oui. Le viol est un crime (article 222-23 du Code pénal), puni de 15 ans de réclusion criminelle, plus selon les circonstances aggravantes (mineur, autorité, etc.).

**Proposition du modèle — `dd_interdits_quotidien`** (Ce qui est interdit au quotidien, et ce qu'on risque) · confiance **0.85**
> Viol listé explicitement comme interdit quotidien avec sa sanction.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 73. Lequel de ces pays est l'un des fondateurs de la Communauté économique européenne (futur UE) ?

*Institutions · Carte de résident*

- La France ← **bonne réponse**
- Le Royaume-Uni
- L'Espagne
- La Pologne

**Explication de la question** — Les six pays fondateurs de la CEE en 1957 (Traité de Rome) sont : la France, l'Allemagne (RFA à l'époque), l'Italie, la Belgique, les Pays-Bas et le Luxembourg.

**Proposition du modèle — `inst_ue`** (L'Union européenne) · confiance **0.85**
> Pays fondateurs de la CEE, appartient aux traités de l'UE.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 74. Lequel de ces personnages historiques est français ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Jeanne d'Arc ← **bonne réponse**
- Winston Churchill
- George Washington
- Christophe Colomb

**Explication de la question** — Jeanne d'Arc (1412-1431), originaire de Domrémy, est une figure majeure de l'histoire de France. Elle a contribué à libérer la France pendant la guerre de Cent Ans.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.85**
> Jeanne d'Arc, figure de l'Ancien Régime citée dans la frontière de hg_revolution.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 75. Parmi ces personnages historiques, lequel est français ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Jeanne d'Arc ← **bonne réponse**
- Christophe Colomb
- Winston Churchill
- Albert Einstein

**Explication de la question** — Plusieurs personnages français célèbres : Jeanne d'Arc (héroïne du XVe siècle), Napoléon Bonaparte, Charles de Gaulle, Marie Curie (scientifique). Tous ont marqué l'histoire de France.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.85**
> Jeanne d'Arc relève des figures de l'Ancien Régime/pré-Révolution françaises.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 76. Pour combien de temps est élu le président de la République française ?

*Institutions · Carte de résident*

- 5 ans ← **bonne réponse**
- 4 ans
- 6 ans
- 7 ans

**Explication de la question** — Le président de la République est élu pour 5 ans (quinquennat) depuis la réforme constitutionnelle de 2000.

**Proposition du modèle — `inst_president`** (Le président de la République) · confiance **0.85**
> Durée du mandat présidentiel, caractéristique de l'institution.

**Alternative du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 77. Pour combien de temps sont élus les députés ?

*Institutions · Carte de résident*

- 5 ans ← **bonne réponse**
- 4 ans
- 6 ans
- 7 ans

**Explication de la question** — Les députés sont élus pour 5 ans au suffrage universel direct, par circonscription.

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.85**
> Durée du mandat des députés.

**Alternative du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 78. Pour combien de temps sont élus les sénateurs ?

*Institutions · Carte de résident*

- 6 ans ← **bonne réponse**
- 5 ans
- 3 ans
- 9 ans

**Explication de la question** — Les sénateurs sont élus pour 6 ans au suffrage universel indirect. Le Sénat est renouvelé par moitié tous les 3 ans.

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.85**
> Durée du mandat des sénateurs.

**Alternative du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 79. Qu'est-ce qu'un arrêt maladie en France ?

*Vivre en société · Carte de résident*

- Une suspension de travail prescrite par un médecin ← **bonne réponse**
- Un licenciement
- Des vacances
- Un événement religieux

**Explication de la question** — L'arrêt maladie est prescrit par un médecin. Il faut transmettre l'arrêt à l'employeur (48h) et à l'Assurance maladie. Le salarié touche des indemnités journalières (Sécurité sociale + employeur selon convention).

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.85**
> Arrêt maladie lié au contrat de travail individuel, cité explicitement.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 80. Qu'est-ce qu'une 'loi organique' en droit français ?

*Institutions · Naturalisation*

- Une loi précisant l'organisation des pouvoirs publics ← **bonne réponse**
- Une loi religieuse
- Une loi sur les organes humains
- Un décret du maire

**Explication de la question** — Une loi organique précise l'organisation et le fonctionnement des pouvoirs publics. Elle est adoptée selon une procédure renforcée et est soumise obligatoirement au contrôle du Conseil constitutionnel.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.85**
> Loi organique, rang des normes.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 81. Qu'est-ce que l'égalité ?

*Principes et valeurs · Carte de résident*

- Tous les citoyens sont égaux devant la loi ← **bonne réponse**
- Tout le monde gagne le même salaire
- Tout le monde a la même apparence
- Tout le monde doit avoir les mêmes opinions

**Explication de la question** — L'égalité signifie que tous les citoyens sont égaux devant la loi, sans distinction d'origine, de race, de religion, de sexe ou d'opinion.

**Proposition du modèle — `pv_egalite_non_discrimination`** (Égalité et refus des discriminations) · confiance **0.85**
> Égalité devant la loi comme principe, sans distinction.

**Alternative du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.30**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 82. Qu'est-ce que le 'noyau dur' des droits intangibles selon la CEDH ?

*Droits et devoirs · Naturalisation*

- Vie, interdiction de torture, d'esclavage, légalité pénale ← **bonne réponse**
- Tous les droits sont intangibles
- Aucun droit n'est intangible
- Uniquement le droit à la propriété

**Explication de la question** — Certains droits sont absolus, indispensables : droit à la vie, interdiction de la torture, interdiction de l'esclavage, principe de légalité pénale. Aucune dérogation n'est possible, même en cas de guerre.

**Proposition du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.85**
> Noyau dur des droits intangibles, notion de principe pénal.

**Alternative du modèle — `dd_protection_europeenne`** (Les droits protégés au-delà de la France : CEDH, Union européenne) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 83. Qu'est-ce que le droit à la dignité humaine ?

*Droits et devoirs · Carte de résident*

- Un principe constitutionnel protégeant la condition humaine ← **bonne réponse**
- Un avantage fiscal
- Une obligation religieuse
- Un droit réservé aux femmes

**Explication de la question** — Le principe de dignité humaine, principe constitutionnel depuis 1994, protège chaque personne de toute atteinte dégradant sa condition d'être humain. Il fonde de nombreux droits fondamentaux.

**Proposition du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.85**
> Dignité humaine, principe cité dans infractions_peines.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 84. Qu'est-ce que le droit à un environnement équilibré selon la Charte de 2004 ?

*Droits et devoirs · Naturalisation*

- Le droit à un environnement équilibré et respectueux de la santé ← **bonne réponse**
- Le droit à la pollution
- Un droit européen non intégré
- Aucun droit spécifique

**Explication de la question** — L'article 1er de la Charte de l'environnement reconnaît le droit pour chacun de vivre dans un environnement équilibré et respectueux de la santé. Adossée à la Constitution depuis 2005.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.85**
> Droit à l'environnement, énoncé toujours couplé au devoir environnemental dans ce référentiel

**Alternative du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 85. Qu'est-ce que le pouvoir exécutif ? Le pouvoir :

*Institutions · Carte de résident*

- D'appliquer les lois et de diriger l'État ← **bonne réponse**
- De voter les lois
- De juger les citoyens
- De modifier la Constitution

**Explication de la question** — Le pouvoir exécutif est chargé d'appliquer les lois et de diriger la politique de la nation. En France, il est exercé par le président et le gouvernement.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.85**
> Définition générale du pouvoir exécutif au niveau séparation des pouvoirs.

**Alternative du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 86. Quand sont élus les sénateurs ?

*Institutions · Naturalisation*

- Tous les 3 ans, par moitié ← **bonne réponse**
- Tous les ans
- Tous les 5 ans en même temps
- Tous les 10 ans

**Explication de la question** — Les sénateurs sont élus pour 6 ans au suffrage indirect, par environ 162 000 "grands électeurs" (députés, conseillers régionaux, départementaux, municipaux). Le Sénat est renouvelé par moitié tous les 3 ans.

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.85**
> Mode et rythme d'élection des sénateurs, caractéristique institutionnelle.

**Alternative du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 87. Que commémore le 14 juillet ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- La prise de la Bastille (1789) ← **bonne réponse**
- L'armistice de 1918
- L'abolition de l'esclavage
- La fin de la guerre d'Algérie

**Explication de la question** — Le 14 juillet est la fête nationale française. Elle commémore la prise de la Bastille en 1789 (début de la Révolution) et la fête de la Fédération en 1790 (union nationale).

**Proposition du modèle — `hg_fetes_jours_feries`** (Fêtes et jours fériés en France) · confiance **0.85**
> Ce que commémore le 14 juillet, question calendaire.

**Alternative du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 88. Que dit la loi sur la haine en ligne ?

*Droits et devoirs · Carte de résident*

- Punis par la loi de 1881 et la régulation des plateformes ← **bonne réponse**
- Liberté totale sur internet
- Uniquement les commentaires anonymes
- Uniquement entre adultes

**Explication de la question** — Les propos haineux (racistes, sexistes, homophobes, etc.) sur internet relèvent du droit pénal français (loi de 1881 sur la presse). Les plateformes ont aussi des obligations de modération (loi Avia/DSA).

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.85**
> Liberté d'expression et ses limites (haine en ligne).

**Alternative du modèle — `dd_interdits_quotidien`** (Ce qui est interdit au quotidien, et ce qu'on risque) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 89. Que désigne l'enseignement par alternance ?

*Vivre en société · Carte de résident*

- Combiner études et travail en entreprise, avec rémunération ← **bonne réponse**
- Étudier en ligne uniquement
- Étudier le soir uniquement
- Étudier sans diplôme

**Explication de la question** — L'alternance combine études (en CFA ou école) et travail en entreprise (en apprentissage ou contrat de professionnalisation). L'élève est rémunéré.

**Proposition du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.85**
> Alternance mentionnée dans le champ scolaire, mais aussi possible emploi_formation

**Alternative du modèle — `vs_emploi_formation`** (Chercher un emploi, se former, créer son activité) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 90. Que désigne l'expression 'Mai 68' ?

*Histoire, géo et culture · Carte de résident*

- Une période de grèves et de manifestations en 1968 ← **bonne réponse**
- Une bataille militaire
- Une exposition universelle
- Une fête religieuse

**Explication de la question** — Mai 68 désigne une période de grèves, de manifestations étudiantes et de mouvements sociaux en mai-juin 1968 en France. Ces événements ont marqué la société française.

**Proposition du modèle — `hg_conquetes_droits`** (Les conquêtes sociales et les transformations de la société) · confiance **0.85**
> Mai 68, transformation profonde de la société.

**Alternative du modèle — `hg_guerres_resistance`** (Les guerres du XXᵉ siècle et la décolonisation) · confiance **0.30**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 91. Que désigne l'expression 'État de droit' en philosophie politique ?

*Droits et devoirs · Naturalisation*

- Un État soumis à la loi avec contrôle juridictionnel ← **bonne réponse**
- Un État avec beaucoup de lois
- Un État sans lois
- Un État monarchique

**Explication de la question** — Un État de droit est un État soumis à la loi, où les pouvoirs publics doivent respecter les règles juridiques et où les droits des citoyens sont garantis et contrôlés par des juges indépendants.

**Proposition du modèle — `dd_textes_fondateurs`** (La Déclaration de 1789 et les textes qui garantissent nos droits) · confiance **0.85**
> État de droit, principe fondateur.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 92. Que désigne l'expression 'État-providence' ?

*Vivre en société · Naturalisation*

- Modèle social où l'État assure protection et redistribution ← **bonne réponse**
- Un parti politique
- Une religion
- Un syndicat

**Explication de la question** — L'État-providence désigne le modèle social où l'État assure la protection sociale et redistribue les richesses pour réduire les inégalités (santé, retraites, allocations, services publics gratuits ou subventionnés).

**Proposition du modèle — `vs_protection_sociale_aides`** (La protection sociale et les aides) · confiance **0.85**
> État-providence, modèle de redistribution sociale.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 93. Que désigne la 'crèche' en France ?

*Vivre en société · Carte de séjour pluriannuelle*

- Un mode de garde collectif pour enfants 0-3 ans ← **bonne réponse**
- Une école obligatoire
- Une salle de musique
- Une bibliothèque

**Explication de la question** — La crèche est un mode de garde collectif pour les enfants de 0 à 3 ans environ. Les places sont attribuées par la mairie ou des structures privées. Le tarif dépend des revenus des parents.

**Proposition du modèle — `vs_famille_etat_civil`** (La famille, le couple et l'état civil) · confiance **0.85**
> Crèche pour enfants 0-3 ans, mode de garde, mentionné dans famille_etat_civil.

**Alternative du modèle — `vs_ecole_scolarite`** (L'école et les études) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 94. Que désigne la notion d''état d'urgence' en droit français ?

*Droits et devoirs · Naturalisation*

- Un régime d'exception restreignant temporairement certaines libertés ← **bonne réponse**
- Un service hospitalier
- Une procédure administrative ordinaire
- Une mesure économique

**Explication de la question** — L'état d'urgence (loi de 1955, révisée depuis) permet au gouvernement de prendre des mesures restrictives des libertés en cas de péril imminent (terrorisme, catastrophe). Il a notamment été déclaré après 2015.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.85**
> État d'urgence, restriction des libertés.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 95. Que désigne la présomption d'innocence ?

*Droits et devoirs · Carte de résident*

- L'accusé est présumé innocent jusqu'à condamnation définitive ← **bonne réponse**
- L'accusé doit prouver son innocence
- L'accusé est coupable par défaut
- L'accusé est ignoré par la justice

**Explication de la question** — La présomption d'innocence signifie qu'une personne est considérée innocente tant qu'elle n'a pas été jugée coupable définitivement. C'est la charge de la preuve qui incombe à l'accusation.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.85**
> Présomption d'innocence dans le cadre procédural.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 96. Que désigne le 'travail dissimulé' en droit pénal ?

*Vivre en société · Naturalisation*

- Travail non déclaré, délit puni de 3 ans de prison ← **bonne réponse**
- Travail bénévole légal
- Travail de nuit autorisé
- Service civique

**Explication de la question** — Le travail dissimulé (article L. 8221-1 du Code du travail) est le fait d'occuper un salarié sans déclaration préalable, sans bulletin de paie ou en sous-déclarant les heures effectuées. C'est un délit puni de 3 ans de prison.

**Proposition du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.85**
> Travail non déclaré cité explicitement dans contrat/salaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 97. Que faut-il faire en cas de cambriolage ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Appeler la police (17) et déposer plainte ← **bonne réponse**
- Ranger soi-même la maison
- Rien dire à personne
- Affronter le cambrioleur seul

**Explication de la question** — Il faut prévenir immédiatement la police (17) ou la gendarmerie, et déposer plainte au commissariat. Ne rien toucher avant l'arrivée des enquêteurs.

**Proposition du modèle — `dd_police_justice`** (Police, justice : mes droits quand la loi s'applique à moi) · confiance **0.85**
> Porter plainte après un cambriolage, réparation.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.30**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 98. Que protège la loi sur la presse de 1881 ?

*Droits et devoirs · Naturalisation*

- La liberté de la presse, avec ses limites légales ← **bonne réponse**
- Le droit des imprimeurs
- Le commerce des livres
- Aucune liberté particulière

**Explication de la question** — La loi du 29 juillet 1881 garantit la liberté de la presse et encadre les abus (diffamation, injure, provocation à la haine, fausse nouvelle). C'est le texte fondateur de la liberté d'expression médiatique.

**Proposition du modèle — `dd_libertes_limites`** (Les libertés individuelles et leurs limites) · confiance **0.85**
> Liberté de la presse et ses limites.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 99. Que verse l'employeur en plus du salaire pour la Sécurité sociale ?

*Vivre en société · Carte de résident*

- Des cotisations sociales (patronales) ← **bonne réponse**
- Une amende
- Un pourboire
- Aucun montant supplémentaire

**Explication de la question** — L'employeur verse des cotisations sociales (patronales) en plus du salaire net. Le salarié cotise aussi (cotisations salariales). Ces cotisations financent la Sécurité sociale, le chômage, la retraite.

**Proposition du modèle — `vs_protection_sociale_aides`** (La protection sociale et les aides) · confiance **0.85**
> Cotisations sociales patronales financent la Sécurité sociale.

**Alternative du modèle — `vs_travail_contrat_salaire`** (Le contrat de travail et le salaire) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 100. Quel est le délai standard pour saisir le Conseil constitutionnel après le vote d'une loi ?

*Institutions · Naturalisation*

- Dans les 15 jours avant promulgation ← **bonne réponse**
- 1 an après
- Jamais
- 10 ans après

**Explication de la question** — La saisine doit intervenir dans le délai de 15 jours qui suivent la promulgation possible, c'est-à-dire avant que le président ne signe la loi.

**Proposition du modèle — `inst_constitution`** (La Constitution et la séparation des pouvoirs) · confiance **0.85**
> Saisine du Conseil constitutionnel.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 101. Quel est le numéro national d'aide aux femmes victimes de violences ?

*Vivre en société · Carte de séjour pluriannuelle*

- Le 3919 ← **bonne réponse**
- Le 15
- Le 17
- Le 36 36

**Explication de la question** — Le 3919 est le numéro national d'écoute pour les femmes victimes de violences (conjugales, sexuelles, harcèlement). C'est gratuit et confidentiel.

**Proposition du modèle — `vs_urgences_secours`** (Urgences, secours et forces de l'ordre) · confiance **0.85**
> Numéro 3919 fait partie des numéros de secours listés.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 102. Quel ministre, en 1945, a participé à la fondation de la Sécurité sociale ?

*Histoire, géo et culture · Naturalisation*

- Pierre Laroque (avec Ambroise Croizat) ← **bonne réponse**
- Robert Schuman
- Jean Monnet
- De Gaulle seul

**Explication de la question** — Pierre Laroque (1907-1997), haut fonctionnaire, a été le principal architecte de la Sécurité sociale française créée en 1945. Le ministre du Travail était alors Ambroise Croizat.

**Proposition du modèle — `hg_conquetes_droits`** (Les conquêtes sociales et les transformations de la société) · confiance **0.85**
> Fondateur de la Sécurité sociale, droit social.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 103. Quel numéro appeler en cas de problème avec un enfant (urgence non vitale) ?

*Vivre en société · Carte de séjour pluriannuelle*

- Le 119 (Allo Enfance en danger) ← **bonne réponse**
- Le 36 36
- Le 100
- Le 911

**Explication de la question** — Le 119 est le numéro national 'Allo Enfance en danger', gratuit, accessible 24h/24, pour signaler une situation d'enfance en difficulté ou en danger. En cas d'urgence vitale, appeler le 15.

**Proposition du modèle — `vs_urgences_secours`** (Urgences, secours et forces de l'ordre) · confiance **0.85**
> Numéro 119, service d'urgence pour enfance en danger, même si signaler relève d'un devoir, le numéro est un service d'urgence.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 104. Quel principe constitutionnel garantit l'égal accès des femmes et des hommes aux mandats électifs ?

*Institutions · Naturalisation*

- La parité (inscrite dans la Constitution en 1999) ← **bonne réponse**
- Le quota religieux
- La hiérarchie par âge
- Aucun principe particulier

**Explication de la question** — Le principe de parité, inscrit dans la Constitution depuis 1999 (article 1er, alinéa 2), impose aux partis politiques de favoriser l'égal accès des femmes et des hommes aux mandats et fonctions électives.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.85**
> Parité liée à l'encadrement électoral.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 105. Quel principe environnemental impose de prévenir les dommages graves à l'environnement ?

*Droits et devoirs · Carte de résident*

- Le principe de précaution (Charte de l'environnement) ← **bonne réponse**
- Le principe de proportionnalité
- Le principe de neutralité
- Le principe de subsidiarité

**Explication de la question** — Le principe de précaution (article 5 de la Charte de l'environnement) impose des mesures provisoires pour prévenir un risque grave de dommage à l'environnement, même en cas d'incertitude scientifique.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.85**
> Principe de précaution lié au devoir environnemental.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 106. Quel principe interdit toute forme de torture, même en temps de guerre ?

*Droits et devoirs · Naturalisation*

- L'interdiction absolue (article 3 CEDH) ← **bonne réponse**
- L'interdiction conditionnelle
- L'interdiction uniquement civile
- L'interdiction uniquement pour les Français

**Explication de la question** — L'interdiction absolue de la torture (article 3 CEDH, Convention contre la torture de 1984). Aucune circonstance, même l'état de guerre ou de nécessité, ne peut justifier la torture.

**Proposition du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.85**
> Interdiction absolue de la torture, interdit intangible.

**Alternative du modèle — `dd_protection_europeenne`** (Les droits protégés au-delà de la France : CEDH, Union européenne) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 107. Quel principe interdit toute peine cruelle ou dégradante ?

*Droits et devoirs · Carte de résident*

- L'interdiction des traitements dégradants (article 3 CEDH) ← **bonne réponse**
- Le principe de proportionnalité
- Le droit à la propriété
- La liberté d'expression

**Explication de la question** — Le principe de dignité humaine et l'article 3 de la Convention européenne des droits de l'homme prohibent absolument les traitements cruels, inhumains ou dégradants, même en temps de guerre.

**Proposition du modèle — `dd_infractions_peines`** (L'infraction et la peine : du principe de légalité aux interdits absolus) · confiance **0.85**
> Interdiction absolue des traitements dégradants, principe noyau dur.

**Alternative du modèle — `dd_protection_europeenne`** (Les droits protégés au-delà de la France : CEDH, Union européenne) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 108. Quel roi est dit le 'Roi-Soleil' ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Louis XIV (Roi-Soleil) ← **bonne réponse**
- Louis XVI
- Henri IV
- François Ier

**Explication de la question** — Louis XIV, qui a régné de 1643 à 1715, est surnommé le 'Roi-Soleil'. Il a fait construire le château de Versailles et a marqué le rayonnement de la France au XVIIe siècle.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.85**
> Louis XIV, roi de l'Ancien Régime.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 109. Quel slogan symbolise la Révolution de 1789 ?

*Principes et valeurs · Carte de résident*

- Liberté, Égalité, Fraternité ← **bonne réponse**
- Travail, Famille, Patrie
- Tous pour un, un pour tous
- Dieu, le roi, la patrie

**Explication de la question** — 'Liberté, Égalité, Fraternité' est devenue la devise officielle de la République, héritage des principes de la Révolution. Elle est inscrite dans la Constitution.

**Proposition du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.85**
> Question sur la devise malgré le lien avec 1789, la réponse porte sur la devise elle-même.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 110. Quel âge permet de quitter le foyer parental ?

*Vivre en société · Carte de séjour pluriannuelle*

- 18 ans (majorité légale), 16 ans avec émancipation ← **bonne réponse**
- 12 ans
- 21 ans
- Aucune limite

**Explication de la question** — À 18 ans (majorité légale), une personne peut quitter le foyer familial sans autorisation. Avant, l'émancipation est possible dès 16 ans, mais elle est encadrée.

**Proposition du modèle — `vs_famille_etat_civil`** (La famille, le couple et l'état civil) · confiance **0.85**
> Majorité et émancipation, notions familiales/état civil.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 111. Quelle crise politique majeure a frappé la France de mai à juin 1968 ?

*Histoire, géo et culture · Naturalisation*

- Une crise étudiante, sociale et politique (Mai 68) ← **bonne réponse**
- Une guerre civile
- Une famine
- Une épidémie

**Explication de la question** — Mai 68 a combiné une crise étudiante (occupation de la Sorbonne, barricades), une crise sociale (10 millions de grévistes) et une crise politique. De Gaulle a dissous l'Assemblée et son parti a remporté les élections.

**Proposition du modèle — `hg_conquetes_droits`** (Les conquêtes sociales et les transformations de la société) · confiance **0.85**
> Mai 68, transformation sociale profonde.

**Alternative du modèle — `hg_republiques`** (Les cinq républiques) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 112. Quelle dynastie régnait sur la France à la veille de la Révolution ?

*Histoire, géo et culture · Naturalisation*

- Les Bourbons ← **bonne réponse**
- Les Valois
- Les Capétiens directs
- Les Plantagenets

**Explication de la question** — La dynastie des Bourbons régnait sur la France depuis 1589 (Henri IV). Louis XVI était le dernier Bourbon à régner avant la Révolution et l'abolition de la monarchie en 1792.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.85**
> Les Bourbons, dynastie régnant sur la France avant la Révolution.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 113. Quelle est la monnaie utilisée en France ?

*Institutions · Carte de séjour pluriannuelle*

- L'euro ← **bonne réponse**
- Le franc
- La livre sterling
- Le dollar

**Explication de la question** — L'euro est la monnaie de la France depuis le 1er janvier 2002, partagée avec 19 autres pays de la zone euro.

**Proposition du modèle — `inst_ue`** (L'Union européenne) · confiance **0.85**
> L'euro, monnaie de l'UE en France.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 114. Quelle institution est consultée avant l'adoption de tout projet de loi ?

*Institutions · Carte de résident*

- Le Conseil d'État ← **bonne réponse**
- La Cour de cassation
- Le Conseil constitutionnel uniquement
- L'Académie française

**Explication de la question** — Le Conseil d'État est consulté sur les projets de loi avant leur examen en Conseil des ministres. Il donne un avis juridique au gouvernement.

**Proposition du modèle — `inst_justice`** (La justice, les tribunaux et les magistrats) · confiance **0.85**
> Conseil d'État consulté sur les projets de loi, institution juridictionnelle administrative.

**Alternative du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 115. Quelle institution européenne assure les politiques migratoires communes ?

*Institutions · Naturalisation*

- Frontex (frontières) et EUAA (asile) ← **bonne réponse**
- L'OTAN
- L'ONU uniquement
- Le pape

**Explication de la question** — L'agence européenne Frontex coordonne la gestion des frontières extérieures de l'UE. L'EASO (devenue EUAA) coordonne les politiques d'asile entre États membres.

**Proposition du modèle — `inst_ue`** (L'Union européenne) · confiance **0.85**
> Frontex et EUAA sont des agences de l'Union européenne gérant les politiques migratoires communes.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 116. Quelle institution gère les finances et le budget de l'État ?

*Institutions · Naturalisation*

- Préparé par le gouvernement, voté par le Parlement, contrôlé par la Cour des comptes ← **bonne réponse**
- Décidé par le pape
- Voté par les maires
- Aucun budget officiel

**Explication de la question** — Le budget de l'État est préparé par le gouvernement (ministère de l'Économie et des Finances), voté par le Parlement chaque automne, et son exécution est contrôlée par la Cour des comptes.

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.85**
> Préparation et contrôle du budget par le gouvernement/Cour des comptes.

**Alternative du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 117. Quelle institution évalue l'exécution des politiques publiques et les comptes de l'État ?

*Institutions · Naturalisation*

- La Cour des comptes ← **bonne réponse**
- Le Conseil constitutionnel
- L'Assemblée nationale seule
- L'ONU

**Explication de la question** — La Cour des comptes est une juridiction financière indépendante qui contrôle l'usage des fonds publics et publie des rapports souvent commentés dans le débat public.

**Proposition du modèle — `inst_gouvernement`** (Le gouvernement et l'administration de l'État) · confiance **0.85**
> Cour des comptes, contrôle des finances publiques.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 118. Quelle proposition décrit correctement le statut des partis politiques en France ?

*Institutions · Carte de résident*

- Plusieurs partis peuvent exister et concourir librement aux élections ← **bonne réponse**
- Un seul parti unique est autorisé
- Les partis sont interdits par la Constitution
- Seuls deux partis sont autorisés

**Explication de la question** — Les partis politiques sont libres : plusieurs partis peuvent exister, défendre des idées différentes et participer aux élections. C'est le principe du pluralisme politique.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.85**
> Pluralisme des partis politiques, encadrement de la vie politique.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 119. Quelle région française est célébrée pour la production de champagne ?

*Histoire, géo et culture · Carte de résident*

- La Champagne (région viticole protégée) ← **bonne réponse**
- La Bretagne
- La Provence
- La Corse

**Explication de la question** — Le champagne est produit dans la région viticole de Champagne, située dans le Grand Est. Le terme 'champagne' est une appellation d'origine contrôlée protégée.

**Proposition du modèle — `hg_art_de_vivre`** (Gastronomie, sport et art de vivre) · confiance **0.85**
> Le champagne comme produit/boisson emblématique de la France.

**Alternative du modèle — `hg_geographie`** (Géographie de la France et outre-mer) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 120. Quelle ville accueille la cathédrale de Notre-Dame, restaurée après l'incendie de 2019 ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Paris ← **bonne réponse**
- Reims
- Strasbourg
- Lyon

**Explication de la question** — Notre-Dame de Paris, gravement endommagée par un incendie en avril 2019, a été rouverte au public le 7 décembre 2024 après une restauration majeure.

**Proposition du modèle — `hg_geographie`** (Géographie de la France et outre-mer) · confiance **0.85**
> Question sur la ville où se trouve Notre-Dame, localisation.

**Alternative du modèle — `hg_patrimoine`** (Monuments et sites emblématiques) · confiance **0.60**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 121. Quelle ville est appelée la 'ville lumière' ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Paris ← **bonne réponse**
- Marseille
- Lyon
- Toulouse

**Explication de la question** — Paris est surnommée la 'ville lumière' depuis le XVIIIe siècle. Ce surnom évoque à la fois son rayonnement intellectuel et sa précocité dans l'éclairage public urbain.

**Proposition du modèle — `hg_geographie`** (Géographie de la France et outre-mer) · confiance **0.85**
> Surnom d'une grande ville.

**Alternative du modèle — `hg_patrimoine`** (Monuments et sites emblématiques) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 122. Quels représentants sont élus lors des élections législatives ?

*Institutions · Carte de séjour pluriannuelle*

- Les députés ← **bonne réponse**
- Les sénateurs
- Le président de la République
- Les maires

**Explication de la question** — Les élections législatives permettent d'élire les députés qui siègent à l'Assemblée nationale. Ils représentent les circonscriptions.

**Proposition du modèle — `inst_elections`** (Les élections et le droit de vote) · confiance **0.85**
> Élections législatives vues du scrutin, élection des députés.

**Alternative du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 123. Qui a rédigé la Déclaration des droits de la femme en 1791 ?

*Histoire, géo et culture · Carte de résident*

- Olympe de Gouges ← **bonne réponse**
- Simone Veil
- Marie Curie
- Marie-Antoinette

**Explication de la question** — Olympe de Gouges (1748-1793) a rédigé la Déclaration des droits de la femme et de la citoyenne en 1791, en réponse à la DDHC qui excluait les femmes. Elle a été guillotinée en 1793.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.85**
> Olympe de Gouges, figure de la Révolution française et de ses acteurs.

**Alternative du modèle — `hg_conquetes_droits`** (Les conquêtes sociales et les transformations de la société) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 124. Qui était Jeanne d'Arc, héroïne française ?

*Histoire, géo et culture · Carte de séjour pluriannuelle*

- Une héroïne française du XVe siècle ← **bonne réponse**
- Une reine de France
- Une scientifique
- Une chanteuse

**Explication de la question** — Jeanne d'Arc (1412-1431) est une héroïne française du Moyen Âge. Elle a libéré Orléans, conduit Charles VII à Reims pour son sacre, puis a été brûlée vive à Rouen.

**Proposition du modèle — `hg_revolution`** (Les rois de France et la Révolution) · confiance **0.85**
> Jeanne d'Arc, figure des rois de France et Ancien Régime.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 125. Qui était Joséphine Baker ?

*Histoire, géo et culture · Naturalisation*

- Une chanteuse américano-française et résistante (au Panthéon) ← **bonne réponse**
- Une scientifique
- Une reine d'Angleterre
- Une politicienne contemporaine

**Explication de la question** — Joséphine Baker (1906-1975), américaine devenue française, était une chanteuse, danseuse et résistante. Première femme noire entrée au Panthéon en 2021 pour son engagement contre le racisme et pour la France libre.

**Proposition du modèle — `hg_arts_sciences`** (Artistes et savants français) · confiance **0.85**
> Chanteuse et résistante, reconnue comme artiste célèbre.

**Alternative du modèle — `hg_guerres_resistance`** (Les guerres du XXᵉ siècle et la décolonisation) · confiance **0.50**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 126. Un agent public peut-il accepter de l'argent pour rendre un service ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Non, c'est de la corruption, un délit grave ← **bonne réponse**
- Oui, c'est une coutume
- Uniquement sur les marchés
- Uniquement le dimanche

**Explication de la question** — Non. Accepter de l'argent ou un avantage pour rendre un service public est de la corruption, un délit grave puni par la loi.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.85**
> Probité de l'agent public, devoir cité explicitement dans la notion.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 127. Un citoyen peut-il visiter l'Assemblée nationale ?

*Institutions · Carte de séjour pluriannuelle*

- Oui, lors des visites organisées ← **bonne réponse**
- Non, l'accès est interdit à tous
- Uniquement les ambassadeurs étrangers
- Uniquement les militaires

**Explication de la question** — Oui. L'Assemblée nationale (Palais Bourbon) et le Sénat (palais du Luxembourg) sont ouverts au public lors de visites organisées, notamment pendant les Journées du patrimoine.

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.85**
> Visite de l'Assemblée nationale, institution parlementaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 128. Un ministre commet une infraction. Échappe-t-il à la justice ?

*Institutions · Naturalisation*

- Non, il peut être jugé comme tout citoyen ← **bonne réponse**
- Oui, les ministres ont une immunité totale
- Oui, jusqu'à la fin de son mandat
- Oui, seul le président peut le juger

**Explication de la question** — Non. Un ministre, comme tout citoyen, doit répondre de ses actes devant la justice. Pour les actes commis dans l'exercice de ses fonctions, il est jugé par la Cour de justice de la République.

**Proposition du modèle — `inst_justice`** (La justice, les tribunaux et les magistrats) · confiance **0.85**
> Jugement d'un ministre, Cour de justice de la République.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 129. Un parent peut-il frapper son enfant en France ?

*Droits et devoirs · Carte de séjour pluriannuelle*

- Non, les violences éducatives sont interdites ← **bonne réponse**
- Oui, sans condition
- Uniquement la mère
- Uniquement les jours fériés

**Explication de la question** — Non. La loi de 2019 a inscrit dans le Code civil l'interdiction des violences éducatives ordinaires (châtiments corporels et humiliations).

**Proposition du modèle — `dd_interdits_quotidien`** (Ce qui est interdit au quotidien, et ce qu'on risque) · confiance **0.85**
> Interdiction concrète des violences éducatives, un geste précis.

**Alternative du modèle — `dd_droits_sociaux`** (Travailler, se soigner, être logé, aller à l'école : les droits sociaux) · confiance **0.40**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 130. Une loi votée par le Parlement s'applique-t-elle à toute la France ?

*Institutions · Carte de séjour pluriannuelle*

- Oui, sur tout le territoire national ← **bonne réponse**
- Non, uniquement à Paris
- Uniquement dans la commune où elle est votée
- Uniquement la première année

**Explication de la question** — Oui. Une loi votée par le Parlement et promulguée par le président s'applique sur tout le territoire national, sauf disposition spécifique pour l'outre-mer.

**Proposition du modèle — `inst_parlement`** (Le Parlement : Assemblée nationale et Sénat) · confiance **0.85**
> Portée nationale de la loi votée, travail parlementaire.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 131. À quelle fréquence les élections européennes sont-elles organisées ?

*Institutions · Carte de résident*

- Tous les 5 ans ← **bonne réponse**
- Tous les ans
- Tous les 3 ans
- Tous les 10 ans

**Explication de la question** — Les élections européennes ont lieu tous les 5 ans, simultanément dans tous les États membres de l'UE.

**Proposition du modèle — `inst_ue`** (L'Union européenne) · confiance **0.85**
> Fréquence des élections européennes.

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 132. Qu'est-ce que le 'devoir de fraternité' reconnu en France ?

*Droits et devoirs · Naturalisation*

- Un principe constitutionnel découlant de la devise républicaine (2018) ← **bonne réponse**
- Une obligation religieuse
- Une simple coutume
- Aucune valeur juridique

**Explication de la question** — Le Conseil constitutionnel a reconnu en 2018 le principe de fraternité comme principe à valeur constitutionnelle, découlant de la devise républicaine. Il a notamment justifié l'aide humanitaire désintéressée.

**Proposition du modèle — `dd_devoirs_citoyen`** (Les devoirs du citoyen : la loi, l'impôt, la défense, l'environnement) · confiance **0.88**
> Devoir de fraternité cité explicitement dans les devoirs constitutionnels

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

### 133. Sur quels bâtiments le drapeau français est-il obligatoirement déployé ?

*Principes et valeurs · Carte de séjour pluriannuelle*

- Les bâtiments publics ← **bonne réponse**
- Les commerces de centre-ville
- Les immeubles d'habitation
- Les gares et aéroports uniquement

**Explication de la question** — Le drapeau est arboré sur les bâtiments publics : mairies, préfectures, écoles, tribunaux, ministères, casernes. Il marque la présence de la République.

**Proposition du modèle — `pv_symboles_devise`** (Les symboles et la devise de la République) · confiance **0.88**
> Affichage obligatoire du drapeau sur bâtiments publics.

**Alternative du modèle — _aucune notion correspondante_** · confiance **0.10**
> _Le modèle n'a pas justifié cette alternative séparément._

**Ton verdict :** ☐ Valider  ☐ Corriger → `________________`  ☐ Rejeter  ☐ Passer

---

