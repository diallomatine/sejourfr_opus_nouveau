import Link from "next/link";
import { examApi } from "@/lib/api";
import type { ExamTemplateSummary, Module as ModuleEnum } from "@/lib/types";

type SearchParams = Promise<{ module?: string }>;

export default async function ExamensBlancsPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const params = await searchParams;
  const filter: ModuleEnum | undefined =
    params.module === "TCF" ? "TCF" : params.module === "CIVIQUE" ? "CIVIQUE" : undefined;

  let exams: ExamTemplateSummary[] = [];
  let error: string | null = null;
  try {
    exams = await examApi.list(filter);
  } catch {
    error =
      "Impossible de charger la liste des examens. Vérifiez que le backend tourne sur le port 8080.";
  }

  const civique = exams.filter((e) => e.module === "CIVIQUE");
  const tcf = exams.filter((e) => e.module === "TCF");

  return (
    <>
      <header style={{ padding: "64px 0 24px", textAlign: "center" }}>
        <div className="container-x">
          <span
            className="eyebrow"
            style={{ display: "inline-block", marginBottom: 16 }}
          >
            Examens blancs · {exams.length} disponibles
          </span>
          <h1 className="el-h1">
            Préparez-vous en <em>conditions réelles</em>.
          </h1>
          <p className="el-lede">
            1 examen gratuit par module · {exams.length - 2} examens premium pour
            approfondir, varier les thématiques et viser les parcours CSP, CR ou
            naturalisation.
          </p>

          <div className="el-filters">
            <FilterLink href="/examens-blancs" active={!filter}>
              Tous · {exams.length}
            </FilterLink>
            <FilterLink
              href="/examens-blancs?module=CIVIQUE"
              active={filter === "CIVIQUE"}
            >
              Civique · {civique.length}
            </FilterLink>
            <FilterLink href="/examens-blancs?module=TCF" active={filter === "TCF"}>
              TCF IRN · {tcf.length}
            </FilterLink>
          </div>
        </div>
      </header>

      <section style={{ padding: "16px 0 80px" }}>
        <div className="container-x">
          {error && <div className="form-error">{error}</div>}

          {!error && exams.length === 0 && (
            <div className="el-empty">Aucun examen blanc disponible pour ce filtre.</div>
          )}

          <div className="el-grid">
            {exams.map((e) => (
              <ExamCard key={e.id} exam={e} />
            ))}
          </div>
        </div>
      </section>

      <style>{`
        .el-h1 {
          font-family: var(--font-display); font-weight: 500; font-size: 46px;
          line-height: 1.05; letter-spacing: -0.025em; margin: 0 0 14px;
        }
        .el-h1 em { font-style: italic; color: var(--color-red); }
        .el-lede {
          color: var(--color-muted); font-size: 17px;
          margin: 0 auto; max-width: 640px;
        }
        .el-filters {
          display: inline-flex; gap: 8px; flex-wrap: wrap;
          padding: 6px; margin-top: 32px;
          background: #fff; border: 1px solid var(--color-line);
          border-radius: 100px;
        }
        .el-filter {
          padding: 8px 18px; border-radius: 100px;
          font-family: var(--font-mono); font-size: 12px;
          letter-spacing: 0.06em; color: var(--color-muted);
          text-decoration: none; transition: all 0.15s;
        }
        .el-filter:hover { color: var(--color-blue); }
        .el-filter.active {
          background: var(--color-blue); color: #fff;
        }
        .el-empty {
          padding: 64px 0; text-align: center;
          color: var(--color-muted); font-size: 15px;
        }
        .el-grid {
          display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px;
        }
        @media (max-width: 960px) {
          .el-grid { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 640px) {
          .el-h1 { font-size: 32px; }
          .el-grid { grid-template-columns: 1fr; }
        }

        .el-card {
          display: flex; flex-direction: column;
          background: #fff;
          border: 1px solid var(--color-line);
          border-radius: 14px;
          padding: 22px 22px 18px;
          text-decoration: none; color: inherit;
          transition: all 0.18s;
          position: relative;
          min-height: 240px;
        }
        .el-card:hover {
          transform: translateY(-3px);
          border-color: var(--color-blue);
          box-shadow: 0 20px 40px -22px rgba(30, 58, 140, 0.18);
        }
        .el-card.locked:hover { border-color: var(--color-muted-2); }
        .el-card-head {
          display: flex; justify-content: space-between; align-items: flex-start;
          margin-bottom: 14px;
        }
        .el-tag {
          font-family: var(--font-mono); font-size: 10px;
          letter-spacing: 0.14em; text-transform: uppercase;
          padding: 4px 10px; border-radius: 100px;
          font-weight: 500;
        }
        .el-tag.civique { background: var(--color-blue-light); color: var(--color-blue); }
        .el-tag.tcf { background: var(--color-red-light); color: var(--color-red-dark); }
        .el-badge {
          font-family: var(--font-mono); font-size: 10px;
          letter-spacing: 0.14em; text-transform: uppercase;
          padding: 4px 10px; border-radius: 6px;
          font-weight: 500;
          display: inline-flex; align-items: center; gap: 4px;
        }
        .el-badge.free { background: var(--color-green); color: #fff; }
        .el-badge.premium {
          background: var(--color-paper-2); color: var(--color-muted);
        }
        .el-title {
          font-family: var(--font-display); font-weight: 500;
          font-size: 19px; line-height: 1.25; letter-spacing: -0.012em;
          margin: 0 0 6px;
          color: var(--color-ink);
        }
        .el-sub {
          font-family: var(--font-mono); font-size: 11px;
          letter-spacing: 0.06em; color: var(--color-muted);
          margin: 0 0 14px;
        }
        .el-desc {
          color: var(--color-ink-2); font-size: 13.5px; line-height: 1.5;
          margin: 0 0 16px; flex: 1;
        }
        .el-foot {
          display: flex; justify-content: space-between; align-items: center;
          padding-top: 14px;
          border-top: 1px solid var(--color-line-2);
        }
        .el-target {
          font-family: var(--font-mono); font-size: 10px;
          letter-spacing: 0.12em; text-transform: uppercase;
          color: var(--color-muted);
        }
        .el-cta {
          font-size: 13px; font-weight: 600;
          color: var(--color-blue);
        }
        .el-card.locked .el-cta { color: var(--color-muted); }
        .el-card.locked .el-title { color: var(--color-ink-2); }
      `}</style>
    </>
  );
}

