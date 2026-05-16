# Blog SejourFR — Style Guide (interne)

> Fichier de référence pour rédiger un nouvel article MDX. **Ignoré par le parseur** (`lib/blog/articles.ts` ne charge que les `.mdx`).

## 1. Frontmatter (YAML, entre `---`)

| Clé | Type | Obligatoire | Notes |
|---|---|---|---|
| `title` | string | oui | Titre éditorial, peut contenir deux points |
| `slug` | string | oui | kebab-case, doit matcher le nom du fichier |
| `category` | enum | oui | Voir §2 |
| `excerpt` | string | oui | 1-2 phrases, ≤ 240 chars |
| `publishedAt` | `YYYY-MM-DD` | oui | Sert au tri (desc) |
| `updatedAt` | `YYYY-MM-DD` | non | Mettre = `publishedAt` si jamais modifié |
| `author` | objet `{name, role, initials}` | oui | Toujours `Abdoul Matine Diallo / Fondateur SéjourFR / AD` |
| `coverImage` | string | non | Pas utilisé aujourd'hui — on a `coverIcon` à la place |
| `coverIcon` | string | non | Clé Lucide, voir §3 |
| `tags` | string[] | oui | 4-6 tags, lowercase, accents/tirets autorisés |
| `seo.title` | string | recommandé | ≤ 60 chars |
| `seo.description` | string | recommandé | ≤ 155 chars |

## 2. Catégories valides (`content/categories.json`)

- `titre-de-sejour` (bleu)
- `naturalisation` (rouge)
- `actualite` (ambre) — décrets, arrêtés, circulaires
- `conseils` (indigo) — méthodes, entraînement, préparation

## 3. `coverIcon` valides (`components/blog/CoverIllustration.tsx`)

`building`, `compass`, `fileText`, `flag`, `graduation`, `landmark`, `lightbulb`, `messages`, `newspaper`, `scale`, `scroll`, `sparkles`. Fallback = `newspaper`.

Usage observé : `scale` (naturalisation), `fileText` (titre de séjour), `newspaper` (actualité).

## 4. Ton et registre

- **Posé, factuel, sans pathos.** Phrases courtes à moyennes. Pas de "vous allez voir", pas de "spoiler".
- **Paragraphes de 2-5 lignes** maximum. Sauter une ligne entre chaque.
- **Pas d'emojis** — jamais, ni dans le corps, ni dans les titres, ni dans les callouts.
- **Italique `<em>` dans les titres** : autorisé, sera rendu en **rouge** par `globals.css`. À utiliser pour 1-2 mots clés, pas un titre entier.
- Gras `**...**` réservé aux mots-clés, jurisprudences, montants, dates butoirs. Pas plus de 2-3 fois par paragraphe.
- **Listes à puces** pour les énumérations de pièces / conditions / exceptions. Listes numérotées pour les étapes.
- **Tableaux Markdown** ok pour ordres de grandeur (coûts, délais).

## 5. Structure et rythme

- 1 `#` (le `title` du frontmatter sert d'H1 — **ne pas** réécrire de H1 dans le MDX).
- **6-10 H2** par article, courts (5-7 mots). Découpent les grandes parties.
- H3 pour les sous-cas. H4 réservés aux questions / items numérotés répétitifs.
- Toujours **une section "Ressources officielles"** en fin d'article (liste à puces avec liens externes).

## 6. Composants MDX disponibles

```mdx
<Callout type="info|warning|tip" title="Titre court">
Contenu en markdown. Listes ok. Idéal pour souligner une exception, un piège, une nouveauté légale.
</Callout>

<PullQuote attribution="optionnel">
Citation à fort impact, 1-2 phrases. Rendue en Fraunces italique avec barre rouge à gauche.
</PullQuote>

<Steps>
<Step title="Titre court de l'étape">Corps de l'étape (markdown).</Step>
<Step title="Étape suivante">…</Step>
</Steps>

<CTABox
  title="Titre court orienté action"
  description="Une phrase qui dit la promesse."
  href="/route-app-ou-https://..."
  cta="Libellé du bouton"
/>

<ImageWithCaption src="/path.jpg" alt="…" caption="…" fluid />
```

**Règle CTA** : **une seule** `<CTABox>` par article, en fin (avant la section "Ressources"). Pas de paragraphe + lien en guise de CTA — toujours le composant.

## 7. Citation des textes officiels

- Forme canonique : **« décret n° 2025-648 du 15 juillet 2025 »**, **« arrêté du 10 octobre 2025 »**, **« circulaire Retailleau (2 mai 2025) »**, **« loi n° 2024-42 du 26 janvier 2024 »**, **« article 2 de la Constitution du 4 octobre 1958 »**, **« loi du 9 décembre 1905 »**.
- Liens externes vers `legifrance.gouv.fr`, `service-public.fr`, `interieur.gouv.fr`, `vie-publique.fr`, `formation-civique.interieur.gouv.fr`.
- En cas de doute sur un numéro d'article précis → **formulation prudente** (« la loi de 1905 sépare les Églises et l'État ») plutôt qu'une citation fausse.

## 8. Maillage interne

- **2-4 liens internes** vers d'autres articles `/blog/<slug>` ou vers les routes app (`/civique`, `/entrainement`, `/examens-blancs`, `/naturalisation`).
- Insérer le lien **dans le paragraphe pertinent** (pas de section "À lire aussi" séparée — c'est `getRelatedArticles()` qui s'en charge dans le template).
- Les liens externes (`https://...`) sont automatiquement ouverts dans un nouvel onglet (cf. `mdx-components.tsx`).

## 9. Longueur cible

- **1 500 - 2 500 mots** par article (≈ 6-10 min de lecture, calculé par `reading-time`).
- Excerpt ≤ 240 chars, SEO title ≤ 60, SEO description ≤ 155.
