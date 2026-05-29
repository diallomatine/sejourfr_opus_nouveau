# Tâche Claude Code : Module d'entraînement Expression (EO + EE) — TCF IRN

## Contexte du projet

SejourFR est une app de préparation au TCF IRN (Spring Boot 4 / Java 21 / PostgreSQL / Flyway au back, Next.js React 19 TS au front web, Flutter au mobile). Le module **Compréhension (CO/CE)** fonctionne déjà en QCM (tables `questions`, `choices`, `attempts`).

On ajoute le module **Expression** : Expression Orale (EO) et Expression Écrite (EE). Contrairement au QCM, c'est de la **production libre** corrigée par IA (Claude), sans bonne réponse unique.

**L'existant à NE PAS casser** : une table `production_tasks` existe déjà (migration V130) avec 18 lignes seedées (9 EO + 9 EE). Sa structure :

```
production_tasks (
  id UUID PK,
  epreuve VARCHAR,        -- 'TCF_EO' | 'TCF_EE'
  tache_numero INT,       -- 1 | 2 | 3
  niveau_cible VARCHAR,   -- 'A2' | 'B1' | 'B2'  (voir migration ci-dessous)
  consigne TEXT,
  contexte TEXT,
  duree_max_sec INT,      -- EO
  mots_min INT,           -- EE
  mots_max INT,           -- EE
  criteres_evaluation JSONB,
  is_active BOOLEAN
)
```

## Réalités de l'examen officiel TCF IRN (à respecter absolument)

D'après les sujets officiels de France Éducation International :

