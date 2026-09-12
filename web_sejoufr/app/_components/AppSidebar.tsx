"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import {
  Flame,
  LayoutGrid,
  ListChecks,
  Sparkles,
  Target,
  Trophy,
} from "lucide-react";
import { dashboardApi } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";
import { basculeParcours } from "@/lib/module-switch";
import { objectifLabel } from "@/lib/preparation";

/**
 * Barre latérale de l'espace personnel.
 *
 * **La FORME vient de la maquette** (`~/Desktop/grok_ecran`, `.sf-rail` dans
 * `studio.tsx` + `sejour.css`) : logo, sous-titre de parcours, **bascule
 * TCF IRN / Examen civique**, entrées à icônes, note de bas de colonne.
 *
 * 🛑 **Les ENTRÉES, elles, sont les nôtres — aucune inventée, aucune perdue**
 * (arbitrage du propriétaire : « on garde nos menus, seuls les écrans on
 * copie »). Les sept destinations d'avant sont toutes là :
 *
 * | destination | où elle est maintenant |
 * |---|---|
 * | `/dashboard` | entrée à icône « Tableau de bord » |
 * | `/entrainement?module=TCF` | **côté gauche de la bascule** |
 * | `/entrainement?module=CIVIQUE` | **côté droit de la bascule** |
 * | `/examens-blancs` | entrée à icône « Examens blancs » |
 * | `/plan` | entrée à icône « Plan » |
 * | `/historique` | entrée à icône « Résultats » |
 * | `/recommandations` | entrée à icône « Recommandations » |
 *
 * Les deux parcours passent en bascule parce que la maquette les y met **et**
 * parce que les répéter en entrées de liste aurait mis deux fois la même
 * destination dans la même colonne.
 *
 * 🛑 **La bascule est CONTEXTUELLE depuis le 2026-09-12** (arbitrage du
 * propriétaire) : « une seule bascule TCF / Examen civique visible à la fois, et
 * son action dépend du contexte courant — sur Plan elle change le Plan, sur
 * Réviser / Entraînement elle change l'espace d'entraînement. » Sur le Plan elle
 * mène donc à `/plan?module=…` et l'écran masque la sienne (≥ 901 px, la borne
 * du rail). Partout ailleurs elle garde sa destination historique.
 *
 * 🛑 **La règle vit dans `lib/module-switch.ts`, pas ici** : le marquage de
 * l'onglet actif, le sous-titre de parcours et la destination reposent tous les
 * trois sur la même lecture, et trois `if` recopiés auraient divergé.
 *
 * En pied : la note de la maquette, le badge streak (via GET /api/me/dashboard
 * mémoïsé) et la carte utilisateur cliquable vers /profil (le logout vit sur la
 * page profil).
 */
export function AppSidebar() {
  return (
    <Suspense fallback={<aside className="app-sidebar" aria-hidden />}>
      <AppSidebarInner />
    </Suspense>
  );
}

