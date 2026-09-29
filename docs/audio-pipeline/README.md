# 📦 SejourFR — Pipeline de génération de questions audio CO

> Dossier de spécifications complet pour l'implémentation de la feature **"Génération automatique de questions audio TCF Compréhension Orale"** dans le backend Spring Boot de SejourFR.

---

## 🎯 Objectif de la feature

Permettre à un administrateur, depuis l'espace d'admin, de **générer en un clic** une question complète de Compréhension Orale (audio MP3 + transcript + question + 4 choix + explication), via un pipeline orchestré :

```
Admin → Backend Spring Boot → Anthropic Claude → Azure Speech → Cloudflare R2 → DB
```

L'admin **prévisualise** ensuite la question (écoute le MP3, lit le contenu) et choisit de **valider** ou **rejeter**.

---

## 📚 Comment lire ce dossier

Les fichiers sont numérotés et doivent être lus dans l'ordre :

| Ordre | Fichier | Contenu | Cible |
|---|---|---|---|
| 1 | `00-OVERVIEW.md` | Vue d'ensemble, architecture, décisions clés | Tous |
| 2 | `01-API-CONTRACT.md` | Endpoints REST, DTOs Java, codes d'erreur | Dev backend |
| 3 | `02-DATABASE-SCHEMA.md` | Migration Flyway V14, entités JPA | Dev backend |
| 4 | `03-INTEGRATIONS.md` | Specs Anthropic + Azure Speech + Cloudflare R2 | Dev backend |
| 5 | `04-PROMPT-CLAUDE.md` | Prompt système complet + schéma JSON strict | Dev backend |
| 6 | `05-BUSINESS-RULES.md` | Validations, calibrage, anti-doublons | Dev backend |
| 7 | `06-IMPLEMENTATION-GUIDE.md` | **Guide pas-à-pas pour Claude Code** | Claude Code |
| 8 | `07-ACCEPTANCE-TESTS.md` | Tests Given/When/Then exhaustifs | Dev + QA |
| 9 | `08-OBSERVABILITY-SECURITY.md` | Logging, monitoring, coûts, sécurité | Dev + Ops |

---

## 🚀 Démarrage rapide avec Claude Code

### Étape 1 : Préparer ton repo

1. Copie le dossier `sejourfr-audio-pipeline/` à la racine de ton repo backend (au même niveau que `src/`, `pom.xml`)
2. Vérifie que tu as bien configuré tes accès aux 3 services externes :
   - Compte Anthropic avec clé API
   - Compte Azure avec Speech Service activé en région France Centrale
   - Bucket Cloudflare R2 créé avec accès public + API token

### Étape 2 : Lancer Claude Code

Depuis la racine du repo, lance :

```bash
claude
```

Puis colle exactement ce prompt d'amorçage :

```
Je vais te demander d'implémenter une nouvelle feature dans ce backend Spring Boot.

Toutes les spécifications sont dans le dossier `/sejourfr-audio-pipeline/`.

Avant de commencer, lis ces fichiers DANS L'ORDRE :
1. sejourfr-audio-pipeline/00-OVERVIEW.md
2. sejourfr-audio-pipeline/01-API-CONTRACT.md
3. sejourfr-audio-pipeline/02-DATABASE-SCHEMA.md
4. sejourfr-audio-pipeline/03-INTEGRATIONS.md
5. sejourfr-audio-pipeline/04-PROMPT-CLAUDE.md
6. sejourfr-audio-pipeline/05-BUSINESS-RULES.md
7. sejourfr-audio-pipeline/06-IMPLEMENTATION-GUIDE.md
8. sejourfr-audio-pipeline/07-ACCEPTANCE-TESTS.md
9. sejourfr-audio-pipeline/08-OBSERVABILITY-SECURITY.md

Ne commence à coder qu'après avoir lu l'intégralité de ces specs.

L'implémentation se fait en 6 phases (voir 06-IMPLEMENTATION-GUIDE.md).
Tu ne passes à la phase N+1 qu'après que j'aie validé la phase N.

Confirme-moi quand tu as fini la lecture et fais-moi un résumé de :
- L'architecture cible
- L'ordre des 6 phases
- Les éléments que tu vois comme à risque ou ambigus

Puis on attaquera ensemble la phase 1.
```

### Étape 3 : Procéder phase par phase

À chaque phase validée, tu lui dis simplement :

```
Phase 1 validée. Passe à la phase 2.
```

