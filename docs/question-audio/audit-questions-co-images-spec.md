# Brief Claude Code — Audit : questions TCF CO avec image (import par lot)

## ⛔ AUDIT UNIQUEMENT

Aucune implémentation. Ne créer aucun des éléments suivants :
- migration ;
- endpoint ;
- composant ;
- importeur ;
- service IA ;
- modification R2 ;
- modification de fichier applicatif.

**Seul fichier autorisé :** `docs/question-audio/audit-questions-co-images.md`

Je lirai le rapport et je donnerai un GO explicite avant tout développement.

---

## 1. Contexte

Certaines questions `TCF_CO` utilisent aujourd'hui des illustrations SVG abstraites, peu fidèles au TCF.

Objectif : produire **par lot**, par exemple 10 questions et leurs 10 images générées par une IA externe, puis les importer dans l'admin sans saisie champ par champ.

### Format TCF visé (important)

Ce brief concerne **un seul format de CO**, appelé ici `IMAGE_PROPOSITIONS`. Il fonctionne ainsi :

1. **À l'écran :** une image et 4 boutons `A` `B` `C` `D`, **sans aucun texte de proposition**.
2. **Dans l'audio :** les 4 propositions sont lues à la suite (« A. … B. … C. … D. … »), en une seule écoute.
3. **Réponse :** le candidat choisit la proposition qui correspond à la scène.

