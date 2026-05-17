# Audit responsive SejourFR Web
Date : 2026-05-17

Légende statut : OK (déjà responsive et correct) / partiel (responsive mais à améliorer) / cassé (rend incorrectement sous 720 px).
Effort : S (< 15 min), M (15-60 min), L (> 1h).

## Synthèse

Le projet est globalement très bien responsive : toutes les pages ont leurs media queries cohérentes (breakpoints 1100 / 980 / 960 / 900 / 820 / 760 / 720 / 680 / 640 / 600 / 560 / 480). Le pattern qualité est respecté partout.

**Seul vrai défaut critique identifié** : la sidebar des espaces connectés (`/dashboard`, `/profil`, `/entrainement`, etc.) bascule en barre horizontale scrollable sous 900 px. Lisible mais médiocre UX, peu accessible, fait perdre la hiérarchie verticale claire de la navigation.

**Fix appliqué** : nouveau composant `app/_components/MobileSidebarToggle.tsx` qui ajoute un bouton hamburger fixed (visible uniquement < 900 px) + drawer avec overlay. Le shell (AppGroupLayout + DualChromeShell) ajoute la classe `app-shell--has-drawer` qui masque la sidebar fixe horizontale sous 900 px et fait de la place au bouton (`padding-top: 56px`). Les styles du drawer vivent dans `globals.css`.

Bonus : `SiteHeader` reçoit aussi un menu burger (drawer côté droit) pour les visiteurs et les connectés, parce qu'au-dessus de 960 px les liens centraux étaient affichés mais en dessous il n'y avait aucun moyen de les retrouver.

## Composants transverses

| Composant | Statut avant | Issues | Fix appliqué |
|---|---|---|---|
| `app/layout.tsx` | OK | — | — |
| `app/_components/SiteHeader.tsx` | partiel | Liens centraux cachés sous 960 px sans aucun substitut. CTA "Se connecter" caché sous 480 px. | Bouton hamburger + drawer mobile (panel right slide, overlay cliquable, lock body scroll, close on route change + Échap). |
| `app/_components/Footer.tsx` | OK | Grid 4→2→1, newsletter 2→1 sous 720 px | — |
| `app/_components/AppSidebar.tsx` | cassé | Sous 900 px passait en barre horizontale scrollable. Pas de drawer, pas de hamburger, l'UX était très médiocre sur mobile. **CRITIQUE** — toutes les pages connectées + duales sont concernées. | **Drawer mobile ajouté** via nouveau composant `MobileSidebarToggle.tsx`. La sidebar fixe horizontale est masquée par CSS quand le shell parent a la classe `app-shell--has-drawer`. |
| `app/_components/DualChromeShell.tsx` | cassé | Grid 248 px / 1fr collapse à 1fr sous 900 px → sidebar horizontale. | Inclusion du `<MobileSidebarToggle />`, ajout classe `app-shell--has-drawer`, `padding-top: 56px` sur main < 900 px. |
| `app/(app)/layout.tsx` | cassé | Idem DualChromeShell | Idem |
| `app/_components/HeroSection.tsx` | partiel | Grid 2→1 sous 960 px, OK. Mais sous 560 px : padding 64/84 inchangé, h1 32px, boutons côte-à-côte → étroit sur 375 px. | MQ 560 ajoutée : `.hero` padding 48/64, h1 30px, CTAs en `width:100%`, qcard 20px et 18px de border-radius, chips plus petites. |
| `app/_components/LandingSections.tsx` | partiel | `.cta-block` padding 40/28 ok mais boutons full-width manquaient sous 480 px. | MQ 480 ajoutée : padding 32/20, h1 26px, cta-btn width:100%. |
| `app/_components/MobileAppPromo.tsx` | OK | Grid 2→1 sous 960, features 2→1 sous 560, banner avec dismiss responsive sous 460. | — |
| `app/_components/QuestionRunner.tsx` | OK | Padding réduit sous 720 px, statement 22→19 px, tips/theme tag cachés sur mobile, raccourcis cachés. | — |
| `app/_components/Brand.tsx`, `MediaView.tsx`, `ModuleSwitch.tsx`, `TargetPathBanner.tsx`, `TcfPaywallCard.tsx`, `ThemeCard.tsx`, `PaywallSheet.tsx`, `ExamReport.tsx`, `ExamResultCard.tsx`, `ExamsModuleView.tsx`, `TrainingResultCard.tsx` | OK | Composants atomiques, fluides, contraintes par leur parent | — |
| **`app/_components/MobileSidebarToggle.tsx`** | **NOUVEAU** | Drawer mobile pour les espaces connectés. Hamburger fixed top-left (44×44 px, z-index 70), overlay (z-index 80), drawer (z-index 90, width `min(86vw, 300px)`), close button (X) en haut à droite. Ferme automatiquement sur changement de route, Échap, clic sur overlay. Lock body scroll quand ouvert. | Créé |
| `app/globals.css` | OK | Helpers + tokens design | Ajout des styles `.ms-toggle`, `.ms-overlay`, `.ms-drawer`, `.ms-close`, et overrides `.ms-drawer-inner .app-sidebar *` pour rétablir le rendu vertical de la sidebar dans le drawer. Règle `.app-shell--has-drawer > .app-sidebar { display: none; }` sous 900 px. |

