"use client";

import Link from "next/link";
import { ArrowLeft, ArrowRight, BookOpen, Crown, Lock, Sparkles } from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { SITE } from "@/lib/site";
import type { LandingCategory } from "@/lib/modules-data";

interface Props {
  category: LandingCategory;
  basePath: string;
  accent: "blue" | "red";
}

/**
 * Page d'une catégorie d'un module (Civique ou Naturalisation).
 *
 * Vitrine publique : présente la catégorie, ses chiffres, et envoie soit
 * vers `/inscription` (visiteur), soit vers `/entrainement?module=CIVIQUE`
 * (utilisateur connecté) pour démarrer une vraie session d'entraînement.
 *
 * Le runner backend (POST /api/attempts) exigeant un Bearer, on ne tente
 * pas de jouer les QCM depuis cette page publique.
 */
export function CategoryLanding({ category, basePath, accent }: Props) {
  const { user, status } = useAuth();
  const isAuthenticated = status === "authenticated";
  const isPremium = !!user?.isPremium;
  const free = SITE.freeQuestionsPerCategory;

  const total = category.questionCount;
  const visible = isPremium ? total : Math.min(free, total);
  const locked = !isPremium && total > free;
  const lockedCount = locked ? Math.max(0, total - free) : 0;

  const trainHref = isAuthenticated
    ? "/entrainement?module=CIVIQUE"
    : "/inscription";

  return (
    <div className={`cat-landing cat-accent-${accent}`}>
      <div className="container-x cat-wrap">
        <Link href={basePath} className="cat-back">
          <ArrowLeft size={16} />
          Retour aux catégories
        </Link>

        <header className="cat-head">
          <div className="cat-emoji" aria-hidden>{category.emoji}</div>
          <div className="cat-head-body">
            <div className="cat-eyebrow">Catégorie</div>
            <h1 className="cat-title">{category.name}</h1>
            <p className="cat-desc">{category.description}</p>
          </div>
        </header>

        <section className="cat-stats">
          <div className="cat-stat">
            <BookOpen size={18} />
            <div>
              <div className="cat-stat-value">{total}</div>
              <div className="cat-stat-label">questions au total</div>
            </div>
          </div>
          <div className="cat-stat">
            <Sparkles size={18} />
            <div>
              <div className="cat-stat-value">{visible}</div>
              <div className="cat-stat-label">
                {isPremium ? "accessibles" : `accessibles en gratuit`}
              </div>
            </div>
          </div>
          {locked && (
            <div className="cat-stat cat-stat-locked">
              <Lock size={18} />
              <div>
                <div className="cat-stat-value">+{lockedCount}</div>
                <div className="cat-stat-label">débloquées en Premium</div>
              </div>
            </div>
          )}
        </section>

        <section className="cat-cta-row">
          <Link href={trainHref} className="btn btn-lg cat-cta">
            {isAuthenticated ? "Démarrer l'entraînement" : "Créer un compte pour s'entraîner"}
            <ArrowRight size={16} className="arrow" />
          </Link>
          {!isAuthenticated && (
            <Link href="/connexion" className="btn btn-lg btn-ghost cat-cta">
              J&apos;ai déjà un compte
            </Link>
          )}
        </section>

        {!isPremium && lockedCount > 0 && (
          <aside className="cat-upsell">
            <div className="cat-upsell-icon" aria-hidden>
              <Crown size={28} />
            </div>
            <div className="cat-upsell-body">
              <div className="cat-upsell-head">
                <Crown size={16} className="cat-upsell-icon-mobile" aria-hidden />
                <span className="cat-upsell-label">
                  Encore <strong>{lockedCount}</strong> question{lockedCount > 1 ? "s" : ""} à débloquer
                </span>
              </div>
              <p className="cat-upsell-text">
                Passez Premium pour accéder à toutes les questions de cette catégorie,
                aux 20 examens blancs chronométrés et au suivi de progression complet.
              </p>
            </div>
            <Link href="/#tarifs" className="btn cat-upsell-cta">
              <Crown size={16} />
              Passer Premium · {SITE.premiumPriceLabel}
            </Link>
          </aside>
        )}

        <section className="cat-info">
          <h2 className="cat-info-title">Comment se déroule l&apos;entraînement</h2>
          <ol className="cat-info-list">
            <li>
              <span className="cat-info-num">1</span>
              <div>
                <div className="cat-info-step">Questions à choix multiples</div>
                <p className="cat-info-text">
                  Chaque question a 4 réponses possibles, dont une seule correcte.
                  Vous validez à votre rythme.
                </p>
              </div>
            </li>
            <li>
              <span className="cat-info-num">2</span>
              <div>
                <div className="cat-info-step">Correction immédiate</div>
                <p className="cat-info-text">
                  Après chaque réponse, une explication détaillée vous est présentée
                  pour comprendre le bon raisonnement.
                </p>
              </div>
            </li>
            <li>
              <span className="cat-info-num">3</span>
              <div>
                <div className="cat-info-step">Suivi de progression</div>
                <p className="cat-info-text">
                  Vos statistiques sont mises à jour question par question :
                  catégorie, taux de réussite, points faibles à revoir.
                </p>
              </div>
            </li>
          </ol>
        </section>
      </div>

      <style>{`
        .cat-landing {
          --accent: var(--color-blue);
          --accent-2: var(--color-blue-dark);
          --accent-soft: var(--color-blue-soft);
          padding: 32px 0 80px;
        }
        .cat-landing.cat-accent-red {
          --accent: var(--color-red);
          --accent-2: var(--color-red-dark);
          --accent-soft: var(--color-red-light);
        }
        .cat-wrap { display: flex; flex-direction: column; gap: 28px; }

        .cat-back {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          font-size: 13px;
          color: var(--color-muted);
          font-weight: 500;
          transition: color 0.15s;
          align-self: flex-start;
        }
        .cat-back:hover { color: var(--accent); }

        .cat-head {
          display: flex;
          gap: 18px;
          align-items: flex-start;
        }
        .cat-emoji {
          font-size: 56px;
          line-height: 1;
          flex-shrink: 0;
        }
        .cat-head-body { min-width: 0; }
        .cat-eyebrow {
          font-family: var(--font-mono);
          font-size: 11px;
          letter-spacing: 0.18em;
          text-transform: uppercase;
          color: var(--accent);
          font-weight: 500;
          margin-bottom: 8px;
        }
        .cat-title {
          font-family: var(--font-display);
          font-weight: 600;
          font-size: 38px;
          letter-spacing: -0.025em;
          line-height: 1.05;
          color: var(--color-ink);
        }
        .cat-desc {
          margin-top: 10px;
          font-size: 15px;
          color: var(--color-muted);
          max-width: 640px;
          line-height: 1.55;
        }

        .cat-stats {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
          gap: 12px;
        }
        .cat-stat {
          display: flex;
          gap: 12px;
          align-items: center;
          padding: 16px 18px;
          border-radius: 14px;
          background: #fff;
          border: 1px solid var(--color-line);
          color: var(--accent);
        }
        .cat-stat-value {
          font-family: var(--font-display);
          font-weight: 600;
          font-size: 24px;
          color: var(--color-ink);
          line-height: 1.05;
        }
        .cat-stat-label {
          font-size: 12.5px;
          color: var(--color-muted);
          margin-top: 2px;
        }
        .cat-stat-locked {
          background: rgba(232, 163, 23, 0.08);
          border-color: #F4D89E;
          color: #946100;
        }

        .cat-cta-row {
          display: flex;
          gap: 12px;
          flex-wrap: wrap;
        }
        .cat-cta { white-space: nowrap; }
        .cat-landing.cat-accent-red .cat-cta:not(.btn-ghost) {
          background: var(--color-red);
          border-color: var(--color-red);
        }
        .cat-landing.cat-accent-red .cat-cta:not(.btn-ghost):hover {
          background: var(--color-red-dark);
          border-color: var(--color-red-dark);
        }

        .cat-upsell {
          position: relative;
          display: grid;
          grid-template-columns: auto 1fr auto;
          gap: 20px;
          align-items: center;
          padding: 22px 24px;
          border-radius: 18px;
          border: 1px solid #F4D89E;
          background: linear-gradient(135deg, #FFF7E0, #FCEDC8);
        }
        .cat-upsell-icon {
          width: 56px; height: 56px;
          border-radius: 16px;
          display: inline-flex;
          align-items: center; justify-content: center;
          background: linear-gradient(135deg, #F4B83A, #C9870D);
          color: #fff;
          flex-shrink: 0;
        }
        .cat-upsell-icon-mobile { display: none; color: #B27500; }
        .cat-upsell-body { min-width: 0; }
        .cat-upsell-head {
          display: flex; align-items: center; gap: 8px;
          margin-bottom: 4px;
          color: #6F4500;
          font-weight: 600;
        }
        .cat-upsell-text {
          font-size: 13.5px;
          color: #5A3B00;
          line-height: 1.5;
        }
        .cat-upsell-cta { white-space: nowrap; }

        .cat-info {
          padding: 28px;
          border-radius: 18px;
          background: var(--accent-soft);
          border: 1px solid var(--color-line-2);
        }
        .cat-info-title {
          font-family: var(--font-display);
          font-weight: 500;
          font-size: 22px;
          color: var(--color-ink);
          margin-bottom: 16px;
          letter-spacing: -0.015em;
        }
        .cat-info-list {
          list-style: none;
          display: flex;
          flex-direction: column;
          gap: 14px;
        }
        .cat-info-list li {
          display: flex;
          gap: 14px;
          align-items: flex-start;
        }
        .cat-info-num {
          width: 30px; height: 30px;
          border-radius: 50%;
          background: var(--accent);
          color: #fff;
          font-family: var(--font-mono);
          font-weight: 600;
          font-size: 13px;
          display: inline-flex;
          align-items: center; justify-content: center;
          flex-shrink: 0;
        }
        .cat-info-step {
          font-weight: 700;
          font-size: 14.5px;
          color: var(--color-ink);
        }
        .cat-info-text {
          margin-top: 4px;
          font-size: 13.5px;
          color: var(--color-muted);
          line-height: 1.5;
        }

        @media (max-width: 720px) {
          .cat-title { font-size: 28px; }
          .cat-emoji { font-size: 42px; }
          .cat-head { gap: 14px; }
          .cat-upsell {
            grid-template-columns: 1fr;
            padding: 18px;
          }
          .cat-upsell-icon { display: none; }
          .cat-upsell-icon-mobile { display: inline-flex; }
          .cat-upsell-cta { width: 100%; }
          .cat-info { padding: 22px; }
          .cat-cta { width: 100%; justify-content: center; }
        }
      `}</style>
    </div>
  );
}
