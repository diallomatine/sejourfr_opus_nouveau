"use client";

/**
 * **Le plan civique** (L10, `20_` §6).
 *
 * ⚠️ **Révoque le panneau précédent**, qui recopiait les priorités *figées* du
 * dernier diagnostic. Le plan est maintenant un **moteur** : il relit tout
 * l'historique des réponses à chaque lecture, y compris celles des séries et
 * des examens blancs (`20_` §8.2), et il dit **quand y revenir**.
 *
 * 🛑 **Rien n'est dérivé ici.** L'ordre des cibles, leur état de maîtrise, leur
 * échéance et leur verrou arrivent **servis**. Ce panneau les met en mots
 * (`lib/civic-plan.ts`) et ouvre ce qui existe déjà — la série ciblée, les
 * séries du thème, l'examen blanc.
 *
 * 🛑 **Le plan travaille au grain que le tagging permet**, et il le dit
 * (`20_` §3.3) : thème par thème tant que les questions ne sont pas taguées,
 * notion par notion ensuite. Ce n'est pas une panne, c'est la phase 1 de la
 * spec — et attendre le tagging pour offrir quoi que ce soit priverait le
 * candidat de ce qui est déjà mesurable.
 *
 * 🛑 **Le constat est intégralement gratuit.** Le `locked` servi porte sur la
 * **série**, jamais sur ce que le candidat a mesuré : un compte gratuit voit
 * ses priorités entières, avec leurs états et leurs compteurs.
 */
import {useCallback, useEffect, useState} from "react";
import Link from "next/link";
import {useRouter} from "next/navigation";
import {ArrowRight, Lock} from "lucide-react";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {civicPlanApi} from "@/lib/api";
import {
    CIVIC_PLAN_ALL_GOOD_TEXT,
    CIVIC_PLAN_ALL_GOOD_TITLE,
    CIVIC_PLAN_EXAM_HREF,
    CIVIC_PLAN_LOCKED_CTA,
    CIVIC_PLAN_LOCKED_NOTE,
    CIVIC_PLAN_NOW_CTA,
    CIVIC_PLAN_NOW_TITLE,
    CIVIC_PLAN_PRIORITIES_TITLE,
    CIVIC_PLAN_RESULT_SEUIL,
    CIVIC_PLAN_RESULT_TITLE,
    CIVIC_PLAN_REVIEW_TITLE,
    CIVIC_PLAN_SOLID_TITLE,
    CIVIC_PLAN_WORK_CTA,
    civicCibleTone,
    civicPlanAutresLabel,
    civicPlanGrainNote,
    civicPlanRaison,
    civicRevueLabel,
    civicSerieLabel,
} from "@/lib/civic-plan";
import {handleStartFailure} from "@/lib/start-failure";
import {themeSlug} from "@/lib/themes";
import {CIVIC_MAITRISE_LABEL} from "@/lib/types";
import type {CivicPlanCibleDto, CivicPlanDto} from "@/lib/types";

