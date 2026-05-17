import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "images.unsplash.com" },
    ],
  },
  // Autorise les requêtes cross-origin vers les ressources de dev (HMR
  // WebSocket inclus) depuis le LAN, pour pouvoir tester sur un téléphone
  // physique branché sur le même réseau. Sans ça, le bundle React n'hydrate
  // pas côté mobile et le site reste statique (drawer ne s'ouvre pas, etc.).
  allowedDevOrigins: ["192.168.1.13"],
};

export default nextConfig;
