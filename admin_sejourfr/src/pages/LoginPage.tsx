import { useState } from "react";
import { Navigate, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { HttpError } from "../api/http";
import styles from "./LoginPage.module.css";

interface LocationState {
  from?: string;
}

export function LoginPage() {
  const { isAuthenticated, login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const state = location.state as LocationState | null;
  const from = state?.from ?? "/dashboard";

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />;
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login(email, password);
      navigate(from, { replace: true });
    } catch (err) {
      if (err instanceof HttpError && err.status === 401) {
        setError("Identifiants invalides.");
      } else if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Erreur de connexion.");
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className={styles.page}>
      <div className={styles.card}>
        <div className={styles.brand}>
          <div className={styles.cocarde} />
          <div>
            <div className={styles.brandName}>
              Sejour<span className={styles.fr}>FR</span>
            </div>
            <div className={styles.brandTag}>Console admin</div>
          </div>
        </div>

        <div className={styles.eyebrow}>§ Authentification</div>
        <h1 className={styles.title}>Connectez-<em>vous</em></h1>

        <form className={styles.form} onSubmit={handleSubmit}>
          <div className={styles.field}>
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              required
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@sejourfr.fr"
            />
          </div>

          <div className={styles.field}>
            <label htmlFor="password">Mot de passe</label>
            <input
              id="password"
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </div>

          {error && <div className={styles.error}>{error}</div>}

          <button type="submit" className={styles.submit} disabled={submitting}>
            {submitting ? "Connexion..." : "Se connecter"}
          </button>
        </form>

        <div className={styles.footer}>
          Reserve aux administrateurs SejourFR.
        </div>
      </div>
    </div>
  );
}
