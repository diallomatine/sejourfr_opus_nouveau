# Migrations Flyway — organisation et convention de numérotation

Flyway scanne récursivement `classpath:db/migration` (prod & dev) et
`classpath:db/migration-dev` (dev uniquement). L'arborescence est organisée par **plages
numériques** et par **dossiers thématiques** :

```
db/migration/
├── 00_schema/                       V0xx        évolutions de schéma (step 10 : place pour hotfix entre 2 features)
├── 10_reference/                    V1xx        données de référence (thèmes, plans, exam templates)
├── 20_civique/                      V2xx        seeds civique
│   ├── 00_initial/                  V20x        seed des thèmes (V200 principes, V201 thèmes 2-5)
│   ├── 10_institutions/             V21x        (V210-V216 = reformulations lot01-04 + niveau CSP/CR/NAT)
│   ├── 20_droits_devoirs/           V22x
│   ├── 30_histoire_geo/             V23x
│   └── 40_societe/                  V24x
└── 30_tcf/                          V3xx        seeds TCF
    ├── 00_lots_mixtes/              V30x        CE + STRUCTURE dans le même fichier
    ├── 10_ce/                       V31x        CE focalisée par niveau (V310 A2, V311 B1, V312 B2)
    ├── 20_structure/                V32x        STRUCTURE focalisée
    └── 30_echantillons/             V33x        échantillons de validation de méthode

db/migration-dev/                    V9xx        seeds dev uniquement (V900 comptes seed, attempts factices)
```

**Convention** : le numéro de version du fichier reflète son emplacement dans l'arbre.

- `00_schema/Vxxx` : 1er chiffre = 0 (catégorie schéma). Espacement step 10 (V001, V010,
  V020...) pour pouvoir intercaler. **DDL pur** (CREATE/ALTER), pas d'INSERT qui dépend de
  données seedées plus tard.
- `10_reference/V1xx` : seeds de référence (thèmes, plans, exam templates). Toute donnée fixe
  partagée prod/dev.
- `20_civique/10_institutions/V21x` : 1er chiffre 2 = civique, 2e chiffre 1 = institutions.
  Files V210..V219 (10 slots par sous-thème).
- Idem TCF.

**Pour ajouter une migration :**

- Nouvelle évolution de schéma → `00_schema/`, prochain V0x0 libre.
- Nouveau seed civique → sous-dossier du thème, prochain numéro libre dans le namespace
  (10 slots).
- Nouveau seed TCF → `00_lots_mixtes/`, `10_ce/`, `20_structure/` ou `30_echantillons/`
  selon la nature.
- Si le namespace est plein (rare), ajouter un nouveau sous-dossier (ex. `50_xxx/` → V25x).

`out-of-order: true` est activé : l'ordre d'ajout n'est pas contraint tant que les numéros
restent uniques.
