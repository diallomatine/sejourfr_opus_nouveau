# SejourFR — Guide de génération des `production_tasks` TCF

> **À l'attention de Claude Code (ou de tout générateur de contenu)**
>
> Ce document décrit les règles à respecter pour créer de nouvelles tâches d'expression orale (EO) ou écrite (EE) du TCF IRN. Il garantit la cohérence pédagogique, la rigueur CECRL, et la compatibilité technique avec le moteur d'évaluation IA (Whisper + Claude).
>
> **Règle d'or** : ne jamais inventer une structure ou un critère. Tout sujet doit suivre les patterns décrits ici. Toute déviation doit être justifiée explicitement.

---

## 1. Périmètre

Ce guide couvre la génération de tâches pour :

- **TCF Expression Orale** (`TCF_EO`) — tâches 1, 2, 3
- **TCF Expression Écrite** (`TCF_EE`) — tâches 1, 2, 3
- **Niveaux** : A2, B1, B2 uniquement (les autres niveaux CECRL ne font pas partie du TCF IRN)

Les épreuves QCM (CO, CE, structure, civique) sont **hors-périmètre** : elles utilisent la table `questions`, pas `production_tasks`.

---

## 2. Structure obligatoire d'une `production_task`

Chaque tâche est un INSERT SQL avec les champs suivants. **Aucun champ ne doit être omis ou inventé**.

```sql
INSERT INTO production_tasks (
    id, epreuve, tache_numero, niveau_cible,
    consigne, contexte,
    duree_max_sec, mots_min, mots_max,
    criteres_evaluation, is_active
) VALUES (
    gen_random_uuid(),
    '<TCF_EO|TCF_EE>',
    <1|2|3>,
    '<A2|B1|B2>',
    '<consigne>',
    '<contexte>',
    <duree_en_secondes_pour_EO_OR_NULL_pour_EE>,
    <mots_min_pour_EE_OR_NULL_pour_EO>,
    <mots_max_pour_EE_OR_NULL_pour_EO>,
    '<json_criteres_evaluation>'::jsonb,
    TRUE
);
```

### Contraintes techniques à respecter

- `epreuve` ∈ {`TCF_EO`, `TCF_EE`} **uniquement**
- `tache_numero` ∈ {1, 2, 3} **uniquement**
- `niveau_cible` ∈ {`A2`, `B1`, `B2`} **uniquement**
- Si `epreuve = TCF_EO` : `duree_max_sec` rempli, `mots_min` et `mots_max` = NULL
- Si `epreuve = TCF_EE` : `mots_min` et `mots_max` remplis, `duree_max_sec` = NULL
- `criteres_evaluation` : JSONB structuré (voir section 5)
- `is_active` : par défaut `TRUE` pour les sujets validés, `FALSE` pour les brouillons

### Échappement des apostrophes en SQL

Toutes les apostrophes dans `consigne`, `contexte` et le JSON doivent être **doublées** : `l''examinateur`, `d''une part`, etc.

---

## 3. Paramètres de durée et de longueur

### Expression Orale (`TCF_EO`)

| Tâche | `duree_max_sec` |
|---|---|
| Tâche 1 (entretien dirigé) | 180 |
| Tâche 2 (jeu de rôle) | 210 |
| Tâche 3 (point de vue) | 210 |

### Expression Écrite (`TCF_EE`)

| Tâche | `mots_min` | `mots_max` |
|---|---|---|
| Tâche 1 (message court) | 60 | 120 |
| Tâche 2 (récit / expérience) | 120 | 150 |
| Tâche 3 (point de vue argumenté) | 150 | 180 |

Ces valeurs sont **non négociables** : elles correspondent au format officiel du TCF IRN.

---

## 4. Règles d'écriture par tâche

### 4.1 Tâche 1 — Entretien dirigé / Message court

**Objectif pédagogique** : production simple sur soi-même ou sur un sujet familier du quotidien.

**Sujets autorisés** : vie personnelle, travail, études, famille, loisirs, projets, vie quotidienne, présentation de soi.

**Consigne — pattern** :
> "Présentez-vous." / "Parlez de..." / "Écrivez un message pour..."

