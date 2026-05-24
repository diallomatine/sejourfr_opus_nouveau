"use client";

import { useEffect, useRef, useState } from "react";
import { ApiException } from "@/lib/api";
import { useAuth } from "@/lib/auth-context";

/**
 * Bouton "Continuer avec Google" qui s'integre dans les pages /connexion et
 * /inscription.
 * <p>
 * Utilise Google Identity Services (GIS) cote navigateur : le script
 * https://accounts.google.com/gsi/client est charge une fois, puis on
 * appelle `google.accounts.id.initialize` + `renderButton` sur un div hote.
 * Le callback recoit un credential JWT que l'on POST au backend
 * (/api/auth/google). Le compte est cree automatiquement s'il n'existe pas.
 * <p>
 * Configuration : variable d'env {@code NEXT_PUBLIC_GOOGLE_CLIENT_ID} =
 * client web Google (format "xxx-xxx.apps.googleusercontent.com"). Quand
 * absente, le composant ne rend rien (silencieux en dev sans cles).
 */

interface Props {
  /** Pour adapter le libelle du bouton (signin = "Continue with Google", signup = "Sign up with Google"). */
  variant?: "signin" | "signup";
  /** Callback appele apres login reussi (avant le refresh user). Par defaut on ne fait rien : la page parente reagit via `useAuth().status === "authenticated"` dans son `useEffect`. */
  onSuccess?: () => void;
  /** Callback d'erreur affiche par la page parente. */
  onError?: (message: string) => void;
}

interface GsiCredentialResponse {
  credential: string;
  select_by?: string;
}

interface GsiClient {
  accounts: {
    id: {
      initialize: (opts: {
        client_id: string;
        callback: (resp: GsiCredentialResponse) => void;
        ux_mode?: "popup" | "redirect";
        auto_select?: boolean;
      }) => void;
      renderButton: (
        parent: HTMLElement,
        opts: {
          type?: "standard" | "icon";
          theme?: "outline" | "filled_blue" | "filled_black";
          size?: "large" | "medium" | "small";
          text?: "signin_with" | "signup_with" | "continue_with" | "signin";
          shape?: "rectangular" | "pill" | "circle" | "square";
          logo_alignment?: "left" | "center";
          width?: number;
          locale?: string;
        },
      ) => void;
    };
  };
}

declare global {
  interface Window {
    google?: GsiClient;
  }
}

const GSI_SCRIPT_SRC = "https://accounts.google.com/gsi/client";

export default function GoogleSignInButton({
  variant = "signin",
  onSuccess,
  onError,
}: Props) {
  const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";
  const { loginWithGoogle } = useAuth();
  const hostRef = useRef<HTMLDivElement | null>(null);
  const [scriptReady, setScriptReady] = useState(false);

  // Injection du script GIS une seule fois.
  useEffect(() => {
    if (!clientId) return;
    if (typeof window === "undefined") return;
    if (window.google?.accounts?.id) {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setScriptReady(true);
      return;
    }
    const existing = document.querySelector<HTMLScriptElement>(
      `script[src="${GSI_SCRIPT_SRC}"]`,
    );
    if (existing) {
      existing.addEventListener("load", () => setScriptReady(true), {
        once: true,
      });
      return;
    }
    const script = document.createElement("script");
    script.src = GSI_SCRIPT_SRC;
    script.async = true;
    script.defer = true;
    script.onload = () => setScriptReady(true);
    document.head.appendChild(script);
  }, [clientId]);

  // Callbacks gardés dans une ref : ils changent d'identité à chaque render de
  // la page parente (ex: onSuccess={() => router.push(...)}), mais on ne veut
  // PAS ré-exécuter initialize()/renderButton pour autant.
  const cbRef = useRef({ loginWithGoogle, onSuccess, onError });
  useEffect(() => {
    cbRef.current = { loginWithGoogle, onSuccess, onError };
  }, [loginWithGoogle, onSuccess, onError]);

  // initialize() est une config globale GIS : on ne l'appelle qu'une fois par
  // montage (le garde survit au double-invoke de StrictMode en dev). Sinon GIS
  // log "initialize() is called multiple times".
  const initedRef = useRef(false);

  useEffect(() => {
    if (!clientId) return;
    if (!scriptReady) return;
    if (!hostRef.current) return;
    if (!window.google?.accounts?.id) return;

    if (!initedRef.current) {
      window.google.accounts.id.initialize({
        client_id: clientId,
        ux_mode: "popup",
        callback: async (resp) => {
          if (!resp.credential) {
            cbRef.current.onError?.("Aucun token reçu de Google.");
            return;
          }
          try {
            await cbRef.current.loginWithGoogle(resp.credential);
            cbRef.current.onSuccess?.();
          } catch (err) {
            if (err instanceof ApiException) {
              cbRef.current.onError?.(err.message);
            } else {
              cbRef.current.onError?.("Connexion Google impossible. Réessayez.");
            }
          }
        },
      });
      initedRef.current = true;
    }

    // Vider l'hote avant render (en cas de re-mount).
    hostRef.current.innerHTML = "";
    window.google.accounts.id.renderButton(hostRef.current, {
      type: "standard",
      theme: "outline",
      size: "large",
      text: variant === "signup" ? "signup_with" : "continue_with",
      shape: "rectangular",
      logo_alignment: "left",
      locale: "fr",
    });
  }, [clientId, scriptReady, variant]);

  if (!clientId) {
    // En dev sans cles configurees, on n'affiche rien plutot que de polluer
    // l'UI avec un bouton qui ne fait rien. Cote prod, configurer
    // NEXT_PUBLIC_GOOGLE_CLIENT_ID dans .env.production.
    return null;
  }

  return (
    <div className="google-signin">
      <div className="google-signin-divider">
        <span>ou</span>
      </div>
      <div ref={hostRef} aria-label="Bouton Google Sign-In" />
      <style>{`
        .google-signin {
          display: flex;
          flex-direction: column;
          align-items: stretch;
          gap: 18px;
          margin-top: 18px;
        }
        .google-signin > div:last-child {
          display: flex;
          justify-content: center;
        }
        .google-signin-divider {
          position: relative;
          text-align: center;
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.14em;
          text-transform: uppercase;
          color: var(--color-muted-2);
        }
        .google-signin-divider::before,
        .google-signin-divider::after {
          content: "";
          position: absolute;
          top: 50%;
          width: calc(50% - 28px);
          height: 1px;
          background: var(--color-line);
        }
        .google-signin-divider::before { left: 0; }
        .google-signin-divider::after { right: 0; }
        .google-signin-divider span {
          background: #fff;
          padding: 0 4px;
        }
      `}</style>
    </div>
  );
}
