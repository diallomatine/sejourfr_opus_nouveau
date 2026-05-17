# Inventaire des URLs SejourFR
Date : 2026-05-17

## Pages publiques (chrome public : SiteHeader + Footer)
- `/` — landing one-pager — `app/page.tsx` (compose HeroSection + LandingSections + MobileAppSection)
- `/blog` — index blog — `app/blog/page.tsx`
- `/tarifs` — page tarifs — `app/tarifs/page.tsx`
- `/faq` — FAQ — `app/faq/page.tsx`
- `/contact` — contact — `app/contact/page.tsx`
- `/cgu` — CGU — `app/cgu/page.tsx`
- `/mentions-legales` — mentions légales — `app/mentions-legales/page.tsx`
- `/confidentialite` — politique confidentialité — `app/confidentialite/page.tsx`
- `/examen-blanc` — page legacy (redirige vers `/examens-blancs`) — `app/examen-blanc/page.tsx`

## Pages auth (chrome public, layout pleine page)
- `/connexion` — `app/connexion/page.tsx`
- `/inscription` — `app/inscription/page.tsx`
- `/mot-de-passe-oublie` — `app/mot-de-passe-oublie/page.tsx`
- `/reinitialiser-mot-de-passe` — `app/reinitialiser-mot-de-passe/page.tsx`

## Pages connectées (sidebar via `(app)/layout.tsx`)
Le `SiteHeader`/`Footer` globaux ne s'affichent PAS sur ces routes via `shouldHideGlobalChrome`... mais actuellement la helper retourne toujours `false`, donc le chrome est visible partout. Ces pages utilisent `AppSidebar` à gauche.

- `/dashboard` — `app/(app)/dashboard/page.tsx` (1590L)
- `/statistiques` — `app/(app)/statistiques/page.tsx` (1362L)
- `/historique` — `app/(app)/historique/page.tsx` (950L)
- `/revision` — `app/(app)/revision/page.tsx` (929L)
- `/profil` — `app/(app)/profil/page.tsx` (812L)
- `/parcours` — `app/(app)/parcours/page.tsx` (714L)
- `/paiement` — `app/(app)/paiement/page.tsx` (1055L)
- `/paiement/succes` — `app/(app)/paiement/succes/page.tsx` (640L)

## Pages duales (DualChromeShell connecté, chrome public guest)
Préfixes définis dans `lib/chrome-routes.ts` : `/entrainement`, `/examens-blancs`, `/sessions`.

- `/entrainement` — `app/entrainement/page.tsx` (1316L)
- `/examens-blancs` — `app/examens-blancs/page.tsx` (939L) — liste
- `/examens-blancs/civique` — `app/examens-blancs/civique/page.tsx` (10L) — sub-list filter
- `/examens-blancs/tcf` — `app/examens-blancs/tcf/page.tsx` (10L) — sub-list filter
- `/sessions/[attemptId]` — `app/sessions/[attemptId]/page.tsx` (322L) — runner générique

## Routes dynamiques
- `/blog/[slug]` — détail article — `app/blog/[slug]/page.tsx` (168L)
- `/blog/category/[slug]` — index par catégorie — `app/blog/category/[slug]/page.tsx` (178L)
- `/examens-blancs/[slug]` — briefing template — `app/examens-blancs/[slug]/page.tsx` (25L)
- `/sessions/[attemptId]` — runner — déjà listé

## Composants partagés à vérifier (impact transverse)
- `app/_components/SiteHeader.tsx` — sticky top, déjà responsive (menu collapse 960px, hide CTA 480px)
- `app/_components/Footer.tsx` — déjà responsive (grid 4→2→1)
- `app/_components/AppSidebar.tsx` — bascule en barre horizontale scrollable sous 900px (PAS de drawer)
- `app/_components/DualChromeShell.tsx` — grid 248px/1fr, collapse à 1fr sous 900px
- `app/(app)/layout.tsx` — idem dual shell
- `app/_components/HeroSection.tsx` — déjà responsive (grid 2→1 sous 960px)
- `app/_components/LandingSections.tsx` — 1132L, plusieurs sections
- `app/_components/MobileAppPromo.tsx`
- `app/_components/QuestionRunner.tsx` — runner 918L, focus mode
- `app/_components/Footer.tsx`, `Brand.tsx`, `ModuleSwitch.tsx`, `ThemeCard.tsx`, `TargetPathBanner.tsx`, `PaywallSheet.tsx`, `ExamReport.tsx`, `ExamResultCard.tsx`, `ExamsModuleView.tsx`, `TrainingResultCard.tsx`, `TcfPaywallCard.tsx`, `MediaView.tsx`

## Composants section
- `components/blog/*` (15 fichiers)
- `components/contact/*` (4)
- `components/faq/*` (8)
- `components/legal/*` (10)
- `components/pricing/*` (4)
