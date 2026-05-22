# Identité visuelle commune

Strictement identique sur les 4 surfaces (les écarts sont des **bugs**).

## Couleurs

- Bleu France `#1E3A8C` (dark `#15296B`, light `#E8ECF8`, soft `#F4F6FC`)
- Rouge France `#E1372F` (dark `#B5251E`, light `#FDECEB`) — réservé aux CTAs critiques +
  signaux d'urgence
- Ink `#0F1839` / Ink-2 `#1F2950`
- Muted `#6B7299` / `#9CA2BD`
- Vert succès `#168F5B` · Ambre `#E8A317`
- Lignes `#E4E7F2` / `#EEF0F8` · Papier `#FAFAF7` / `#F2F1EC`

⚠️ Note : le web utilise `#1E3A8C`, l'admin documente `#1E3A8F` dans son CLAUDE.md —
vérifier le code source en cas de doute (le code fait foi).

## Typographies

- **Plus Jakarta Sans** (web/mobile) ou **Inter** (admin) — corps, UI, boutons
- **Fraunces** — titres éditoriaux ; les `<em>` dans les titres sont **toujours rouges**
- **JetBrains Mono** — eyebrows, labels techniques, badges, valeurs numériques

## Logo

Cocarde (3 cercles concentriques bleu/blanc/rouge) + Wordmark (`Sejour` bleu, `FR` rouge)
+ Tagline `EXAMEN CIVIQUE · TCF`.

## Règle absolue

Ne jamais hardcoder une couleur ou une font. Toujours passer par les tokens locaux
(`var(--color-*)`, `AppColors.*`, `AppFonts.*`).