function AppSidebarInner() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { user, status } = useAuth();

  /* 🛑 **Une seule lecture, une seule autorité** : où mène la bascule depuis
     cette route, et quel parcours y est courant. */
  const bascule = basculeParcours(pathname, searchParams);
  const isTcfActive = bascule.courant === "TCF";
  const isCiviqueActive = bascule.courant === "CIVIQUE";

  /* Le sous-titre de parcours de la maquette. 🛑 Hors d'un parcours (tableau
     de bord, résultats, profil…) il n'y a **pas** de parcours courant : on
     affiche la ligne de marque, jamais un module choisi par défaut. */
  const parcoursTag = isTcfActive
    ? "Coach TCF IRN"
    : isCiviqueActive
      ? "Examen civique"
      : "Examen civique · TCF";
  // Les erreurs/favoris (/revision) vivent désormais sous Recommandations.
  const isRecoActive =
    pathname === "/recommandations" ||
    pathname?.startsWith("/recommandations/") ||
    pathname === "/revision" ||
    pathname?.startsWith("/revision/");
  // Progression est désormais une vue secondaire du Plan : garder le parent
  // visuellement actif quand l'utilisateur consulte /statistiques.
  const isPlanActive =
    pathname === "/plan" ||
    pathname?.startsWith("/plan/") ||
    pathname === "/statistiques" ||
    pathname?.startsWith("/statistiques/");

  const [streak, setStreak] = useState<number | null>(null);

  // Streak best-effort : badge masqué tant que la valeur est inconnue ou 0.
  useEffect(() => {
    if (status !== "authenticated") return;
    let cancelled = false;
    dashboardApi
      .summaryCached()
      .then((d) => {
        if (!cancelled) setStreak(d.currentStreakDays);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [status]);

  const initial =
    user?.firstName?.[0]?.toUpperCase() ??
    user?.email?.[0]?.toUpperCase() ??
    "?";

  const fullName = user
    ? `${user.firstName ?? "Utilisateur"} ${user.lastName ?? ""}`.trim()
    : "";

  return (
    <aside className="app-sidebar">
      <Link href={user ? "/dashboard" : "/"} className="app-brand">
        <span className="app-cocarde" aria-hidden />
        <span className="app-brand-text">
          <span className="app-brand-name">
            Sejour<span className="app-brand-fr">FR</span>
          </span>
          <span className="app-brand-tag">{parcoursTag}</span>
        </span>
      </Link>

      {/* La bascule de parcours de la maquette. Ce sont EXACTEMENT les deux
          entrées « TCF IRN » et « Examen civique » d'avant — mêmes libellés ;
          leur destination, elle, suit le contexte (cf. `basculeParcours`). */}
      <div className="app-seg" role="tablist" aria-label="Parcours">
        <Link
          href={bascule.href("TCF")}
          role="tab"
          aria-selected={isTcfActive}
          className={isTcfActive ? "app-seg-item is-on" : "app-seg-item"}
        >
          TCF IRN
        </Link>
        <Link
          href={bascule.href("CIVIQUE")}
          role="tab"
          aria-selected={isCiviqueActive}
          className={isCiviqueActive ? "app-seg-item is-on" : "app-seg-item"}
        >
          Examen civique
        </Link>
      </div>

      <nav className="app-nav" aria-label="Espace personnel">
        <SideLink href="/dashboard" pathname={pathname} icon={<LayoutGrid size={18} />}>
          Tableau de bord
        </SideLink>
        <SideLink href="/examens-blancs" pathname={pathname} icon={<Target size={18} />}>
          Examens blancs
        </SideLink>

        <span className="app-nav-section">Suivi</span>
        <SideLink
          href="/plan"
          pathname={pathname}
          icon={<ListChecks size={18} />}
          activeWhen={() => Boolean(isPlanActive)}
        >
          Plan
        </SideLink>
        <SideLink href="/historique" pathname={pathname} icon={<Trophy size={18} />}>
          Résultats
        </SideLink>
        <SideLink
          href="/recommandations"
          pathname={pathname}
          icon={<Sparkles size={18} />}
          activeWhen={() => Boolean(isRecoActive)}
        >
          Recommandations
        </SideLink>
      </nav>

      <div className="app-sidebar-foot">
        {/* La note de bas de colonne de la maquette : elle dit ce que le Plan
            fait, sur tous les écrans de l'espace connecté. */}
        <p className="app-foot-note">
          Le plan choisit la prochaine action, puis réévalue après chaque séance.
        </p>

        {streak !== null && streak > 0 && (
          <div className="streak-card">
            <span className="streak-flame" aria-hidden>
              <Flame size={17} />
            </span>
            <span className="streak-info">
              <span className="streak-title">
                {streak} jour{streak > 1 ? "s" : ""} de suite
              </span>
              <span className="streak-sub">Continuez comme ça !</span>
            </span>
          </div>
        )}

        {user && (
          <Link href="/profil" className="user-mini" title="Mon profil">
            <span className="user-avatar">{initial}</span>
            <span className="user-info">
              <span className="user-name">{fullName || "Utilisateur"}</span>
              <span className="user-objective">
                {objectifLabel(user.targetProcedure)}
              </span>
            </span>
          </Link>
        )}
      </div>

      <style>{sidebarStyles}</style>
    </aside>
  );
}

function SideLink({
  href,
  pathname,
  icon,
  children,
  activeWhen,
}: {
  href: string;
  pathname: string | null;
  icon: React.ReactNode;
  children: React.ReactNode;
  activeWhen?: (pathname: string | null) => boolean;
}) {
  const path = href.split("?")[0];
  const isActive = activeWhen
    ? activeWhen(pathname)
    : pathname === path ||
      (path !== "/dashboard" && pathname?.startsWith(`${path}/`));
  return (
    <Link href={href} className={`nav-item ${isActive ? "is-active" : ""}`}>
      <span className="nav-icon" aria-hidden>
        {icon}
      </span>
      <span className="nav-label">{children}</span>
    </Link>
  );
}

const sidebarStyles = `
  .app-sidebar {
    background: #fff;
    border-right: 1px solid var(--color-line);
    padding: 22px 16px 16px;
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
  }
  .app-brand {
    display: flex; align-items: center; gap: 11px;
    padding: 6px 8px 14px;
    text-decoration: none;
  }
  .app-brand-text {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }
  /* Le sous-titre de parcours de la maquette (« Coach TCF IRN »). */
  .app-brand-tag {
    font-family: var(--font-sans);
    font-size: 12px;
    font-weight: 600;
    color: var(--color-muted);
    letter-spacing: 0.01em;
    margin-top: 2px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  /* === bascule de parcours (forme de la maquette, destinations à nous) === */
  .app-seg {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 4px;
    padding: 4px;
    margin: 0 2px 14px;
    background: var(--color-blue-light);
    border-radius: 14px;
  }
  .app-seg-item {
    min-height: 38px;
    display: grid;
    place-items: center;
    padding: 0 6px;
    border-radius: 11px;
    color: var(--color-blue);
    font-size: 12.5px;
    font-weight: 700;
    text-align: center;
    text-decoration: none;
    transition: background 0.15s, color 0.15s;
  }
  .app-seg-item:hover { background: color-mix(in srgb, #fff 55%, transparent); }
  .app-seg-item.is-on {
    background: #fff;
    color: var(--color-ink);
    box-shadow: 0 0 0 1px var(--color-line), 0 1px 2px -1px rgba(15, 24, 57, 0.12);
  }

  .app-foot-note {
    margin: 0 4px 4px;
    font-size: 12px;
    line-height: 1.45;
    color: var(--color-muted);
  }
  .app-cocarde {
    width: 30px; height: 30px;
    border-radius: 50%;
    flex-shrink: 0;
    background:
      radial-gradient(circle, var(--color-red) 0 28%, transparent 28%),
      radial-gradient(circle, #fff 0 60%, transparent 60%),
      var(--color-blue);
  }
  .app-brand-name {
    font-family: var(--font-sans);
    font-weight: 800;
    font-size: 20px;
    letter-spacing: -0.02em;
    color: var(--color-blue);
  }
  .app-brand-fr { color: var(--color-red); }

  .app-nav { flex: 1; display: flex; flex-direction: column; }
  .app-nav-section {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--color-muted-2);
    letter-spacing: 0.15em;
    text-transform: uppercase;
    padding: 0 10px;
    margin: 18px 0 6px;
    font-weight: 600;
  }

  .nav-item {
    position: relative;
    display: flex; align-items: center; gap: 11px;
    padding: 10px 11px;
    border-radius: 10px;
    color: var(--color-ink-2);
    font-size: 14px;
    font-weight: 500;
    text-decoration: none;
    margin-bottom: 2px;
    transition: background 0.15s, color 0.15s;
  }
  .nav-item:hover { background: var(--color-blue-soft); }
  .nav-item.is-active {
    background: var(--color-blue-light);
    color: var(--color-blue);
    font-weight: 700;
  }
  .nav-item.is-active::before {
    content: '';
    position: absolute;
    left: -16px; top: 8px; bottom: 8px;
    width: 3px;
    border-radius: 0 3px 3px 0;
    background: var(--color-blue);
  }
  .nav-icon {
    color: var(--color-muted);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
    transition: color 0.15s;
  }
  .nav-item:hover .nav-icon,
  .nav-item.is-active .nav-icon { color: var(--color-blue); }
  .nav-label { flex: 1; min-width: 0; }

  /* === footer === */
  .app-sidebar-foot {
    margin-top: auto;
    padding-top: 14px;
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .streak-card {
    display: flex; align-items: center; gap: 11px;
    border: 1px solid var(--color-line);
    border-radius: 12px;
    padding: 10px 12px;
    background: #fff;
  }
  .streak-flame {
    width: 34px; height: 34px;
    border-radius: 10px;
    background: var(--color-red-light);
    color: var(--color-red);
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .streak-info { display: flex; flex-direction: column; min-width: 0; }
  .streak-title {
    font-size: 13px; font-weight: 700;
    color: var(--color-ink);
    line-height: 1.25;
  }
  .streak-sub {
    font-size: 11px; color: var(--color-muted);
    line-height: 1.3;
    margin-top: 1px;
  }

  .user-mini {
    display: flex; align-items: center; gap: 10px;
    padding: 8px;
    border: 1px solid transparent;
    border-radius: 10px;
    width: 100%;
    text-decoration: none;
    transition: background 0.15s, border-color 0.15s;
  }
  .user-mini:hover {
    background: var(--color-blue-soft);
    border-color: var(--color-line);
  }
  .user-avatar {
    width: 36px; height: 36px; border-radius: 50%;
    background: linear-gradient(135deg, var(--color-blue), var(--color-red));
    color: #fff;
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 13px;
    flex-shrink: 0;
  }
  .user-info {
    flex: 1; min-width: 0;
    display: flex; flex-direction: column;
  }
  .user-name {
    font-size: 13px; font-weight: 700;
    color: var(--color-ink);
    line-height: 1.2;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .user-objective {
    font-size: 11px; color: var(--color-muted);
    line-height: 1.3;
    margin-top: 2px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  /* ===== mobile : sidebar horizontale en haut ===== */
  @media (max-width: 900px) {
    .app-sidebar {
      position: static;
      height: auto;
      flex-direction: row;
      align-items: center;
      padding: 12px 18px;
      border-right: none;
      border-bottom: 1px solid var(--color-line);
      gap: 16px;
      overflow-x: auto;
      overflow-y: hidden;
    }
    .app-brand {
      padding: 0; margin: 0;
      flex-shrink: 0;
    }
    /* En barre horizontale, la colonne n'existe plus : ni sous-titre, ni
       bascule, ni note de pied. Le drawer, lui, les remet (globals.css). */
    .app-brand-tag,
    .app-seg,
    .app-foot-note { display: none; }
    .app-nav {
      display: flex; flex-direction: row;
      flex: 1; gap: 4px;
      overflow-x: auto;
    }
    .app-nav-section { display: none; }
    .nav-item {
      padding: 7px 12px;
      font-size: 12.5px;
      white-space: nowrap;
      margin-bottom: 0;
    }
    .nav-item.is-active::before { display: none; }
    .nav-label { display: none; }
    .nav-item .nav-icon { display: flex; }
    .app-sidebar-foot {
      margin-top: 0;
      padding-top: 0;
      flex-direction: row;
      flex-shrink: 0;
    }
    .streak-card { display: none; }
    .user-mini { padding: 4px 8px; }
    .user-info { display: none; }
  }
`;