## Pages publiques

| Route | Statut | Note |
|---|---|---|
| `/` (`app/page.tsx`) | OK | Composé de sections déjà responsives. Hero amélioré sous 560 px. |
| `/blog` | OK | Uses ArticleCard/FeaturedArticleCard, layout grid responsive. |
| `/blog/[slug]` | OK | Article avec MDX prose responsive via globals.css (.mdx-prose). |
| `/blog/category/[slug]` | OK | Idem index. |
| `/tarifs` | OK | Hero + 3 cards + comparaison table. Composants `components/pricing/*` ont leurs MQ. |
| `/faq` | OK | Layout 2 colonnes via `components/faq/*` avec MQ. |
| `/contact` | OK | Form + sidebar via `components/contact/*`, responsive. |
| `/cgu`, `/mentions-legales`, `/confidentialite` | OK | Utilisent `LegalPageLayout` (sidebar desktop sticky + accordion mobile dans `<details>`). Top padding 32→48 px, tables prose avec overflow auto. Très propre. |
| `/examen-blanc` | OK | 7 lignes : redirige vers `/examens-blancs`. |

## Pages auth (chrome public)

Toutes utilisent le pattern split 2-pane `.auth-wrap` qui collapse à 1 colonne sous 980 px (visual-side masqué).

| Route | Statut |
|---|---|
| `/connexion` | OK (614 L) |
| `/inscription` | OK (724 L) — form-row 2→1 sous 480 px, mention-grid 3→1 sous 480 px |
| `/mot-de-passe-oublie` | OK (669 L) |
| `/reinitialiser-mot-de-passe` | OK (193 L) |

## Pages connectées (sidebar via `(app)/layout.tsx`)

Toutes héritent désormais du drawer mobile via `(app)/layout.tsx` modifié.

| Route | Statut | Note |
|---|---|---|
| `/dashboard` | OK | 1590 L, MQ à 1100 puis 680 puis 760, stats grid 4→2→1, shortcuts 4→2→1, table à overflow-x sous 680, hero-banner collapse, exam picker overlay responsive. **Drawer mobile activé.** |
| `/statistiques` | OK | 1362 L, stats grid 4→2→1, row-2 collapse à 980, heatmap-grid responsive à 600 px. **Drawer mobile activé.** |
| `/historique` | OK | 950 L, stats-grid 3→1, table avec overflow-x. **Drawer mobile activé.** |
| `/revision` | OK | 929 L, tabs 2→1 sous 680, modal détail responsive. **Drawer mobile activé.** |
| `/profil` | OK | 812 L, sections cards stack sous 560/640. **Drawer mobile activé.** |
| `/parcours` | OK | 714 L, pc-grid 3→2→1 (1080/720). **Drawer mobile activé.** |
| `/paiement` | OK | 1055 L, plan-cards 2→1 sous 820, trust-row 3→1 sous 760. **Drawer mobile activé.** |
| `/paiement/succes` | OK | 640 L. **Drawer mobile activé.** |

## Pages duales (DualChromeShell connecté)

Toutes héritent du drawer mobile via `DualChromeShell` modifié (visible uniquement quand authentifié).

| Route | Statut | Note |
|---|---|---|
| `/entrainement` | OK | 1316 L, theme-grid 3→2→1 (1100/680), exams-grid 2→1, recherche full-width sous 680. **Drawer mobile activé pour authentifiés.** |
| `/examens-blancs` | OK | 939 L, guest-tiles 2→1 sous 880, sections free/premium. **Drawer mobile.** |
| `/examens-blancs/civique` | OK | 10 L (filter wrapper). |
| `/examens-blancs/tcf` | OK | 10 L (filter wrapper). |
| `/examens-blancs/[slug]` | OK | 25 L wrapper (briefing). |
| `/sessions/[attemptId]` | OK | 322 L. Le `QuestionRunner` lui-même est très bien responsive (frame 720 max, padding réduit sous 720 px). **Drawer mobile activé pour authentifiés** (le QR a un X de quitter à gauche du topbar, le bouton hamburger lui n'apparaît qu'à `top: 12px` donc ne chevauche pas). |

## Vérifications

- `npx tsc --noEmit` → exit 0
- `npm run build` → succès, 40 pages générées
- Aucun commit/push effectué.
