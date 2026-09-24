"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useCallback, useEffect, useState} from "react";
import {Bookmark, BookmarkCheck, ChevronRight, CloudOff, Play} from "lucide-react";
import {ApiException, userContentApi} from "@/lib/api";
import {COMPTE_BACK_PROFIL, COMPTE_PROFIL_HREF} from "@/lib/compte";
import {
  FAVORIS_EMPTY_CTA,
  FAVORIS_EMPTY_HINT,
  FAVORIS_EMPTY_TITLE,
  FAVORIS_HREF,
  FAVORIS_LEAD,
  FAVORIS_LOAD_ERROR,
  FAVORIS_MODULE_LABEL,
  FAVORIS_PAGE_SIZE,
  FAVORIS_RETRY,
  FAVORIS_TITLE,
  favorisShowMore,
} from "@/lib/favoris";
import {entrainementHref} from "@/lib/module-switch";
import {type Module, type QuestionReviewResponse, questionTypeLabel} from "@/lib/types";
import {CompteAuth, CompteLoading, CompteShell} from "../compte/CompteParts";
import {FavoriDetailSheet} from "./FavoriDetailSheet";
import s from "./favoris.module.css";

const MODULES: Module[] = ["CIVIQUE", "TCF"];

/**
 * « Mes favoris » (`/favoris`), ouvert depuis le Profil (« Mon compte »).
 * Miroir mobile : `MesFavorisScreen` (`screens/favoris/mes_favoris_screen.dart`)
 * — même titre, même bascule Civique / TCF, mêmes cartes, même état vide, même
 * détail. Textes : `lib/favoris.ts`.
 */
export function FavorisView() {
  return (
    <Suspense fallback={<CompteLoading/>}>
      <CompteAuth next={FAVORIS_HREF}>
        {() => <FavorisInner/>}
      </CompteAuth>
    </Suspense>
  );
}

function FavorisInner() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const parcours: Module = searchParams?.get("module") === "TCF" ? "TCF" : "CIVIQUE";

  const [favorites, setFavorites] = useState<QuestionReviewResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [visible, setVisible] = useState(FAVORIS_PAGE_SIZE);
  const [selected, setSelected] = useState<QuestionReviewResponse | null>(null);

  const load = useCallback(async (m: Module) => {
    setLoading(true);
    setVisible(FAVORIS_PAGE_SIZE);
    try {
      setFavorites(await userContentApi.favorites(m));
      setLoadError(null);
    } catch (e) {
      setLoadError(e instanceof ApiException ? e.message : FAVORIS_LOAD_ERROR);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load(parcours);
  }, [parcours, load]);

  function selectModule(m: Module) {
    if (m === parcours) return;
    router.replace(`${pathname}?module=${m}`, {scroll: false});
  }

  const onToggleFavorite = useCallback(
    async (q: QuestionReviewResponse, wasFavorite: boolean) => {
      if (wasFavorite) {
        await userContentApi.removeFavorite(q.id);
        setFavorites((prev) => prev.filter((x) => x.id !== q.id));
      } else {
        await userContentApi.addFavorite(q.id);
        setFavorites((prev) => [q, ...prev.filter((x) => x.id !== q.id)]);
      }
    },
    [],
  );

  const shown = Math.min(favorites.length, visible);
  const remaining = favorites.length - shown;

  return (
    <CompteShell
      backHref={COMPTE_PROFIL_HREF}
      backLabel={COMPTE_BACK_PROFIL}
      title={FAVORIS_TITLE}
      lead={FAVORIS_LEAD}
    >
      <div className={s.switch} role="tablist" aria-label="Parcours">
        {MODULES.map((m) => (
          <button
            key={m}
            type="button"
            role="tab"
            aria-selected={m === parcours}
            className={`${s.switchTab} ${m === parcours ? s.switchActive : ""}`}
            onClick={() => selectModule(m)}
          >
            {FAVORIS_MODULE_LABEL[m]}
          </button>
        ))}
      </div>

      {loading ? (
        <div className={s.list} aria-busy>
          {[0, 1, 2, 3, 4].map((i) => (
            <div key={i} className={s.skeleton}/>
          ))}
        </div>
      ) : loadError ? (
        <div className={s.error}>
          <CloudOff size={36} aria-hidden/>
          <p>{loadError}</p>
          <button type="button" className={s.retry} onClick={() => void load(parcours)}>
            {FAVORIS_RETRY}
          </button>
        </div>
      ) : favorites.length === 0 ? (
        <div className={s.empty}>
          <span className={s.emptyIcon} aria-hidden>
            <Bookmark size={34}/>
          </span>
          <h2 className={s.emptyTitle}>{FAVORIS_EMPTY_TITLE}</h2>
          <p className={s.emptyHint}>{FAVORIS_EMPTY_HINT}</p>
          <Link href={entrainementHref(parcours)} className={s.emptyCta}>
            <Play size={16} aria-hidden/>
            {FAVORIS_EMPTY_CTA}
          </Link>
        </div>
      ) : (
        <div className={s.list}>
          {favorites.slice(0, shown).map((q) => (
            <button key={q.id} type="button" className={s.card} onClick={() => setSelected(q)}>
              <span className={s.cardBody}>
                <span className={s.cardHead}>
                  <span className={s.cardIcon} aria-hidden>
                    <BookmarkCheck size={14}/>
                  </span>
                  <span className={`${s.tag} ${s.tagRed}`}>{q.difficulty}</span>
                  <span className={`${s.tag} ${s.tagBlue}`}>{questionTypeLabel(q.questionType)}</span>
                  <ChevronRight className={s.cardChevron} size={20} aria-hidden/>
                </span>
                <span className={s.statement}>{q.statement}</span>
                <span className={s.theme}>
                  <Bookmark size={12} aria-hidden/>
                  <span>{q.themeName}</span>
                </span>
              </span>
            </button>
          ))}
          {remaining > 0 && (
            <button
              type="button"
              className={s.more}
              onClick={() => setVisible((n) => n + FAVORIS_PAGE_SIZE)}
            >
              {favorisShowMore(remaining)}
            </button>
          )}
        </div>
      )}

      {selected && (
        <FavoriDetailSheet
          question={selected}
          isFavorite={favorites.some((f) => f.id === selected.id)}
          onClose={() => setSelected(null)}
          onToggleFavorite={(was) => onToggleFavorite(selected, was)}
        />
      )}
    </CompteShell>
  );
}