Exemple (style d'un livret TCF) :

- **Image :** un couple descend l'allée d'un cinéma ; l'homme montre deux sièges.
- **Audio :**
  - « A. C'est un acteur formidable.
  - B. Je déteste la publicité.
  - C. Viens, on va s'asseoir là.
  - D. Tu vas payer nos billets. »
- **Bonne réponse :** C

Conséquences sur les données :

- **L'ordre des choix doit rester figé.** Aucun mélange à l'affichage, sinon l'audio ne correspond plus aux lettres.
- **Le texte audio est dérivé des `choices`.** Il ne doit pas exister comme champ libre indépendant, pour éviter toute incohérence.
- **L'image donne le contexte.** Les distracteurs doivent rester plausibles lexicalement, mais être faux par rapport à la scène.

Les autres formats CO du TCF ne sont **pas** dans le périmètre : dialogue suivi d'une question écrite, document long, etc.

### Droits

Les images des livrets officiels (France Éducation international) servent **uniquement de référence de style**. Elles ne doivent jamais être reproduites ni stockées.

---

## 2. Ce que l'audit doit établir

Ne rien supposer : vérifier dans le code **et** dans les migrations Flyway. Citer les fichiers et les lignes.

### 2.1 Modèle de données TCF_CO

Identifier les tables, entities, DTO, repositories, services et controllers. Préciser comment sont stockés :

- le type d'épreuve ;
- le niveau ;
- les choix (y compris leur ordre) ;
- la bonne réponse ;
- le texte source de l'audio ;
- l'audio final ;
- l'image ou le SVG ;
- l'état actif ou inactif.

Il faut aussi déterminer :

- **Le discriminant de format.** Existe-t-il un moyen de distinguer le format `IMAGE_PROPOSITIONS` des autres formats CO ? Si non, quelle serait l'évolution minimale ?
- **Les SVG actuels.** Sont-ils inline en base, générés dynamiquement, des fichiers, ou sur R2 ? Comment le front choisit-il quoi afficher ?
- **Les images classiques.** Peut-on afficher du PNG/JPG/WEBP depuis R2 **sans migration** ?

### 2.2 Player candidat (web et mobile)

- **Affichage des choix :** les textes sont-ils affichés pour les questions CO image ? Les choix sont-ils mélangés ? Si oui, où se fait le mélange, et peut-on le désactiver pour ce format ?
- **Chargement des images :** comment l'image est-elle chargée sur mobile (Flutter) ? Comment se passent le cache et l'éventuel mode hors ligne, pour un SVG inline comparé à une URL R2 ?
- **Rendu :** quel est le rendu d'une image en niveaux de gris, en thème clair et en thème sombre ?

### 2.3 Activation et exclusion côté candidat

Tracer le chemin complet du filtrage `active`, de la requête jusqu'à l'entraînement, à l'examen blanc et à la révision des erreurs.

Répondre précisément aux deux questions suivantes :

- Une question inactive est-elle exclue **partout** ?
- Une question **sans audio** peut-elle remonter côté candidat ?

### 2.4 Admin `/questions/tcf`

Documenter le fonctionnement actuel de la page :

- filtres ;
- recherche ;
- pagination ;
- édition ;
- activation ;
- statut audio ;
- affichage de l'image ;
- endpoints appelés.

Recommander ensuite **l'une** des deux options de filtre suivantes :

- **Option A :** une valeur « CO avec image » dans le filtre existant.
- **Option B :** un filtre générique `Image : Toutes / Avec / Sans`.

Préférer l'option générique si elle est cohérente avec l'existant.

Enfin, déterminer si un formulaire de création ou d'édition CO existe, et s'il gère un upload de fichier.

### 2.5 Cloudflare R2

Documenter l'existant :

- config ;
- client ;
- service ;
- buckets ;
- conventions de nommage ;
- upload depuis l'admin ;
- URL publique ou signée ;
- suppression ;
- permissions.

Signaler également ce qui existe ou manque côté validation des images :

- validation du type MIME ;
- limite de poids ;
- validation des dimensions ;
- resize et conversion WEBP.

Recommander un chemin de stockage cohérent avec l'existant.

### 2.6 Pipeline audio existant (Azure TTS)

Documenter :

- l'écran admin, les endpoints et les services ;
- la voix et le format (SSML ou non) ;
- le critère « question sans audio » ;
- le stockage de l'audio et son lien avec la question ;
- la génération unitaire et par lot.

Question clé : **le pipeline sait-il générer un audio à partir des 4 `choices`** (« A. … [pause] B. … ») ? Sinon, quelle est l'adaptation **minimale** ?

Ne proposer en aucun cas un second pipeline.

### 2.7 Briques IA existantes

Identifier :

- les services LLM (Claude Sonnet ou autre) ;
- les prompts TCF ;
- les structured outputs et JSON schemas ;
- les appels multimodaux ;
- la génération d'images.

Indiquer ce qui serait réutilisable pour la phase 3.

---

## 3. Import par lot (cœur du besoin)

### Workflow cible (phase 1)

```text
Admin « Importer des questions CO »
  ├─ Zone 1 : coller le JSON
  └─ Zone 2 : déposer N images (drag & drop)
        ↓
Analyser (aucune écriture)
        ↓
Preview : erreurs par question + aperçu image / choix / bonne réponse
        ↓
Importer
        ↓
Images → R2   |   Questions → DB en is_active = FALSE
        ↓
Pipeline audio existant
        ↓
Relecture → activation manuelle
```

**Règle :** toute question importée est **inactive par défaut**. Elle n'est activée qu'après la génération de l'audio et une relecture.

### Format d'import proposé (à challenger)

```json
{
  "version": "1",
  "type": "TCF_CO",
  "format": "IMAGE_PROPOSITIONS",
  "questions": [
    {
      "externalId": "co-a2-001",
      "level": "A2",
      "image": "co-a2-001.png",
      "sceneDescription": "Un couple descend l'allée d'un cinéma, l'homme montre deux sièges libres.",
      "choices": [
        "C'est un acteur formidable.",
        "Je déteste la publicité.",
        "Viens, on va s'asseoir là.",
        "Tu vas payer nos billets."
      ],
      "correctAnswer": "C"
    }
  ]
}
```

Principes du format :

- **Format stable, distinct des entities.** Le flux est : JSON → DTO + validation → mapper → entities existantes.
- **Pas de champ `audioText`.** L'audio est construit à partir de `choices`, dans l'ordre.
- **`sceneDescription` est conservé.** Il sert à régénérer l'image, au texte alternatif et à contrôler la cohérence entre l'image et les choix.
- **`correctAnswer` est une lettre.** La lettre est plus lisible et plus robuste qu'un index. À confirmer par rapport au modèle actuel.
- **Pas de métadonnées spéculatives.** Ne pas ajouter `batchId`, `generationModel`, etc. sans justification claire.

L'audit doit répondre aux questions suivantes :

1. Où placer les DTO, les validateurs et le mapper dans l'architecture actuelle ?
2. Quelles validations faire avant l'import ? Par exemple :
   - schéma ;
   - image présente et unique ;
   - niveau valide ;
   - exactement 4 choix non vides et distincts ;
   - lettre valide ;
   - `externalId` unique dans le lot et en base.
3. Faut-il importer **tout ou rien** (une transaction), ou accepter un import partiel ?
4. Comment garder R2 et la DB cohérents ? Que faire des images orphelines en cas d'échec ?
5. Comment gérer les doublons ? Recommander la stratégie la plus simple : un `externalId` persisté et unique, ou autre chose.

### Phases

| Phase | Contenu |
|---|---|
| 1 | JSON + images en drag & drop + preview + import |
| 2 | Import d'un fichier ZIP (`manifest.json` + `images/`). Dire si cette phase vaut la peine dès le MVP. |
| 3 | Génération IA depuis l'admin, en deux étapes (LLM → questions + `sceneDescription`, puis générateur d'images → images), **produisant le même format** et passant par **le même importeur** |

