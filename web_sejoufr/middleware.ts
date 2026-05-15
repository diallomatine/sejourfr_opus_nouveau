import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const COOKIE_NAME = "sejourfr.accessToken";

// Routes qui exigent un accessToken. Le check est sommaire (présence du
// cookie, pas validation cryptographique) : la vraie autorisation est faite
// par le backend Spring, qui rejette en 401 si le JWT est expiré ou mal
// formé. Côté front, ce middleware sert juste à éviter un flash de la page
// protégée avant que le client ne redirige.
const PROTECTED_PREFIXES = ["/dashboard", "/paiement", "/entrainement"];

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
