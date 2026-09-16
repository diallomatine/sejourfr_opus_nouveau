"use client";

import Link from "next/link";
import {useParams} from "next/navigation";
import {useEffect, useState} from "react";
import {ArrowLeft} from "lucide-react";
import {progressApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {planDomainFromSlug, planDomainLabel} from "@/lib/plan-domain";
import {Card, Pad, SejourApp, Top, sejourStyles} from "@/app/_components/sejour/SejourKit";
import {SOURCE_EVALUATION_LABEL, niveauCecrlShort} from "@/lib/types";
import type {EpreuveHistoriqueDto} from "@/lib/types";

/** Ce que la liste contient, dit au candidat plutôt que deviné par lui. */
export const HISTORIQUE_TITLE = "Vos résultats";
export const HISTORIQUE_LEAD =
    "Les évaluations qui déterminent votre niveau sur cette épreuve — "
    + "vos entraînements ciblés n'en font pas partie.";

/** 🛑 Une absence de mesure n'est pas une erreur, et se dit comme telle. */
export const HISTORIQUE_VIDE = "Aucune évaluation qualifiante pour l'instant.";
export const HISTORIQUE_VIDE_AIDE =
    "Un examen blanc, une épreuve passée seule ou un diagnostic apparaîtront "
    + "ici dès qu'ils auront été corrigés.";

export const HISTORIQUE_ERREUR =
    "Vos résultats n'ont pas pu être chargés. Réessayez dans un instant.";

/** « 14 sept. 2026 ». `null` quand le serveur n'a pas de date. */
function jourLong(iso: string | null): string | null {
    if (!iso) return null;
    return new Date(iso).toLocaleDateString("fr-FR", {
        day: "numeric", month: "short", year: "numeric",
    });
}

/**
 * **« D'où sort mon niveau ? »** — les dernières évaluations *qualifiantes*
 * d'une épreuve TCF.
 *
 * 🛑 **Rien n'est dérivé ici** : date, provenance et palier sont **servis**
 * (`GET /api/me/progress/tcf/{epreuve}/historique`), et le libellé d'une
 * provenance vient de la table gelée `SOURCE_EVALUATION_LABEL`.
 *
 * 🛑 **Miroir de `EpreuveHistoriqueScreen` côté mobile**, bloc pour bloc.
 */
export function EpreuveHistoriqueView() {
    const params = useParams<{domaine: string}>();
    const {status} = useAuth();
    const epreuve = planDomainFromSlug(params?.domaine ?? "");

    const [historique, setHistorique] = useState<EpreuveHistoriqueDto | null>(null);
    const [erreur, setErreur] = useState(false);
    const [chargement, setChargement] = useState(true);

    useEffect(() => {
        if (status !== "authenticated" || !epreuve) return;
        let vivant = true;
        setChargement(true);
        progressApi
            .historique(epreuve)
            .then((h) => {
                if (vivant) setHistorique(h);
            })
            .catch(() => {
                // 🛑 Un échec de chargement n'est pas « aucune évaluation » : on
                // ne range pas une panne dans le verdict le plus bas.
                if (vivant) setErreur(true);
            })
            .finally(() => {
                if (vivant) setChargement(false);
            });
        return () => {
            vivant = false;
        };
    }, [status, epreuve]);

    // Une clé de domaine inconnue ne fabrique pas d'épreuve.
    if (!epreuve) {
        return (
            <SejourApp>
                <Top title={HISTORIQUE_TITLE} backTo="/historique" />
                <Pad>
                    <Card>
                        <p className={sejourStyles.tiny}>{HISTORIQUE_VIDE}</p>
                    </Card>
                </Pad>
                <Styles />
            </SejourApp>
        );
    }

    const evaluations = historique?.evaluations ?? [];

    return (
        <SejourApp>
            <Top
                kicker={planDomainLabel(epreuve)}
                title={HISTORIQUE_TITLE}
                backTo="/dashboard"
            />
            <Pad>
                <Card>
                    <p className={sejourStyles.tiny}>{HISTORIQUE_LEAD}</p>
                    <div className="eh-liste">
                        {chargement ? (
                            <p className={sejourStyles.tiny}>Chargement…</p>
                        ) : erreur ? (
                            <p className={sejourStyles.tiny} role="alert">
                                {HISTORIQUE_ERREUR}
                            </p>
                        ) : evaluations.length === 0 ? (
                            <>
                                <p className="eh-vide">{HISTORIQUE_VIDE}</p>
                                <p className={sejourStyles.tiny}>{HISTORIQUE_VIDE_AIDE}</p>
                            </>
                        ) : (
                            <ul className="eh-lignes">
                                {evaluations.map((e, index) => {
                                    const date = jourLong(e.mesureA);
                                    return (
                                        <li key={`${e.source}-${e.mesureA ?? index}`}>
                                            <span className="eh-ligne-corps">
                                                <strong>{SOURCE_EVALUATION_LABEL[e.source]}</strong>
                                                {date && <em>{date}</em>}
                                            </span>
                                            <span className="eh-niveau">
                                                {niveauCecrlShort(e.niveau)}
                                            </span>
                                        </li>
                                    );
                                })}
                            </ul>
                        )}
                    </div>
                    <Link href="/historique" className={sejourStyles.link}>
                        <ArrowLeft size={15} strokeWidth={2.4} aria-hidden /> Tous mes résultats
                    </Link>
                </Card>
            </Pad>
            <Styles />
        </SejourApp>
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`** — styled-jsx scope ses règles aux
 * éléments rendus par le même composant, et un `Styles()` qui ne rend que la
 * balise n'en applique aucune.
 *
 * 🛑 **Aucune couleur en dur** : tokens `--color-*` et `--font-*` uniquement.
 */
function Styles() {
    return (
        <style>{`
            .eh-liste { margin: 12px 0 4px; }
            .eh-vide {
                margin: 0 0 4px;
                font-size: 14.5px;
                font-weight: 800;
                color: var(--color-ink);
            }
            .eh-lignes {
                list-style: none;
                margin: 0;
                padding: 0;
                display: flex;
                flex-direction: column;
                gap: 10px;
            }
            .eh-lignes li {
                display: flex;
                align-items: baseline;
                justify-content: space-between;
                gap: 12px;
            }
            .eh-ligne-corps { display: flex; flex-direction: column; min-width: 0; }
            .eh-ligne-corps strong {
                font-size: 14px;
                font-weight: 700;
                color: var(--color-ink);
            }
            .eh-ligne-corps em {
                font-style: normal;
                font-size: 12.5px;
                color: var(--color-muted);
                margin-top: 1px;
            }
            .eh-niveau {
                font-family: var(--font-mono);
                font-size: 13px;
                color: var(--color-blue);
                white-space: nowrap;
            }
        `}</style>
    );
}
