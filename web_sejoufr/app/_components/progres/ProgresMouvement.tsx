"use client";

/**
 * **Progrès** (T28, `30_` §7) — « montrer le MOUVEMENT, pas un tableau de bord ».
 *
 * ⚠️ **Ce n'est pas un écran de plus.** `/statistiques` répond déjà à « où j'en
 * suis » (maîtrise par catégorie) ; ce bloc s'y greffe et répond à « qu'est-ce
 * qui a bougé ». Créer une troisième page « progression » aurait été la
 * troisième réponse à la même question — le dépôt en a déjà deux
 * (`/statistiques`, `/plan/progression`).
 *
 * 🛑 **Rien n'est calculé ici.** Les paliers, les sens d'évolution, les états de
 * maîtrise et les compteurs arrivent **servis** (`/api/me/progress`). Ce
 * composant met en forme, et les phrases vivent dans `lib/progres.ts`.
 *
 * 🛑 **Deux règles de la spec, plus faciles à violer qu'à tenir** :
 * - **aucun pourcentage de progression vers un palier** — un palier CECRL n'est
 *   pas une barre ;
 * - **aucune gamification** — l'activité se dit en jours travaillés, sans record
 *   à battre et sans rien à perdre.
 *
 * 🛑 **Le bloc 5 est un LIEN**, pas une seconde liste : les écrans d'historique
 * existent, les redupliquer créerait une seconde vérité.
 */
import {useEffect, useState} from "react";
import Link from "next/link";
import {ArrowRight, Lock} from "lucide-react";
import {progressApi} from "@/lib/api";
import {kitTone} from "@/lib/civic-diagnostic";
import {EPREUVE_PRESENTATION} from "@/lib/exam-durations";
import {
    PROGRES_ACTIVITE_TITLE,
    PROGRES_CIVIQUE_THEMES_TITLE,
    PROGRES_CIVIQUE_TITLE,
    PROGRES_COMPETENCES_LOCKED,
    PROGRES_COMPETENCES_TITLE,
    PROGRES_EPREUVES_TITLE,
    PROGRES_HISTORIQUE_HREF,
    PROGRES_HISTORIQUE_TEXT,
    PROGRES_HISTORIQUE_TITLE,
    PROGRES_LEAD,
    PROGRES_NIVEAU_TITLE,
    PROGRES_TITLE,
    PROGRES_VIDE_TEXT,
    progresActiviteLabel,
    progresCiviqueLabel,
    progresCiviqueScore,
    progresCompetencesLabel,
    progresEpreuveNiveau,
    progresEvolutionLabel,
    progresEvolutionTone,
    progresNiveauLabel,
    progresRegulariteLabel,
    progresStatutLabel,
    progresStatutTone,
} from "@/lib/progres";
import {CIVIC_THEME_STATE_LABEL} from "@/lib/types";
import type {ProgressDto} from "@/lib/types";

function jourCourt(iso: string | null): string | null {
    if (!iso) return null;
    return new Date(iso).toLocaleDateString("fr-FR", {day: "numeric", month: "short"});
}

