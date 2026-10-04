import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const COOKIE_NAME = "sejourfr.accessToken";

// Routes qui exigent une session. Le check est sommaire (présence du
// cookie) : la vraie autorisation est faite par le backend Spring. Le cookie
// est un MARQUEUR de session (valeur `1`, aucun jeton) posé par
// `tokenStorage.markSession` pour la durée du REFRESH token : un access
// expiré n'est pas une raison de renvoyer vers `/connexion`, le client le
// rafraîchit lui-même. Si le marqueur manque alors qu'un refresh valide est
// en localStorage, `/connexion` hydrate la session et renvoie vers `next`.
// /entrainement, /examens-blancs et /sessions sont publics (mode démo guest).
// /diagnostic aussi : le visiteur fait ses deux productions AVANT qu'on lui
// demande un compte (le Plan, lui, reste derrière le login).
// Le test est un préfixe : "/paiement" couvre donc aussi "/paiement/recapitulatif"
// (l'écran de choix d'un pass) — inutile de l'y ajouter, et surtout ne pas
// remplacer le startsWith par une égalité.
const PROTECTED_PREFIXES = ["/dashboard", "/favoris", "/paiement", "/plan", "/progression"];

export function middleware(req: NextRequest) {
  const { pathname, search } = req.nextUrl;

  if (!PROTECTED_PREFIXES.some((p) => pathname === p || pathname.startsWith(`${p}/`))) {
    return NextResponse.next();
  }

  const hasToken = req.cookies.has(COOKIE_NAME);
  if (hasToken) {
    return NextResponse.next();
  }

  // Garde la destination pour retourner dessus après login.
  const loginUrl = req.nextUrl.clone();
  loginUrl.pathname = "/connexion";
  loginUrl.searchParams.set("next", pathname + search);
  return NextResponse.redirect(loginUrl);
}

export const config = {
  // Évite que le middleware tourne sur les assets statiques et les routes Next internes.
  matcher: ["/((?!_next/static|_next/image|favicon|.*\\.(?:svg|png|jpg|jpeg|gif|webp)).*)"],
};