Variante de la phase 3 : je fournis une image, l'IA multimodale propose les choix et la bonne réponse, puis je modifie et valide avant l'import.

**Contrainte :** l'IA, le JSON et le ZIP convergent vers **un seul importeur**. Pas de second chemin technique.

### Charte visuelle

Proposer l'emplacement d'une charte d'images versionnée, en JSON, comme les autres configs du projet. Elle doit couvrir au minimum :

- trait noir et blanc ;
- ratio (par exemple 4:3) ;
- aucun texte dans l'image ;
- personnages neutres ;
- une seule action lisible par scène.

Elle servira de référence à toute génération future.

---

## 4. Rapport attendu

Fichier : `docs/question-audio/audit-questions-co-images.md`

**Contraintes de forme :**
- concis, avec des tableaux de préférence ;
- chaque affirmation sourcée par fichier et ligne ;
- pas de code d'implémentation.

**Structure :**

1. **Résumé exécutif**, avec des réponses courtes aux questions ci-dessous.
2. **Existant :**
   - modèle ;
   - images et SVG ;
   - player ;
   - activation ;
   - admin ;
   - R2 ;
   - audio ;
   - IA.
3. **Écarts** entre l'existant et le format `IMAGE_PROPOSITIONS`.
4. **Import :**
   - architecture ;
   - format JSON ajusté ;
   - validations ;
   - transaction ;
   - doublons ;
   - avis sur le ZIP.
5. **Architecture cible**, sous forme de schéma texte.
6. **Évolutions**, chacune classée **Nécessaire / Optionnel / À éviter**.
7. **Risques et points de vigilance.**
8. **Plan d'implémentation** par phase, avec un point STOP entre chaque phase.
9. **Liste des fichiers** qui seraient modifiés ou créés.

**Questions auxquelles le résumé doit répondre explicitement :**

1. Une question CO peut-elle déjà porter une image R2 ? Une migration est-elle nécessaire ?
2. Les choix sont-ils mélangés à l'affichage, et les textes sont-ils visibles ?
3. Une question inactive ou sans audio est-elle exclue partout côté candidat ?
4. Quelle option de filtre « avec image » recommandes-tu ?
5. Le pipeline audio peut-il lire les 4 propositions ? Sinon, quelle est l'adaptation minimale ?
6. Peut-on réutiliser R2 tel quel ? Quel chemin de stockage recommandes-tu ?
7. Où placer l'importeur ? Faut-il un import en tout ou rien ?
8. Quelles briques IA sont réutilisables pour la phase 3 ?

---

## ⛔ STOP

Une fois le rapport écrit, **arrête-toi**. Aucune implémentation, aucune migration, aucune modification applicative. J'attends le rapport avant de donner le GO.
