"use client";

/**
 * **Le plan civique, version thème** (`20_` §3.4, mode dégradé assumé).
 *
 * 🛑 **C'est un plan par THÈME, et il le dit.** Le plan par *notion* et la
 * répétition espacée (lot L10) demandent que les 1 016 questions soient taguées
 * — un chantier éditorial qui n'est pas fait. La spec prévoit noir sur blanc ce
 * repli : « Plan et diagnostic au niveau thème ». Attendre le tagging pour
 * offrir quoi que ce soit priverait le candidat de ce qui est déjà mesurable.
 *
 * 🛑 **Rien n'est dérivé ici.** L'ordre des thèmes et leur état arrivent servis
 * par le résultat du diagnostic : ce panneau les met en mots et ouvre
 * l'entraînement correspondant.
 */
import {useEffect, useState} from "react";
import Link from "next/link";
import {ArrowRight} from "lucide-react";
import {civicDiagnosticApi, userContentApi} from "@/lib/api";
import {CIVIC_PRIORITES_TITLE, themeTone} from "@/lib/civic-diagnostic";
import {themeSlug} from "@/lib/themes";
import {CIVIC_THEME_STATE_LABEL} from "@/lib/types";
import type {CivicDiagnosticResultDto} from "@/lib/types";

/** Le plan par notion arrive avec le tagging : on le dit, on ne le promet pas. */
const NOTE_THEME =
    "Votre plan travaille thème par thème. Il deviendra plus précis, notion par notion, "
    + "quand le référentiel civique sera complété.";

const TOUT_SOLIDE_TITLE = "Tous vos thèmes sont solides";
const TOUT_SOLIDE_TEXT =
    "Rien ne ressort comme prioritaire. Enchaînez sur un examen blanc pour vous mettre "
    + "en conditions réelles.";

export function CivicPlanPanel() {
    const [resultat, setResultat] = useState<CivicDiagnosticResultDto | null>(null);

    useEffect(() => {
        let vivant = true;
        void (async () => {
            try {
                const prep = await userContentApi.preparation();
                const sessionId = prep.civique.sessionId;
                if (!sessionId || !vivant) return;
                const r = await civicDiagnosticApi.readResult(sessionId);
                if (vivant) setResultat(r);
            } catch {
                // Best-effort : l'onglet reste vide plutôt que d'afficher une
                // erreur pour un plan qui existe déjà côté diagnostic.
            }
        })();
        return () => {
            vivant = false;
        };
    }, []);

    if (!resultat) return null;

    return (
        <section className="cvp">
            {resultat.priorites.length === 0 ? (
                <div className="cvp-vide">
                    <h2>{TOUT_SOLIDE_TITLE}</h2>
                    <p>{TOUT_SOLIDE_TEXT}</p>
                    <Link href="/examens-blancs?module=CIVIQUE" className="btn">
                        Faire un examen blanc <ArrowRight size={16} aria-hidden />
                    </Link>
                </div>
            ) : (
                <>
                    <h2 className="cvp-h2">{CIVIC_PRIORITES_TITLE}</h2>
                    <ol className="cvp-list">
                        {resultat.priorites.map((p) => (
                            <li key={p.code} data-tone={themeTone(p.etat)}>
                                <span className="cvp-rang">{p.rang}</span>
                                <div className="cvp-body">
                                    <p className="cvp-label">{p.label}</p>
                                    <p className="cvp-etat">
                                        {CIVIC_THEME_STATE_LABEL[p.etat]}
                                    </p>
                                </div>
                                <Link
                                    href={`/entrainement/civique/${themeSlug(p.code)}`}
                                    className="cvp-cta"
                                >
                                    Travailler <ArrowRight size={15} aria-hidden />
                                </Link>
                            </li>
                        ))}
                    </ol>
                    <p className="cvp-note">{NOTE_THEME}</p>
                </>
            )}
            <Styles />
        </section>
    );
}

function Styles() {
    return (
        <style jsx>{`
            .cvp {
                max-width: 480px;
                margin: 0 auto;
                padding: 8px 16px 48px;
                display: flex;
                flex-direction: column;
                gap: 12px;
            }
            .cvp-h2 {
                font-family: var(--font-display);
                font-size: 20px;
                color: var(--color-ink);
                margin: 0;
            }
            .cvp-list {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-direction: column;
                gap: 10px;
            }
            .cvp-list li {
                display: flex;
                align-items: center;
                gap: 12px;
                border: 1px solid var(--color-line);
                border-left-width: 4px;
                border-radius: 14px;
                padding: 14px;
            }
            li[data-tone="hot"] { border-left-color: var(--color-red); }
            li[data-tone="warn"] { border-left-color: var(--color-amber, #e8a317); }
            .cvp-rang {
                font-family: var(--font-mono);
                font-size: 13px;
                color: var(--color-muted-2);
            }
            .cvp-body { flex: 1; }
            .cvp-label {
                margin: 0;
                font-size: 15px;
                color: var(--color-ink);
            }
            .cvp-etat {
                margin: 2px 0 0;
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.04em;
                text-transform: uppercase;
                color: var(--color-muted);
            }
            .cvp-cta {
                display: inline-flex;
                align-items: center;
                gap: 5px;
                font-size: 13.5px;
                font-weight: 600;
                color: var(--color-blue);
                text-decoration: none;
                white-space: nowrap;
            }
            .cvp-note {
                margin: 4px 0 0;
                font-size: 12px;
                line-height: 1.5;
                color: var(--color-muted-2);
            }
            .cvp-vide {
                display: flex;
                flex-direction: column;
                gap: 10px;
                text-align: center;
            }
            .cvp-vide h2 {
                font-family: var(--font-display);
                font-size: 20px;
                color: var(--color-ink);
                margin: 0;
            }
            .cvp-vide p {
                margin: 0;
                font-size: 14px;
                color: var(--color-muted);
            }
        `}</style>
    );
}