**Contexte — pattern** :
- Décrire la situation déclencheuse en 1-2 phrases
- Préciser le destinataire (pour l'EE)
- Indiquer la durée ou la longueur attendue

**Exemple consigne EO niveau A2** :
> "Présentez-vous. Parlez de votre vie quotidienne, de votre travail ou de vos études, de votre famille, de vos loisirs et de vos projets en France."

**Exemple consigne EE niveau A2** :
> "Vous venez d'arriver en France. Écrivez un message à un(e) ami(e) resté(e) dans votre pays pour lui raconter votre installation, votre logement et vos premières impressions."

**À éviter** :
- Sujets abstraits (philosophie, opinions politiques)
- Sujets nécessitant une connaissance spécialisée
- Consignes trop ouvertes ("parlez de ce que vous voulez")

---

### 4.2 Tâche 2 — Jeu de rôle / Récit ou message fonctionnel

**Objectif pédagogique** : interaction en situation pratique (oral) ou production fonctionnelle (écrit).

**Sujets autorisés** :
- Démarches administratives (préfecture, CAF, sécu)
- Logement (location, agence, syndic)
- Travail (entretien d'embauche, demande de congé)
- Voyage / transport (SNCF, agence)
- Santé (rendez-vous, pharmacie)
- Commerces et services (réclamation, achat)
- Vie scolaire (école des enfants, inscription)

**Consigne EO — pattern** :
> "Vous [situation]. Vous [appelez|rencontrez|contactez] [interlocuteur]. Posez les questions nécessaires pour [objectif]."

**Consigne EE — pattern** :
> "Vous [situation]. Écrivez un [email|courrier|message] à [destinataire] pour [objectif]."

**Contexte — éléments à inclure obligatoirement** :
- Scénario complet et réaliste (durée, lieu, personnes impliquées)
- Contraintes chiffrées (budget, dates, nombre de personnes)
- Objectif final clair (au moins 6 questions, ou demander 3 informations précises)
- Pour l'EO : préciser que l'interlocuteur est fictif et que c'est un monologue de l'utilisateur qui simule l'interaction

**Exemple consigne EO niveau B1** (logement) :
> "Vous cherchez un appartement à louer à Paris pour vous et votre famille. Vous contactez une agence immobilière pour obtenir des informations. Posez toutes les questions nécessaires pour choisir un logement adapté."

**Exemple consigne EE niveau B1** (réclamation) :
> "Vous avez acheté un téléphone sur un site internet il y a deux semaines. À la réception, vous avez constaté que l'écran était fissuré. Écrivez un courriel au service client pour exposer le problème et demander une solution."

**À éviter** :
- Situations irréalistes ou folkloriques
- Scénarios sans contrainte (l'utilisateur ne sait pas quoi demander)
- Situations qui supposent une réponse de l'interlocuteur (impossible en monologue)

---

### 4.3 Tâche 3 — Point de vue argumenté

**Objectif pédagogique** : argumentation construite sur un sujet de société accessible.

**Sujets autorisés** :
- Modes de vie (ville vs campagne, mer vs montagne)
- Technologies du quotidien (réseaux sociaux, télétravail, écrans)
- Habitudes (alimentation, sport, transport)
- Vie en société (générations, environnement, consommation)
- Comparaisons culturelles non clivantes

**Consigne — pattern** :
> "À votre avis, [question binaire ou ouverte] ? Expliquez votre opinion en présentant [les avantages et inconvénients|les deux côtés|différents points de vue], puis donnez votre choix personnel avec des exemples concrets."

**Contexte — pattern** :
> "Parlez pendant environ 3 minutes." / "Écrivez environ X mots."
> "Présentez les deux côtés avant de donner votre choix personnel."
> "Justifiez votre opinion avec des arguments et des exemples concrets."
> "Utilisez des connecteurs logiques pour relier vos idées."

**Exemple consigne EO niveau B2** :
> "À votre avis, est-il préférable de vivre à la mer ou à la montagne ? Expliquez votre opinion en présentant les avantages et les inconvénients des deux options, puis donnez votre choix personnel avec des exemples concrets."

**Exemple consigne EE niveau B2** :
> "Certaines personnes pensent que les réseaux sociaux rapprochent les gens, d'autres au contraire qu'ils les isolent. Quel est votre point de vue ? Donnez votre opinion en présentant les arguments des deux côtés, puis justifiez votre position avec des exemples concrets."

**Sujets interdits** :
- Politique partisane (élections, partis, personnalités)
- Religion
- Conflits géopolitiques actuels
- Sujets identitaires sensibles (immigration en tant que débat, genre, etc.)
- Sujets qui supposent une connaissance spécialisée (économie, sciences pointues)

---

## 5. Structure des critères d'évaluation

### Règle générale : exactement 4 critères

Chaque `criteres_evaluation` contient **exactement 4 critères pondérés**. Pas 3, pas 5, pas 6.

La somme des poids = 1.00 exactement.

### Critères autorisés par tâche

#### Tâche 1 (entretien / message simple)

| Code | Label | Plage de poids |
|---|---|---|
| `pertinence` | Pertinence des informations données | 0.25 - 0.35 |
| `vocabulaire` | Vocabulaire de la vie quotidienne | 0.20 - 0.30 |
| `grammaire` | Maîtrise des structures simples | 0.20 - 0.30 |
| `clarte_orale` (EO) / `clarte_ecrite` (EE) | Clarté et fluidité / lisibilité | 0.15 - 0.25 |

#### Tâche 2 (jeu de rôle / message fonctionnel)

| Code | Label | Plage de poids |
|---|---|---|
| `pertinence_questions` (EO) / `pertinence_demande` (EE) | Pertinence et variété des questions / clarté de la demande | 0.30 - 0.40 |
| `interaction` (EO) / `politesse_registre` (EE) | Capacité à interagir / registre adapté au destinataire | 0.15 - 0.25 |
| `vocabulaire_<domaine>` | Vocabulaire spécifique au domaine (logement, santé, travail...) | 0.20 - 0.30 |
| `grammaire` | Correction grammaticale générale | 0.15 - 0.25 |

#### Tâche 3 (point de vue argumenté)

| Code | Label | Plage de poids |
|---|---|---|
| `argumentation` | Qualité et nuance de l'argumentation | 0.30 - 0.40 |
| `organisation` | Organisation et cohérence du discours | 0.20 - 0.30 |
| `lexique` | Richesse et précision du vocabulaire | 0.15 - 0.25 |
| `grammaire_complexe` | Maîtrise des structures complexes | 0.15 - 0.25 |

### Critère interdit : `prononciation`

**Ne jamais utiliser le code `prononciation`.** Whisper transcrit mais n'évalue pas la phonétique. Utiliser `clarte_orale` (qui couvre fluidité, hésitations, intelligibilité globale via la transcription).

### Format JSON exact

```json
{
  "criteres": [
    { "code": "<code>", "label": "<label>", "poids": <decimal> },
    { "code": "<code>", "label": "<label>", "poids": <decimal> },
    { "code": "<code>", "label": "<label>", "poids": <decimal> },
    { "code": "<code>", "label": "<label>", "poids": <decimal> }
  ],
  "niveau_attendu": "<A2|B1|B2>",
  "consignes_correcteur": "<texte>"
}
```

---

## 6. Règles d'écriture des `consignes_correcteur`

C'est **le champ le plus important** du dispositif. Il pilote la qualité de l'évaluation IA.

### Structure obligatoire

Chaque `consignes_correcteur` doit contenir :

1. **Niveau visé** : phrase d'amorce qui rappelle le niveau (`Niveau A2.`, `Niveau B1.`, `Niveau B2.`)
2. **Seuils observables et chiffrés** : au moins un critère quantifié (nombre de thèmes, nombre de questions, présence d'éléments spécifiques)
3. **Vocabulaire attendu** (tâches 2 et 3) : liste de mots-clés que le candidat est censé employer
4. **Structures grammaticales attendues** : temps verbaux, modes, constructions
5. **Pénalisations explicites** : ce qui fait baisser la note (au moins un comportement à pénaliser)
6. **Récompenses explicites** : ce qui mérite des points bonus (au moins un comportement à récompenser)

### Exemples de seuils chiffrés acceptables

- "au moins 3 thèmes parmi : travail/études, famille, loisirs, projets"
- "au moins 6 questions pertinentes"
- "au moins 2 arguments par option"
- "varier au moins 3 structures interrogatives"
- "utiliser au moins 4 connecteurs logiques différents"

### Exemples de pénalisations

- "Pénaliser une succession monotone de 'est-ce que...' sans variation"
- "Pénaliser un discours déséquilibré (oubli d'une des deux options)"
- "Pénaliser si le candidat reste sur des phrases isolées sans développer"
- "Pénaliser les arguments purement personnels sans portée générale"

### Exemples de récompenses

- "Récompenser les questions de relance ('et concernant... ?')"
- "Récompenser la capacité à reformuler"
- "Récompenser les nuances et la capacité à reconnaître les limites de sa propre position"
- "Récompenser les exemples concrets tirés de la vie en France"

### Adaptation au niveau CECRL

| Niveau | Tolérance erreurs | Structures attendues | Sophistication |
|---|---|---|---|
| **A2** | Forte (si compréhension OK) | Présent, passé composé, futur proche, phrases simples coordonnées | Vocabulaire concret, sujets familiers |
| **B1** | Moyenne | + imparfait, subjonctif présent simple, conditionnel, subordonnées de base | Vocabulaire élargi à des domaines pratiques |
| **B2** | Faible | + subjonctif après "bien que/pour que/avant que", conditionnel pour atténuer, subordination complexe | Vocabulaire abstrait, nuances, registre soutenu possible |

---

## 7. Catalogue de référence : nombre de tâches à générer

Objectif initial : **18 tâches** (couverture complète du module TCF productif).

| Épreuve | Niveau | Tâche 1 | Tâche 2 | Tâche 3 | Total |
|---|---|---|---|---|---|
| TCF_EO | A2 | 1 | 1 | 1 | 3 |
| TCF_EO | B1 | 1 | 1 | 1 | 3 |
| TCF_EO | B2 | 1 | 1 | 1 | 3 |
| TCF_EE | A2 | 1 | 1 | 1 | 3 |
| TCF_EE | B1 | 1 | 1 | 1 | 3 |
| TCF_EE | B2 | 1 | 1 | 1 | 3 |
| **Total** | | | | | **18** |

Pour aller plus loin : objectif phase 2 de **60 tâches** (10 variantes par cellule du tableau) pour permettre du tirage aléatoire et limiter la triche.

---

## 8. Bons réflexes culturels et inclusion

### Adapter au public cible

Les utilisateurs de SejourFR sont des étrangers en cours d'installation en France. Les sujets doivent refléter **leur réalité quotidienne**, pas la vie d'un étudiant français lambda.

**Sujets pertinents pour ce public** :
- Démarches administratives (préfecture, OFII, CAF, sécurité sociale)
- Apprentissage du français au quotidien
- Adaptation culturelle, comparaisons avec le pays d'origine (sans stéréotype)
- Recherche d'emploi / équivalence de diplôme
- Logement social, garant, dossier locatif
- École des enfants, périscolaire
- Vie associative locale, voisinage

**Sujets à éviter** :
- Vacances de luxe, voyages exotiques
- Sorties culturelles élitistes
- Références à des marques ou personnalités françaises sans intérêt général

### Diversité dans les contextes

Quand on génère plusieurs tâches du même type, varier :
- Les prénoms (mix de prénoms internationaux : Aïssatou, Mehdi, Wei, Sofia, Jean, Fatima...)
- Les villes (ne pas tout situer à Paris : Lyon, Marseille, Lille, Bordeaux, Strasbourg, Nantes, Toulouse, Rennes)
- Les configurations familiales (célibataire, couple, famille monoparentale, famille recomposée)
- Les origines géographiques implicites (sans caricature)

### Neutralité religieuse et politique

Ne jamais inclure :
- Références religieuses (fêtes, lieux de culte, pratiques)
- Opinions politiques explicites
- Sujets clivants sur l'immigration

---

## 9. Workflow recommandé pour Claude Code

Quand on demande à Claude Code de générer N nouvelles tâches :

1. **Lire ce guide en entier** avant toute génération
2. **Choisir la cellule du tableau** (épreuve × niveau × tâche)
3. **Vérifier ce qui existe déjà** dans `production_tasks` pour cette cellule (éviter les doublons thématiques)
4. **Choisir un thème** dans le catalogue autorisé (section 4) en variant des précédents
5. **Écrire la consigne** en suivant le pattern de la section 4
6. **Écrire le contexte** avec les contraintes concrètes requises
7. **Construire `criteres_evaluation`** en suivant la section 5 (4 critères, somme 1.00)
8. **Rédiger `consignes_correcteur`** avec les 6 éléments obligatoires (section 6)
9. **Valider** : seuil chiffré présent ? vocabulaire attendu listé ? pénalisations explicites ?
10. **Produire le SQL** avec les apostrophes doublées
11. **Marquer `is_active = FALSE`** par défaut pour validation humaine

### Format de livraison attendu

Un seul fichier SQL `V<N>__seed_production_tasks_<batch>.sql` avec :
- Un commentaire en tête expliquant la batch
- Un `INSERT INTO production_tasks` groupé pour toutes les tâches
- Un commentaire séparateur visible entre chaque tâche (`-- ============ TCF_EO TÂCHE 1 A2 ============`)
- Un commentaire en fin de fichier indiquant le nombre total de tâches insérées (assertion)

---

## 10. Validation manuelle obligatoire

**Aucune `production_task` générée par IA ne doit être activée (`is_active = TRUE`) sans relecture humaine.**

Checklist de validation pour chaque tâche :

- [ ] La consigne est en français naturel, sans tournure scolaire ou maladroite
- [ ] Le contexte donne assez d'informations pour produire 2-3 min d'audio ou 60-180 mots
- [ ] Le thème est pertinent pour le public cible
- [ ] Le niveau CECRL est cohérent avec les exigences (descripteurs officiels)
- [ ] Les 4 critères sont bien choisis pour le type de tâche
- [ ] La somme des poids = 1.00 exactement
- [ ] `consignes_correcteur` contient un seuil chiffré observable
- [ ] `consignes_correcteur` mentionne le vocabulaire ou les structures attendus
- [ ] `consignes_correcteur` précise au moins une pénalisation et une récompense
- [ ] Pas de sujet clivant (politique, religion, identitaire)
- [ ] Pas de prénom ou de référence stéréotypée
- [ ] Apostrophes correctement échappées en SQL
- [ ] `epreuve`, `tache_numero`, `niveau_cible` respectent les enums autorisés
- [ ] Cohérence `duree_max_sec` XOR `mots_min`/`mots_max`

Une fois validée, passer `is_active` à `TRUE` via une migration séparée :
```sql
UPDATE production_tasks SET is_active = TRUE WHERE id = '<uuid>';
```

---

## 11. Exemples de référence (à imiter)

Trois exemples canoniques validés (version v3) sont disponibles dans `V<N>__seed_production_tasks_initial.sql`. Ils couvrent :

- `TCF_EO` tâche 1 niveau A2 (entretien sur la vie quotidienne)
- `TCF_EO` tâche 2 niveau B1 (jeu de rôle agence immobilière)
- `TCF_EO` tâche 3 niveau B2 (opinion mer vs montagne)

Toute nouvelle tâche doit être **structurellement comparable** à ces trois exemples : même densité d'informations, même style de `consignes_correcteur`, même niveau de précision.

---

## 12. Mises à jour de ce guide

Ce guide est versionné. Toute modification d'une règle doit :

1. Incrémenter la version en tête de fichier
2. Documenter le changement dans une section CHANGELOG
3. Vérifier la rétro-compatibilité des tâches déjà en base
4. Si nécessaire, créer une migration pour aligner les anciennes tâches

### Version actuelle

**v1.0** — Première publication. Synchronisé avec `PRODUCTION_TASKS_SPEC_V2.md`.

### CHANGELOG

| Version | Date | Changements |
|---|---|---|
| v1.0 | initial | Création initiale, 4 critères par tâche, `clarte_orale` au lieu de `prononciation`, seuils chiffrés obligatoires |
