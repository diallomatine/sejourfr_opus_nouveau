import Link from "next/link";

// ============ Cocarde + Wordmark + Brand link ============

export function Cocarde({ large = false }: { large?: boolean }) {
  return <div className={`cocarde ${large ? "lg" : ""}`} aria-hidden />;
}

export function Wordmark() {
  return (
    <span className="wordmark">
      Sejour<span className="fr">FR</span>
    </span>
  );
}

export function Brand({ href = "/" }: { href?: string }) {
  return (
    <Link
      href={href}
      style={{ display: "flex", alignItems: "center", gap: 12 }}
      aria-label="SejourFR — accueil"
    >
      <Cocarde />
      <Wordmark />
    </Link>
  );
}
