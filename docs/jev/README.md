# Benchmark JEV — point de reprise

JEV (TypeSafe, modèle `jev-1.13.0`) a été évalué comme **estimateur indépendant du niveau CECRL**
des productions écrites, face au correcteur SejourFR actuel (grille v15 / tool-schema v9).
**Rien n'a été intégré au produit** : backend, fronts et admin sont intacts.

**État au 2026-09-30 : en pause.** L'accord JEV ↔ SejourFR est jugé suffisant pour l'instant
(67 % d'exact sur productions réelles, **aucun écart de plus d'un niveau**).

## Les documents

| Fichier | Contenu |
|---|---|
| `spec-benchmark-jev-sejourfr.md` | La spec du propriétaire, puis **l'audit** (section « AUDIT », A.0 → A.19) : pipeline de notation, tables, RGPD, architecture retenue (option A : outil local). |
| `conversation_jev_tests_cecrl.md` | Les tests manuels dans le Playground JEV, source des 35 premières fixtures. |
| `resultats-benchmark-synthetique-v1.md` | 59 cas synthétiques, deux versions de prompt. |
| `resultats-benchmark-reel-v1.md` | 99 productions réelles anonymisées (EE1–EE3). Aucun texte, cas désignés par clé hachée. |

## Résultats à retenir

**Synthétique** (59 cas, `jev-independent-v1`) : 72 % d'exact vs niveau visé (82 % en lecture
souple), 0 écart majeur, stabilité 59/59. JEV **resserre l'échelle** : A1 → A2, B2 → B1.
La version `jev-v15-aligned-v1` (descripteurs v15 imposés) ne change pas le niveau global ; elle
rend les critères plus sévères et fait converger JEV vers SejourFR — d'où le choix de
`independent-v1` comme benchmark principal.

**Réel** (99 productions, 65 candidats, `jev-independent-v1`) :
- 81 niveaux comparables : **54 exacts (67 %), 27 adjacents, 0 majeur**, kappa pondéré 0,64.
- Par tâche : EE1 58 % · EE2 67 % · EE3 75 %. **EE1 est le point faible.**
- JEV ramène vers A2 : 10 A1 SejourFR sur 14 → A2 ; 14 B1 SejourFR sur 33 → A2 (dont 9 EE1).
- 9 désaccords où JEV est très confiant : **premiers candidats à un avis humain**.
- `A1_NON_ATTEINT` (12) : JEV les dit HORS_SUJET (11/12) mais leur donne quand même un niveau
  de langue — il sépare hors-sujet et niveau, SejourFR met 0/20.
- `NON_EVALUABLE` (3) : INSUFFICIENT + HORS_SUJET, confiance ≥ 0,89.
- Stabilité : 23/25 identiques (les 2 instables sont à 50/50).
- B2 **non mesurable** (1 seul cas réel).

Garde-fous : SejourFR n'est pas une vérité ; un accord ne prouve pas la justesse.

## Coûts

JEV : 0,042 $ / M tokens d'entrée, sortie gratuite. Cumul de tous les appels : **≈ 0,077 $**.
Notation SejourFR des fixtures via le backend local : ~53 appels DeepSeek.

## L'outil : `tools/jev-benchmark/`

Python 3.11 (venv `.venv`, Streamlit exige ≥ 3.10), SQLite locale, Streamlit.
Gitignorés : `.env` (clé), `data/` (SQLite, sel, exports, dry-runs), `.venv/`.

```bash
cd tools/jev-benchmark
.venv/bin/python -m jev_bench --help
.venv/bin/python -m jev_bench ui            # interface (sélecteurs origine / version de prompt)
.venv/bin/python -m jev_bench report        # rapport synthétique, par version de prompt
.venv/bin/python -m jev_bench report-real   # rapport réel, sans texte
.venv/bin/python -m jev_bench check-prompts # critères identiques à la grille v15
.venv/bin/python -m jev_bench selfcheck --db
```

- **Clé** : `JEV_API_KEY` dans `tools/jev-benchmark/.env` (copie de celle de `backend_sejourfr/.env`).
  Jamais affichée ni loggée.
- **API** : `POST https://api.typesafe.ai/v1/systemone`, 6 questions `choice` par requête
  (`niveau_global`, `pertinence`, 4 critères v15).
- **Prompts** : `jev_bench/prompts/`, versionnés (`jev-independent-v1`, `jev-v15-aligned-v1`),
  assemblage déterministe + hash.
- **Garde-fous du run réel** : refusé sans `--confirm-real`, sans modèle épinglé ou au-delà de
  `--budget-usd 0.10` ; payloads re-vérifiés avant envoi (seuls exam, modality, task_type,
  consigne, contexte, production).
- **Données réelles** : `extract-real` lit la prod **en SSH, session read-only**
  (`PGOPTIONS=-c default_transaction_read_only=on`, SELECT seulement), tirage côté serveur,
  identifiants remplacés par `md5(sel || id)`, rédaction locale des données personnelles
  ([PERSONNE], [EMAIL], [TELEPHONE], [ADRESSE], [URL]), brut supprimé après import.
  Requête : `jev_bench/sql/export_ee_real_v1.sql`.
- **Formule SejourFR en Python** (`formule.py`) : résultat **secondaire**. Milieux de bandes
  A1=1 · A2=4 · B1=8 · B2=15 (intervalles serveur (0,2) / [2,6) / [6,10) / [10,20]).
  Rejoue à l'identique les évaluations v15 locales.
- **Nettoyage de la base locale** après `score-sejourfr` : `sql/cleanup_local_sejourfr_db.sql`,
  puis replay admin de progression, puis `sql/cleanup_local_refresh_tokens.sql` en dernier.

## Pour reprendre

Par ordre d'utilité :

1. **Avis humain** sur les 27 désaccords réels, en commençant par les 9 où JEV est très
   confiant — la seule façon de savoir qui a raison, surtout sur les **EE1 courts B1 ↔ A2**.
2. **Petits sujets** (strate séparée, jamais mélangée) : proposition prête, ~42 cas + 4 isolés,
   version de prompt `jev-targeted-v1` à écrire. Trois décisions ouvertes : question
   `critere_unique` oui/non ; checklist dans le state oui/non ; comparer à `level_reached`
   (jugé sur un seul critère).
3. **EO (V2)** : transcriptions seulement (audio non conservé) ; tours temps réel séparables
   par préfixe `Candidat :` / `Examinateur :` ; ajouter une décision de qualité de transcription.
   Voir audit A.6, A.7, A.18.
4. **Avant tout usage produit** :
   - **RGPD** : TypeSafe n'a fourni ni DPA, ni lieu de traitement, ni durée de conservation ;
   - la politique de confidentialité (`web_sejoufr/content/legal/legal-info.ts`) ne liste
     **aucun** fournisseur IA, JEV compris, alors que DeepSeek, OpenAI et Google reçoivent
     déjà des productions — écart à corriger indépendamment de JEV.
