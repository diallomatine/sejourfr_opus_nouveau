# Identité visuelle commune

Strictement identique sur les 4 surfaces (les écarts sont des **bugs**).

## Couleurs

- Bleu France `#1E3A8C` (dark `#15296B`, light `#E8ECF8`, soft `#F4F6FC`)
- Rouge France `#E1372F` (dark `#B5251E`, light `#FDECEB`) — CTAs critiques, signaux
  d'urgence **et couleur du module civique** (navigation v2, 2026-10-03)
- Ink `#0F1839` / Ink-2 `#1F2950`
- Muted `#6B7299` / `#9CA2BD`
- Vert succès `#168F5B` · Ambre `#E8A317`
- Lignes `#E4E7F2` / `#EEF0F8` · Papier `#F7F8FC` / `#ECEFF7`

### Couleurs de module (navigation v2, 2026-10-03)

**TCF = bleu, Examen civique = rouge**, sur les deux fronts. L'ordre précédent (TCF rouge,
civique bleu) est révoqué. Un composant qui colore un MODULE lit **toujours** le token
sémantique, jamais `blue`/`red` directement — c'est ce qui rend l'inversion centralisée :
- web : `--color-module-tcf*` / `--color-module-civique*`, `--gradient-module-tcf|civique`
- mobile : `AppColors.moduleTcf*` / `moduleCivique*`, `AppColors.module(civique:)`,
  `AppGradients.module(civique:)`

⚠️ Note : le web utilise `#1E3A8C`, l'admin documente `#1E3A8F` dans son CLAUDE.md —
vérifier le code source en cas de doute (le code fait foi).

## Typographies

- **Plus Jakarta Sans** (web) ou **Inter** (admin) — corps, UI, boutons
- ⚠️ **Mobile** : Bricolage Grotesque (titres) + Hanken Grotesk (UI/labels) — Jakarta,
  Fraunces et JetBrains Mono y ont été retirés ; maintenu tel quel par l'arbitrage X2 de la
  navigation v2 (2026-10-03)
- **Fraunces** — titres éditoriaux ; les `<em>` dans les titres sont **toujours rouges**
- **JetBrains Mono** — eyebrows, labels techniques, badges, valeurs numériques

## Logo

Cocarde (3 cercles concentriques bleu/blanc/rouge) + Wordmark (`Sejour` bleu, `FR` rouge)
+ Tagline `EXAMEN CIVIQUE · TCF`.

## Règle absolue

Ne jamais hardcoder une couleur ou une font. Toujours passer par les tokens locaux
(`var(--color-*)`, `AppColors.*`, `AppFonts.*`).