**Expression Écrite (EE)** — 30 min, 3 tâches dans l'ordre :
- Tâche 1 : message simple, souvent en réponse à un déclencheur (ex. SMS de « Jenny »). Seuils : 30 mots min / 60 max.
- Tâche 2 : récit en réponse à un déclencheur (ex. message d'« Élise »). Seuils : 40 / 90.
- Tâche 3 : avis sur un forum/débat. Seuils : 40 / 90.
- Chaque tâche peut avoir un **déclencheur** (message d'un expéditeur fictif) affiché avant la zone de rédaction.

**Expression Orale (EO)** — 10 min, 3 tâches :
- Tâche 1 : entretien dirigé (se présenter). 3 min. Pas de support.
- Tâche 2 : exercice en interaction / jeu de rôle. 3 min 30. **A un support visuel** (ex. 3 photos de logements avec légendes). L'examen réel propose **5 sujets**, l'examinateur en choisit 1.
- Tâche 3 : exprimer goûts/opinions. 3 min 30. **5 sujets**, 1 choisi.

**Important** : l'examen réel **n'étiquette PAS les sujets par niveau CECRL**. Le candidat est évalué a posteriori sur l'échelle A1→C2. Donc le niveau ne doit PAS être un filtre obligatoire côté apprenant (il peut rester une indication interne pour trier la difficulté des entraînements).

## Vue produit (maquette fournie séparément)

Un fichier HTML de maquette est fourni (`design_page_entrainement_expression_orale_tcf.html`). **Respecte ce design** : structure des écrans, hiérarchie visuelle, composants. Le détail du flux y figure. Résumé du flux :

- 3 onglets globaux : **Entraînement** / **Examens** / **Corrections**
- 3 sous-onglets : **Tâche 1 / Tâche 2 / Tâche 3**
- Dans Entraînement : un carrousel de **Situations** (scénarios concrets), une carte **Consigne + plan d'aide**, une carte **Exemples de réponses** (modèles, avec audio pour EO), un **plan rapide**.
- Bas d'écran EO : panneau **Enregistrer** (micro). EE : zone de **rédaction** + compteur de mots.
- Onglet Corrections : historique des productions corrigées par IA (score /20, critères, points forts/erreurs, version améliorée).

Adapte les couleurs à la charte SejourFR (Bleu France `#1E3A8C`, Rouge France `#E1372F` réservé aux CTA critiques, Vert succès `#168F5B`, Encre `#0F1839`), même si la maquette utilise des bleus différents.

---

# ÉTAPE 1 — Migration base de données (Flyway)

Créer `V131__add_production_situations_examples_attempts.sql`.

## 1.1 Rendre `niveau_cible` optionnel sur `production_tasks`

```sql
ALTER TABLE production_tasks ALTER COLUMN niveau_cible DROP NOT NULL;
COMMENT ON COLUMN production_tasks.niveau_cible IS
  'Indicatif interne pour trier la difficulté. NON exposé comme filtre obligatoire à l''apprenant (l''examen TCF réel n''étiquette pas les sujets par niveau).';
```

## 1.2 Table `production_situations`

Scénarios concrets rattachés à une tâche. Pour EO Tâche 2/3, plusieurs situations = les « 5 sujets » de l'examen réel.

```sql
CREATE TABLE production_situations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES production_tasks(id) ON DELETE CASCADE,
    titre VARCHAR(150) NOT NULL,
    contexte TEXT NOT NULL,                  -- mise en situation présentée au candidat
    consigne TEXT,                           -- consigne spécifique si différente de la tâche
    role_candidat TEXT,                      -- jeu de rôle : rôle du candidat (T2 EO)
    role_examinateur TEXT,                   -- jeu de rôle : rôle joué par l'app/examinateur
    objectif TEXT,                           -- ce que le candidat doit accomplir
    declencheur JSONB,                       -- EE : message déclencheur {expediteur, avatar, texte}
    etapes JSONB,                            -- plan d'aide : [{icon, titre, aide}]
    niveau_indicatif VARCHAR(2) CHECK (niveau_indicatif IN ('A2','B1','B2')),
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_prod_situations_task ON production_situations(task_id);
CREATE INDEX idx_prod_situations_active ON production_situations(is_active);
```

## 1.3 Table `production_situation_medias` (supports visuels)

Pour l'EO Tâche 2 (photos de logements, etc.). Une situation peut avoir plusieurs supports. Flexibilité : SVG inline OU image hébergée (R2).

```sql
CREATE TABLE production_situation_medias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    situation_id UUID NOT NULL REFERENCES production_situations(id) ON DELETE CASCADE,
    type VARCHAR(10) NOT NULL CHECK (type IN ('IMAGE','SVG')),
    image_url TEXT,                          -- si type IMAGE (URL R2)
    inline_svg TEXT,                         -- si type SVG
    legende TEXT,                            -- ex. "Studio 20 m², centre-ville, meublé"
    alt_text TEXT NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    CONSTRAINT chk_media_source CHECK (
        (type = 'IMAGE' AND image_url IS NOT NULL) OR
        (type = 'SVG' AND inline_svg IS NOT NULL)
    )
);
CREATE INDEX idx_prod_sit_medias_situation ON production_situation_medias(situation_id);
```

## 1.4 Table `production_examples` (réponses modèles)

```sql
CREATE TABLE production_examples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    situation_id UUID NOT NULL REFERENCES production_situations(id) ON DELETE CASCADE,
    titre VARCHAR(150) NOT NULL,             -- "Réponse courte et naturelle"
    resume VARCHAR(255),
    contenu TEXT NOT NULL,                    -- texte complet du modèle
    audio_url TEXT,                           -- EO : audio Azure+R2 (NULL pour EE)
    plan_points JSONB,                        -- ["Bonjour + prénom", "Ville", ...]
    niveau_indicatif VARCHAR(2) CHECK (niveau_indicatif IN ('A2','B1','B2')),
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_prod_examples_situation ON production_examples(situation_id);
```

## 1.5 Table `production_attempts` (production user + correction IA)

```sql
CREATE TABLE production_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES production_tasks(id),
    situation_id UUID REFERENCES production_situations(id),  -- NULL si entraînement libre sur la tâche
    epreuve VARCHAR(10) NOT NULL,            -- 'TCF_EO' | 'TCF_EE'

    -- Production de l'utilisateur
    user_audio_url TEXT,                     -- EO : enregistrement sur R2
    user_transcript TEXT,                    -- EO : transcription auto (Azure STT/Whisper)
    user_text TEXT,                          -- EE : texte rédigé
    word_count INT,                          -- EE : compteur de mots
    duration_sec INT,                        -- EO : durée de l'enregistrement

    -- Correction IA
    statut VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        -- PENDING -> TRANSCRIBING (EO) -> CORRECTING -> DONE / ERROR
    ai_score INT,                            -- /20
    ai_niveau_estime VARCHAR(4),             -- 'A1'..'C2'
    ai_score_details JSONB,                  -- {pertinence:.., grammaire:.., ...}
    ai_points_forts TEXT,
    ai_erreurs JSONB,                        -- [{extrait, correction, explication}]
    ai_version_amelioree TEXT,
    ai_conseils TEXT,
    ai_raw_response JSONB,                    -- réponse brute (debug/audit)

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    corrected_at TIMESTAMP
);
CREATE INDEX idx_prod_attempts_user ON production_attempts(user_id);
CREATE INDEX idx_prod_attempts_task ON production_attempts(task_id);
CREATE INDEX idx_prod_attempts_statut ON production_attempts(statut);
```

---

# ÉTAPE 2 — Backend Spring Boot

Respecter la structure plate du projet : `com.sejourfr.app.{entity, repository, service, controller, dto, enums, config}`. DTOs en **records**.

## 2.1 Entities + Repositories

Créer les JPA entities et repositories Spring Data pour les 4 nouvelles tables. Mapper les colonnes JSONB en `String` ou type JSON selon la convention déjà utilisée pour `criteres_evaluation` dans l'entity existante de `production_tasks`.

## 2.2 DTOs (records)

- `ProductionTaskDto` (réutiliser / aligner sur l'existant)
- `ProductionSituationDto` (avec liste de medias et d'exemples imbriqués)
- `ProductionSituationMediaDto`
- `ProductionExampleDto`
- `ProductionAttemptDto` (production + correction)
- `SubmitTextAttemptRequest` (EE : task_id, situation_id?, user_text)
- `SubmitAudioAttemptRequest` (EO : task_id, situation_id?, audio en multipart ou URL R2 déjà uploadée)
- `CorrectionResultDto` (le résultat IA structuré)

## 2.3 Service `ProductionTrainingService`

Lecture du contenu d'entraînement :
- `listTasks(epreuve)` → les 3 tâches d'une épreuve
- `listSituations(taskId)` → situations actives d'une tâche, triées par display_order, avec medias + exemples
- `getSituation(situationId)` → détail complet

## 2.4 Service `ProductionCorrectionService`

Cœur du module. Pour une production user :

**Flux EE (texte)** :
1. Calculer `word_count`. Vérifier les bornes `mots_min`/`mots_max` de la tâche.
2. Appeler Claude (API Anthropic) avec un prompt construit à partir de : consigne de la tâche, contexte de la situation, `criteres_evaluation` (JSONB de la tâche), et le texte du candidat.
3. Demander à Claude une **sortie JSON stricte** (voir schéma ci-dessous).
4. Parser, peupler `production_attempts` (ai_score, ai_niveau_estime, ai_score_details, ai_points_forts, ai_erreurs, ai_version_amelioree, ai_conseils), statut → DONE.

**Flux EO (audio)** :
1. L'audio user est uploadé sur R2 (réutiliser le service R2 existant).
2. Transcrire l'audio (Azure Speech-to-Text — réutiliser l'intégration Azure existante, ou Whisper si déjà en place). Stocker `user_transcript`. statut → CORRECTING.
3. Même appel Claude que pour l'EE, mais sur le transcript, avec les critères EO (la grille inclut « prononciation » — préciser à Claude qu'il évalue sur la base du transcript et ne peut juger la prononciation réelle, donc pondérer ce critère prudemment ou le marquer « non évaluable automatiquement »).
4. Peupler l'attempt, statut → DONE.

**Choix du modèle Claude** : utiliser un modèle équilibré coût/qualité (Sonnet) plutôt qu'Opus pour la correction de masse. Activer le **prompt caching** sur la partie système du prompt (grille + instructions) car elle est identique entre toutes les corrections d'une même tâche — gros gain de coût.

**Schéma JSON attendu de Claude** (le service doit demander EXACTEMENT ce format, sans texte autour) :

```json
{
  "score_sur_20": 14,
  "niveau_estime": "B1",
  "criteres": {
    "pertinence": 15,
    "grammaire": 13,
    "vocabulaire": 14,
    "coherence": 14,
    "prononciation": null
  },
  "points_forts": "Texte clair, consigne respectée, bon emploi du passé composé.",
  "erreurs": [
    {"extrait": "j'ai été à Paris", "correction": "je suis allé à Paris", "explication": "verbe aller au passé composé avec être"}
  ],
  "version_amelioree": "Texte réécrit au niveau supérieur...",
  "conseils": "Travaillez les connecteurs logiques pour enchaîner vos idées."
}
```

Le prompt système doit inclure : le niveau attendu, la grille avec pondérations (depuis `criteres_evaluation`), les consignes correcteur (champ `consignes_correcteur` du JSONB), et l'instruction de répondre uniquement en JSON valide.

## 2.5 Controllers

`ProductionTrainingController` — `/api/production/training/...` (lecture, apprenant authentifié) :
- `GET /tasks?epreuve=TCF_EO`
- `GET /tasks/{taskId}/situations`
- `GET /situations/{situationId}`

`ProductionAttemptController` — `/api/production/attempts/...` (apprenant authentifié) :
- `POST /text` (EE) → SubmitTextAttemptRequest, lance la correction, renvoie l'attempt
- `POST /audio` (EO) → upload multipart, lance transcription + correction
- `GET /` → historique des attempts du user (paginé, filtrable par epreuve/tache)
- `GET /{attemptId}` → détail d'une correction

`ProductionAdminController` — `/api/admin/production/...` (admin) :
- CRUD sur situations, medias, exemples (create/update/delete/toggle is_active)

Auth : réutiliser le filtre JWT existant. `user_id` extrait du token.

---

# ÉTAPE 3 — Frontend (Next.js / React 19 / TS)

Respecter la maquette HTML fournie. CSS en blocs `<style>` scoping JSX (convention du projet), pas Tailwind utilitaire.

## 3.1 Structure de page `/tcf/expression`

- Header avec titre « Expression orale » / « Expression écrite » selon l'épreuve sélectionnée
- 3 onglets globaux : Entraînement / Examens / Corrections
- 3 sous-onglets : Tâche 1 / Tâche 2 / Tâche 3
- Toggle EO ↔ EE

## 3.2 Onglet Entraînement

- **Hero** : titre de la tâche + pitch
- **Stats** : situations complétées, nb exemples, durée cible
- **Carrousel Situations** : cartes scrollables (titre, nb exemples, contexte court, mini-barre de progression). Au clic → charge la situation.
- **Carte Consigne + plan d'aide** : contexte de la situation, durée (EO) ou bornes de mots (EE), liste d'étapes (`etapes` JSONB → help-items avec icône + titre + aide). Pour jeu de rôle EO T2 : afficher `role_candidat` / `objectif` et les supports visuels (`production_situation_medias`).
- **Déclencheur EE** : si `declencheur` présent, l'afficher en encart « message reçu » (expéditeur + texte) avant la consigne.
- **Carte Exemples** : carrousel de previews (titre, résumé). Au clic « Ouvrir » → affiche le `contenu` complet. Pour EO : bouton « ▶ Écouter » qui lit `audio_url`.
- **Plan rapide** : `plan_points` de l'exemple ouvert, en check-list.

## 3.3 Zone de production

- **EE** : textarea + **compteur de mots en temps réel** avec indicateur visuel (rouge si hors bornes `mots_min`/`mots_max`, vert si OK). Bouton « Corriger ma réponse » (désactivé si hors bornes).
- **EO** : panneau micro fixe en bas. Bouton « Enregistrer » → capture audio (Web Audio API / MediaRecorder). Affiche un timer. Bouton « Arrêter ». Puis « Envoyer pour correction ».

## 3.4 Onglet Corrections

- Liste des `production_attempts` du user (filtrable par tâche)
- Chaque item : titre situation, date, score /20, niveau estimé, badges critères
- Détail d'une correction : score global, radar/barres par critère, points forts, liste d'erreurs (extrait → correction → explication), version améliorée, conseils. Pour EO : player de l'enregistrement user + transcript.

## 3.5 États de chargement

La correction IA prend quelques secondes. Afficher un état « Correction en cours… » (polling sur `GET /attempts/{id}` jusqu'à statut DONE, ou attendre la réponse synchrone selon implémentation back).

---

# ÉTAPE 4 — Seed de contenu (situations + exemples)

Créer `V132__seed_production_situations_examples.sql` avec un **lot pilote** pour valider le format :

- EO Tâche 1 (se présenter) : 3 situations, chacune avec 2 exemples (texte + plan_points). audio_url NULL pour l'instant (généré plus tard via le pipeline audio).
- EO Tâche 2 (jeu de rôle logement) : 1 situation avec supports visuels (3 SVG inline de logements façon sujet officiel) + 2 exemples.
- EE Tâche 1 (message à un ami) : 2 situations avec `declencheur` (message type Jenny/Élise) + 2 exemples chacune.

(Le reste du contenu sera fourni séparément en SQL — ne pas inventer 50 situations, juste le pilote pour câbler l'UI.)

---

# Contraintes transverses

- **Ne pas toucher** au module QCM (CO/CE) existant ni au workflow `audio_question_draft`.
- DTOs en records, migrations Flyway numérotées après la dernière existante.
- Réutiliser les services R2 et Azure déjà en place.
- `user_id`, `validated_by` etc. extraits du JWT.
- Le `niveau_cible`/`niveau_indicatif` n'est jamais un filtre bloquant côté apprenant : au mieux un badge discret ou un tri.
- Pas de README, pas de doc générée : juste le code, migrations, et le seed pilote.
- Mobile Flutter : hors scope de cette tâche (sera traité après validation web).

# Ordre d'implémentation recommandé

1. Migration V131 (tables) → V132 (seed pilote)
2. Entities + repositories + DTOs
3. `ProductionTrainingService` + `ProductionTrainingController` (lecture)
4. Front : onglet Entraînement câblé sur les situations/exemples (valider l'affichage avec le seed pilote)
5. `ProductionCorrectionService` + endpoints attempts (EE d'abord, plus simple)
6. Front : zone de rédaction EE + compteur + correction
7. EO : enregistrement audio + transcription + correction
8. Onglet Corrections (historique + détail)
9. `ProductionAdminController` (CRUD admin du contenu)