function FilterLink({
  href,
  active,
  children,
}: {
  href: string;
  active: boolean;
  children: React.ReactNode;
}) {
  return (
    <Link href={href} className={`el-filter ${active ? "active" : ""}`}>
      {children}
    </Link>
  );
}

function ExamCard({ exam }: { exam: ExamTemplateSummary }) {
  const minutes = Math.round(exam.durationSeconds / 60);
  const isTcf = exam.module === "TCF";
  return (
    <Link
      href={`/examens-blancs/${exam.slug}`}
      className={`el-card ${exam.free ? "" : "locked"}`}
    >
      <div className="el-card-head">
        <span className={`el-tag ${isTcf ? "tcf" : "civique"}`}>
          ● {isTcf ? "TCF IRN" : "Civique"}
        </span>
        <span className={`el-badge ${exam.free ? "free" : "premium"}`}>
          {exam.free ? "Gratuit" : "🔒 Premium"}
        </span>
      </div>

      <h3 className="el-title">{exam.name}</h3>
      {exam.subtitle && <p className="el-sub">{exam.subtitle}</p>}
      {exam.description && (
        <p className="el-desc">
          {exam.description.length > 140
            ? exam.description.slice(0, 137) + "…"
            : exam.description}
        </p>
      )}

      <div className="el-foot">
        <span className="el-target">
          {renderTarget(exam)} · {exam.totalQuestions} Q · {minutes} min
        </span>
        <span className="el-cta">
          {exam.free ? "Commencer →" : "Découvrir →"}
        </span>
      </div>
    </Link>
  );
}

function renderTarget(e: ExamTemplateSummary): string {
  if (e.module === "CIVIQUE") {
    return e.targetProcedure ?? "Tous parcours";
  }
  return e.targetLevel ?? "Diagnostic";
}