export function ProgresMouvement() {
    const [progres, setProgres] = useState<ProgressDto | null>(null);

    useEffect(() => {
        let vivant = true;
        progressApi
            .get()
            .then((p) => {
                if (vivant) setProgres(p);
            })
            .catch(() => {
                // Best-effort : le reste de l'écran (maîtrise par catégorie)
                // n'a pas à disparaître parce qu'un bloc de mouvement manque.
            });
        return () => {
            vivant = false;
        };
    }, []);

    if (!progres) return null;

    const {tcf, civique, activite} = progres;
    const niveau = progresNiveauLabel(tcf);
    const competences = progresCompetencesLabel(tcf.competences);
    const civiqueLabel = progresCiviqueLabel(civique);
    const civiqueScore = progresCiviqueScore(civique);
    const regularite = progresRegulariteLabel(activite);

    return (
        <section className="pmv" aria-label={PROGRES_TITLE}>
            <header className="pmv-head">
                <h2>{PROGRES_TITLE}</h2>
                <p>{PROGRES_LEAD}</p>
            </header>

            {!tcf.disponible && !civique.disponible ? (
                <p className="pmv-vide">{PROGRES_VIDE_TEXT}</p>
            ) : null}

            {/* 1 — le niveau. 🛑 Deux paliers nommés, jamais une barre entre
                eux : « 68 % vers le B2 » n'a aucun sens mesurable. */}
            {tcf.disponible && niveau && (
                <div className="pmv-bloc">
                    <p className="pmv-eyebrow">{PROGRES_NIVEAU_TITLE}</p>
                    <p className="pmv-niveau">{niveau}</p>
                    {/* 🛑 Une courbe demande DEUX points. Avec un seul, on
                        n'annonce pas une trajectoire : on liste les mesures. */}
                    {tcf.historique.length > 1 && (
                        <ol className="pmv-frise">
                            {tcf.historique.map((point) => (
                                <li key={point.sessionId}>
                                    <span>{point.niveau ?? "—"}</span>
                                    <em>{jourCourt(point.mesureA)}</em>
                                </li>
                            ))}
                        </ol>
                    )}
                </div>
            )}

            {/* 2 — par épreuve. Les 4 sont là, évaluées ou non. */}
            {tcf.epreuves.length > 0 && (
                <div className="pmv-bloc">
                    <p className="pmv-eyebrow">{PROGRES_EPREUVES_TITLE}</p>
                    <ul className="pmv-epreuves">
                        {tcf.epreuves.map((e) => {
                            const presentation = EPREUVE_PRESENTATION[
                                e.epreuve as keyof typeof EPREUVE_PRESENTATION
                            ];
                            const marqueur = progresEvolutionLabel(e);
                            const statut = progresStatutLabel(e);
                            return (
                                <li key={e.epreuve}>
                                    <span aria-hidden>{presentation?.icon}</span>
                                    <span className="pmv-ep-label">
                                        {presentation?.label ?? e.epreuve}
                                    </span>
                                    {/* 🛑 Le statut est SERVI (`status`), et une
                                        épreuve jamais mesurée se dit « À
                                        évaluer » — jamais « À renforcer », qui
                                        déguiserait une absence de mesure en
                                        verdict (V040/V041/V042). */}
                                    {statut && (
                                        <span
                                            className="pmv-ep-statut"
                                            data-tone={progresStatutTone(e)}
                                        >
                                            {statut}
                                        </span>
                                    )}
                                    <span className="pmv-ep-niveau">
                                        {progresEpreuveNiveau(e)}
                                    </span>
                                    {/* 🛑 `INCONNUE` ne rend RIEN — surtout pas
                                        « = » : une épreuve non comparable n'a ni
                                        progressé ni tenu. */}
                                    {marqueur && (
                                        <em data-tone={progresEvolutionTone(e.evolution)}>
                                            {marqueur}
                                        </em>
                                    )}
                                </li>
                            );
                        })}
                    </ul>
                </div>
            )}

            {/* 3 — les compétences. 🛑 Le compteur reste, le DÉTAIL est premium. */}
            {competences && (
                <div className="pmv-bloc">
                    <p className="pmv-eyebrow">{PROGRES_COMPETENCES_TITLE}</p>
                    <p className="pmv-compte">{competences}</p>
                    {tcf.competences.locked ? (
                        <p className="pmv-note">
                            <Lock size={13} aria-hidden /> {PROGRES_COMPETENCES_LOCKED}
                        </p>
                    ) : (
                        <ul className="pmv-acquises">
                            {tcf.competences.dernieres.map((c) => (
                                <li key={c.skillId}>
                                    <span>{c.titre}</span>
                                    <em>{jourCourt(c.preuveA)}</em>
                                </li>
                            ))}
                        </ul>
                    )}
                </div>
            )}

            {/* Civique — 🛑 aucun palier CECRL de ce côté (`20_` §12). */}
            {civique.disponible && (
                <div className="pmv-bloc">
                    <p className="pmv-eyebrow">{PROGRES_CIVIQUE_TITLE}</p>
                    {civiqueScore && <p className="pmv-niveau">{civiqueScore}</p>}
                    {civiqueLabel && <p className="pmv-compte">{civiqueLabel}</p>}
                </div>
            )}

            {/* Civique — le détail par thème. 🛑 L'état arrive SERVI : on pose
                un libellé gelé dessus, on ne classe aucun nombre. Et
                `NON_EVALUE` est neutre, jamais ambre : le serveur n'a pas
                mesuré ce thème, il ne dit pas qu'il est fragile. */}
            {civique.themes.length > 0 && (
                <div className="pmv-bloc">
                    <p className="pmv-eyebrow">{PROGRES_CIVIQUE_THEMES_TITLE}</p>
                    <ul className="pmv-themes">
                        {civique.themes.map((t) => (
                            <li key={t.themeId}>
                                <span className="pmv-th-label">{t.label}</span>
                                <em data-tone={kitTone(t.etat)}>
                                    {CIVIC_THEME_STATE_LABEL[t.etat]}
                                </em>
                            </li>
                        ))}
                    </ul>
                </div>
            )}

            {/* 4 — l'activité. 🛑 Ni flamme, ni record, ni objectif : un
                compteur qu'on peut casser transforme une mesure en dette. */}
            <div className="pmv-bloc">
                <p className="pmv-eyebrow">{PROGRES_ACTIVITE_TITLE}</p>
                <p className="pmv-compte">{progresActiviteLabel(activite)}</p>
                <ul className="pmv-semaines" aria-hidden>
                    {activite.semaines.map((s) => (
                        <li key={s.debut}>
                            {Array.from({length: 7}, (_, i) => (
                                <span key={i} data-on={i < s.jours} />
                            ))}
                        </li>
                    ))}
                </ul>
                {regularite && <p className="pmv-note">{regularite}</p>}
            </div>

            {/* 5 — l'historique. 🛑 Un LIEN vers l'existant, pas une liste. */}
            <Link href={PROGRES_HISTORIQUE_HREF} className="pmv-lien">
                <span>
                    <strong>{PROGRES_HISTORIQUE_TITLE}</strong>
                    {PROGRES_HISTORIQUE_TEXT}
                </span>
                <ArrowRight size={16} aria-hidden />
            </Link>

            <Styles />
        </section>
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`** — styled-jsx scope ses règles aux
 * éléments rendus par le même composant, et un `Styles()` qui ne rend que la
 * balise n'en applique aucune.
 */
function Styles() {
    return (
        <style>{`
            .pmv {
                width: min(100%, 1180px);
                margin: 0 auto 8px;
                padding: 0 28px;
                display: flex;
                flex-direction: column;
                gap: 12px;
            }
            .pmv-head h2 {
                font-family: var(--font-display);
                font-size: 22px;
                color: var(--color-ink);
                margin: 0;
            }
            .pmv-head p {
                margin: 4px 0 0;
                font-size: 13.5px;
                color: var(--color-muted);
            }
            .pmv-bloc {
                border: 1px solid var(--color-line);
                border-radius: 14px;
                padding: 14px 16px;
            }
            .pmv-eyebrow {
                margin: 0 0 6px;
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.08em;
                text-transform: uppercase;
                color: var(--color-muted-2);
            }
            .pmv-niveau {
                margin: 0;
                font-family: var(--font-display);
                font-size: 24px;
                color: var(--color-ink);
            }
            .pmv-compte {
                margin: 0;
                font-size: 15px;
                color: var(--color-ink);
            }
            .pmv-vide {
                margin: 0;
                font-size: 14px;
                color: var(--color-muted);
            }
            .pmv-frise {
                list-style: none;
                display: flex;
                flex-wrap: wrap;
                gap: 14px;
                margin: 10px 0 0;
                padding: 0;
            }
            .pmv-frise li {
                display: flex;
                flex-direction: column;
                font-size: 14px;
                color: var(--color-ink);
            }
            .pmv-frise em,
            .pmv-acquises em {
                font-style: normal;
                font-size: 11.5px;
                color: var(--color-muted-2);
            }
            .pmv-epreuves,
            .pmv-themes,
            .pmv-acquises {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-direction: column;
                gap: 8px;
            }
            .pmv-epreuves li,
            .pmv-themes li {
                display: flex;
                align-items: center;
                flex-wrap: wrap;
                gap: 10px;
                font-size: 14px;
                color: var(--color-ink);
            }
            .pmv-ep-label,
            .pmv-th-label { flex: 1; min-width: 0; }
            .pmv-ep-statut {
                font-size: 12px;
                line-height: 1.4;
                padding: 2px 8px;
                border-radius: 999px;
                white-space: nowrap;
                border: 1px solid var(--color-line);
                color: var(--color-muted);
            }
            .pmv-ep-statut[data-tone="ok"] {
                border-color: color-mix(in srgb, var(--color-green) 35%, transparent);
                color: var(--color-green);
            }
            .pmv-ep-statut[data-tone="warn"] {
                border-color: color-mix(in srgb, var(--color-amber) 45%, transparent);
                color: var(--color-amber);
            }
            .pmv-ep-statut[data-tone="hot"] {
                border-color: color-mix(in srgb, var(--color-red) 30%, transparent);
                color: var(--color-red);
            }
            .pmv-themes em {
                font-style: normal;
                font-size: 12.5px;
                white-space: nowrap;
                color: var(--color-muted-2);
            }
            .pmv-themes em[data-tone="ok"] { color: var(--color-green); }
            .pmv-themes em[data-tone="warn"] { color: var(--color-amber); }
            .pmv-themes em[data-tone="hot"] { color: var(--color-red); }
            .pmv-ep-niveau {
                font-family: var(--font-mono);
                font-size: 12.5px;
                color: var(--color-muted);
            }
            .pmv-epreuves em {
                font-style: normal;
                font-size: 12.5px;
                white-space: nowrap;
            }
            .pmv-epreuves em[data-tone="up"] { color: var(--color-green, #168f5b); }
            .pmv-epreuves em[data-tone="down"] { color: var(--color-red); }
            .pmv-epreuves em[data-tone="flat"] { color: var(--color-muted-2); }
            .pmv-acquises li {
                display: flex;
                justify-content: space-between;
                gap: 10px;
                font-size: 14px;
                color: var(--color-ink);
            }
            .pmv-semaines {
                list-style: none;
                display: flex;
                gap: 10px;
                margin: 10px 0 0;
                padding: 0;
            }
            .pmv-semaines li {
                display: flex;
                gap: 3px;
            }
            .pmv-semaines span {
                width: 9px;
                height: 9px;
                border-radius: 3px;
                background: var(--color-line);
            }
            .pmv-semaines span[data-on="true"] { background: var(--color-blue); }
            .pmv-note {
                margin: 8px 0 0;
                display: flex;
                align-items: center;
                gap: 6px;
                font-size: 12.5px;
                line-height: 1.5;
                color: var(--color-muted-2);
            }
            .pmv-lien {
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 12px;
                border: 1px solid var(--color-line);
                border-radius: 14px;
                padding: 14px 16px;
                text-decoration: none;
                color: var(--color-ink);
            }
            .pmv-lien strong {
                display: block;
                font-size: 15px;
            }
            .pmv-lien span {
                font-size: 12.5px;
                color: var(--color-muted);
            }
            @media (max-width: 700px) {
                .pmv { padding: 0 16px; }
                .pmv-semaines { flex-wrap: wrap; }
            }
        `}</style>
    );
}