export function CivicPlanPanel() {
    const router = useRouter();
    const [plan, setPlan] = useState<CivicPlanDto | null>(null);
    const [erreur, setErreur] = useState<string | null>(null);
    const [enCours, setEnCours] = useState<string | null>(null);
    const [paywall, setPaywall] = useState(false);

    useEffect(() => {
        let vivant = true;
        civicPlanApi
            .get()
            .then((p) => {
                if (vivant) setPlan(p);
            })
            .catch(() => {
                // Best-effort : l'onglet reste sobre. Le constat existe déjà
                // côté diagnostic, on ne remplace pas un plan par une erreur.
            });
        return () => {
            vivant = false;
        };
    }, []);

    /**
     * Ouvre la série ciblée. 🛑 Le **403** est un refus attendu — le verrou du
     * serveur et le `locked` servi sont la même règle — et il ouvre l'offre,
     * jamais un message d'erreur technique.
     */
    const commencer = useCallback(
        async (cible: CivicPlanCibleDto) => {
            if (enCours) return;
            if (cible.locked) {
                setPaywall(true);
                return;
            }
            setEnCours(cible.id);
            setErreur(null);
            try {
                const attempt = await civicPlanApi.serie(cible.id, cible.grain);
                router.push(`/sessions/${attempt.id}`);
            } catch (e) {
                handleStartFailure(e, {
                    onPaywall: () => setPaywall(true),
                    onMessage: setErreur,
                    fallbackMessage: "Impossible de démarrer cette série.",
                });
                setEnCours(null);
            }
        },
        [enCours, router],
    );

    if (!plan || !plan.disponible) return null;

    const grainNote = civicPlanGrainNote(plan.grain);
    const autres = civicPlanAutresLabel(plan);
    const maintenant = new Date();

    return (
        <section className="cvp">
            {/* 1 — l'objectif. 🛑 Le seuil est SERVI : l'écran le dit sans le
                connaître, et il ne promet jamais la réussite. */}
            {plan.resultat && (
                <div className="cvp-objectif">
                    <p className="cvp-eyebrow">{CIVIC_PLAN_RESULT_TITLE}</p>
                    <p className="cvp-score">
                        <strong>{plan.resultat.bonnes}</strong> / {plan.resultat.posees}
                    </p>
                    <p className="cvp-seuil">
                        {CIVIC_PLAN_RESULT_SEUIL} : {plan.resultat.seuil} /{" "}
                        {plan.resultat.format}
                    </p>
                </div>
            )}

            {erreur && (
                <p className="cvp-erreur" role="alert">
                    {erreur}
                </p>
            )}

            {plan.prochaine ? (
                <>
                    {/* 2 — à faire maintenant, le bloc dominant. */}
                    <div className="cvp-now">
                        <p className="cvp-eyebrow">{CIVIC_PLAN_NOW_TITLE}</p>
                        <p className="cvp-now-theme">{plan.prochaine.themeLabel}</p>
                        <h2>{plan.prochaine.label}</h2>
                        <p className="cvp-now-raison">{civicPlanRaison(plan.prochaine)}</p>
                        <p className="cvp-now-serie">{civicSerieLabel(plan.prochaine)}</p>
                        <button
                            type="button"
                            className="btn btn-lg"
                            disabled={enCours === plan.prochaine.id}
                            onClick={() => void commencer(plan.prochaine!)}
                        >
                            {plan.prochaine.locked ? (
                                <>
                                    <Lock size={15} aria-hidden /> {CIVIC_PLAN_LOCKED_CTA}
                                </>
                            ) : (
                                <>
                                    {CIVIC_PLAN_NOW_CTA}{" "}
                                    <ArrowRight size={16} aria-hidden />
                                </>
                            )}
                        </button>
                        {plan.prochaine.locked && (
                            <p className="cvp-note">{CIVIC_PLAN_LOCKED_NOTE}</p>
                        )}
                    </div>

                    {/* 4 — les priorités, entières, verrouillées ou non. */}
                    <h2 className="cvp-h2">{CIVIC_PLAN_PRIORITIES_TITLE}</h2>
                    <ol className="cvp-list">
                        {plan.priorites.map((cible, rang) => (
                            <li key={cible.id} data-tone={civicCibleTone(cible)}>
                                <span className="cvp-rang">{rang + 1}</span>
                                <div className="cvp-body">
                                    <p className="cvp-label">{cible.label}</p>
                                    <p className="cvp-meta">
                                        {cible.themeLabel} ·{" "}
                                        {CIVIC_MAITRISE_LABEL[cible.maitrise]} ·{" "}
                                        {civicPlanRaison(cible)}
                                    </p>
                                </div>
                                <button
                                    type="button"
                                    className="cvp-cta"
                                    disabled={enCours === cible.id}
                                    onClick={() => void commencer(cible)}
                                >
                                    {cible.locked ? (
                                        <Lock size={14} aria-hidden />
                                    ) : (
                                        <>
                                            {CIVIC_PLAN_WORK_CTA}{" "}
                                            <ArrowRight size={15} aria-hidden />
                                        </>
                                    )}
                                </button>
                            </li>
                        ))}
                    </ol>
                    {autres && <p className="cvp-note">{autres}</p>}
                </>
            ) : (
                <div className="cvp-vide">
                    <h2>{CIVIC_PLAN_ALL_GOOD_TITLE}</h2>
                    <p>{CIVIC_PLAN_ALL_GOOD_TEXT}</p>
                    <Link href={CIVIC_PLAN_EXAM_HREF} className="btn">
                        Faire un examen blanc <ArrowRight size={16} aria-hidden />
                    </Link>
                </div>
            )}

            {/* 5 — révision d'entretien. 🛑 Secondaire, et JAMAIS présentée
                comme une alerte : ce sont des points acquis qu'on entretient. */}
            {plan.aRevoir.length > 0 && (
                <>
                    <h2 className="cvp-h2">{CIVIC_PLAN_REVIEW_TITLE}</h2>
                    <ul className="cvp-soft">
                        {plan.aRevoir.map((cible) => (
                            <li key={cible.id}>
                                <span>{cible.label}</span>
                                <em>{civicRevueLabel(cible, maintenant)}</em>
                            </li>
                        ))}
                    </ul>
                </>
            )}

            {/* 6 — ce qui est acquis. Le candidat n'a pas besoin de tout réviser. */}
            {plan.solides.length > 0 && (
                <>
                    <h2 className="cvp-h2">{CIVIC_PLAN_SOLID_TITLE}</h2>
                    <ul className="cvp-solides">
                        {plan.solides.map((cible) => (
                            <li key={cible.id}>
                                <Link href={`/entrainement/civique/${themeSlug(cible.themeCode)}`}>
                                    ✅ {cible.label}
                                </Link>
                            </li>
                        ))}
                    </ul>
                </>
            )}

            {grainNote && <p className="cvp-note">{grainNote}</p>}

            <PaywallSheet
                open={paywall}
                module="CIVIQUE"
                onClose={() => setPaywall(false)}
            />
            <Styles />
        </section>
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`, et ce n'est pas un oubli.**
 *
 * styled-jsx scope ses règles aux éléments rendus par **le même** composant :
 * dans un `Styles()` qui ne rend que la balise, aucun élément ne reçoit la
 * classe de scope, et **aucune règle ne s'applique**.
 */
function Styles() {
    return (
        <style>{`
            .cvp {
                max-width: 480px;
                margin: 0 auto;
                padding: 8px 16px 48px;
                display: flex;
                flex-direction: column;
                gap: 14px;
            }
            .cvp-eyebrow {
                margin: 0;
                font-family: var(--font-mono);
                font-size: 11px;
                letter-spacing: 0.08em;
                text-transform: uppercase;
                color: var(--color-muted-2);
            }
            .cvp-objectif {
                border: 1px solid var(--color-line);
                border-radius: 14px;
                padding: 14px;
            }
            .cvp-score {
                margin: 6px 0 0;
                font-family: var(--font-display);
                font-size: 30px;
                color: var(--color-ink);
            }
            .cvp-score strong { color: var(--color-blue); }
            .cvp-seuil {
                margin: 2px 0 0;
                font-size: 13px;
                color: var(--color-muted);
            }
            .cvp-now {
                background: var(--color-blue-light);
                border-radius: 16px;
                padding: 16px;
                display: flex;
                flex-direction: column;
                gap: 6px;
            }
            .cvp-now h2 {
                margin: 0;
                font-family: var(--font-display);
                font-size: 21px;
                color: var(--color-ink);
            }
            .cvp-now-theme {
                margin: 0;
                font-size: 12.5px;
                color: var(--color-blue-dark, #15296b);
            }
            .cvp-now-raison,
            .cvp-now-serie {
                margin: 0;
                font-size: 13.5px;
                color: var(--color-muted);
            }
            .cvp-now .btn { margin-top: 8px; }
            .cvp-h2 {
                font-family: var(--font-display);
                font-size: 20px;
                color: var(--color-ink);
                margin: 6px 0 0;
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
            .cvp-list li[data-tone="hot"] { border-left-color: var(--color-red); }
            .cvp-list li[data-tone="warn"] { border-left-color: var(--color-amber, #e8a317); }
            .cvp-list li[data-tone="ok"] { border-left-color: var(--color-green, #168f5b); }
            .cvp-rang {
                font-family: var(--font-mono);
                font-size: 13px;
                color: var(--color-muted-2);
            }
            .cvp-body { flex: 1; min-width: 0; }
            .cvp-label {
                margin: 0;
                font-size: 15px;
                color: var(--color-ink);
            }
            .cvp-meta {
                margin: 2px 0 0;
                font-size: 12px;
                line-height: 1.45;
                color: var(--color-muted);
            }
            .cvp-cta {
                display: inline-flex;
                align-items: center;
                gap: 5px;
                background: none;
                border: 0;
                cursor: pointer;
                font-size: 13.5px;
                font-weight: 600;
                color: var(--color-blue);
                white-space: nowrap;
            }
            .cvp-cta:disabled { opacity: 0.55; cursor: default; }
            .cvp-soft {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-direction: column;
                gap: 8px;
            }
            .cvp-soft li {
                display: flex;
                justify-content: space-between;
                gap: 10px;
                font-size: 14px;
                color: var(--color-ink);
            }
            .cvp-soft em {
                font-style: normal;
                font-size: 12.5px;
                color: var(--color-muted-2);
            }
            .cvp-solides {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-wrap: wrap;
                gap: 8px;
            }
            .cvp-solides a {
                font-size: 13.5px;
                color: var(--color-ink);
                text-decoration: none;
                border: 1px solid var(--color-line);
                border-radius: 999px;
                padding: 6px 12px;
            }
            .cvp-erreur {
                margin: 0;
                background: var(--color-red-light);
                color: var(--color-red-dark);
                border-radius: 12px;
                padding: 12px 14px;
                font-size: 13.5px;
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
