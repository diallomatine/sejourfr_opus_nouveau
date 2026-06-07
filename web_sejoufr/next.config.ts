import type {NextConfig} from "next";

// En-têtes de sécurité appliqués à toutes les routes. Volontairement sans CSP
// `script-src`/`style-src` stricte : le site utilise styled-jsx (styles inline)
// et Google Identity Services, qu'une CSP restrictive casserait sans nonces. On
// pose les directives CSP sûres (anti-clickjacking, blocage <base>/<object>) +
// les en-têtes classiques. Une CSP `script-src` complète (avec nonce) reste un
// chantier de durcissement à part.
const securityHeaders = [
    {key: "X-Frame-Options", value: "SAMEORIGIN"},
    {key: "X-Content-Type-Options", value: "nosniff"},
    {key: "Referrer-Policy", value: "strict-origin-when-cross-origin"},
    {
        // microphone=(self) : l'épreuve Expression orale enregistre via
        // MediaRecorder — un blocage total ferait échouer getUserMedia avec
        // "Permissions policy violation" quel que soit le réglage navigateur.
        key: "Permissions-Policy",
        value: "camera=(), microphone=(self), geolocation=(), interest-cohort=()",
    },
    {
        key: "Strict-Transport-Security",
        value: "max-age=63072000; includeSubDomains; preload",
    },
    {
        key: "Content-Security-Policy",
        value: "frame-ancestors 'self'; object-src 'none'; base-uri 'self'",
    },
];

const nextConfig: NextConfig = {
    async headers() {
        return [{source: "/:path*", headers: securityHeaders}];
    },
    images: {
        remotePatterns: [
            {protocol: "https", hostname: "images.unsplash.com"},
        ],
    },
    // Autorise les requêtes cross-origin vers les ressources de dev (HMR
    // WebSocket inclus) depuis le LAN, pour pouvoir tester sur un téléphone
    // physique branché sur le même réseau. Sans ça, le bundle React n'hydrate
    // pas côté mobile et le site reste statique (drawer ne s'ouvre pas, etc.).
    allowedDevOrigins: ["192.168.1.11"],
};

export default nextConfig;