Les 6 phases sont :

| Phase | Contenu | Test |
|---|---|---|
| 1 | Setup (dépendances Maven, config) | Compilation OK |
| 2 | Base de données (migration V14, entités) | `mvn flyway:migrate` OK |
| 3 | DTOs + exceptions + handler global | Tests unitaires DTOs |
| 4 | Clients externes (Anthropic, Azure, R2) | Tests avec mocks |
| 5 | Service d'orchestration | Tests E2E mockés |
| 6 | Controller + endpoints + tests d'intégration | Tests manuels réels |

---

## 🔑 Décisions clés (rappel)

| Sujet | Décision |
|---|---|
| Mode de génération | Synchrone (10-30s) |
| Workflow post-génération | Prévisualisation obligatoire (DRAFT) |
| Volume | 1 question par clic |
| Clés API | Variables d'environnement backend |
| TTS retenu | Azure Speech Service (voix neural FR-FR) |
| LLM retenu | Anthropic Claude Sonnet 4.6 |
| Stockage audio | Cloudflare R2 (compatible S3) |
| Stack | Spring Boot 3.x + Java 17+ + PostgreSQL |

---

## 💰 Coûts estimés

- **Par génération** : ~0.01 € (Anthropic + Azure + R2)
- **Pour 1000 questions générées** : ~10 €
- **Budget mensuel suggéré** : 50 € (configurable, avec alerte à 80%)

---

## ✅ Critères d'acceptation globaux

Le projet est livré OK quand :

- [ ] L'admin peut générer une question audio en un clic
- [ ] Le MP3 est lisible et de qualité acceptable
- [ ] La question est en DRAFT après génération
- [ ] L'admin peut valider (DRAFT → ACTIVE) ou rejeter (suppression complète)
- [ ] En cas d'erreur, aucune donnée orpheline n'est laissée (rollback complet)
- [ ] Chaque génération est tracée dans `audio_question_generation_logs`
- [ ] Aucune clé API n'apparaît dans les logs ou le frontend
- [ ] Les tests unitaires passent (mocks)
- [ ] 5 générations manuelles réelles ont été validées
- [ ] Le monitoring des coûts est en place

---

## 🛠️ Variables d'environnement requises

Avant le premier démarrage en local, créer un `.env` à la racine du repo (ne pas commiter) :

```bash
# Anthropic
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-sonnet-4-6

# Azure Speech (région France Centrale recommandée pour latence)
AZURE_SPEECH_KEY=...
AZURE_SPEECH_REGION=francecentral

# Cloudflare R2
R2_ACCOUNT_ID=...
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET_NAME=sejourfr-audio
R2_PUBLIC_URL_BASE=https://pub-xxxxx.r2.dev

# Configuration générale
AUDIO_GENERATION_TIMEOUT_SEC=45
```

Ajouter `.env` au `.gitignore`.

---

## 🆘 Setup des comptes externes

### Anthropic

1. Aller sur https://console.anthropic.com
2. Créer une clé API (Settings → API Keys → Create)
3. Charger ~10 € de crédit pour démarrer
4. Récupérer `ANTHROPIC_API_KEY`

### Azure Speech Service

1. Aller sur le portail Azure (https://portal.azure.com)
2. Créer une ressource "Speech Service" en région **France Centrale**
3. Plan tarifaire : **S0 (Standard)** pour les voix neural
4. Récupérer la **clé 1** dans Keys and Endpoint
5. Variables : `AZURE_SPEECH_KEY` + `AZURE_SPEECH_REGION=francecentral`

### Cloudflare R2

1. Aller sur https://dash.cloudflare.com → R2
2. Créer un bucket : **sejourfr-audio**
3. Bucket Settings → Public Access → Allow Access → R2.dev subdomain → Enable
4. Récupérer l'URL publique (forme : `https://pub-XXXXX.r2.dev`)
5. Manage R2 API Tokens → Create API Token :
   - Permissions : **Object Read & Write**
   - Scope : Apply to specific buckets → `sejourfr-audio`
6. Récupérer `Access Key ID` + `Secret Access Key`
7. Account ID est visible dans l'URL du dashboard ou dans la page d'accueil R2

---

## 📞 Support

En cas de question sur le contenu des specs, ouvrir une discussion dans le repo en référençant le fichier et la section concernés.

Pour les questions purement techniques sur Claude Code, voir : https://docs.claude.com

---

**Bonne implémentation 🚀**
