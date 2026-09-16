"use client";

import Link from "next/link";
import {useParams} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {
    ArrowLeft,
    ClipboardCheck,
    Compass,
    FileText,
    CircleCheck,
    type LucideIcon,
} from "lucide-react";
import {progressApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {planDomainFromSlug, planDomainLabel} from "@/lib/plan-domain";
import {
    Card,
    FilterChips,
    HistoryRow,
    InfoNote,
    LevelChart,
    Pad,
    PanelHead,
    ResultHero,
    SejourApp,
    Stack,
    Top,
    sejourStyles,
    type ChartPoint,
} from "@/app/_components/sejour/SejourKit";
import {progresEvolutionLabel} from "@/lib/progres";
import {SOURCE_EVALUATION_LABEL, cecrlIndex, niveauCecrlShort} from "@/lib/types";
import type {
    EpreuveHistoriqueDto,
    EvaluationQualifianteDto,
    NiveauCecrl,
    ProgressDto,
    ProgressEpreuveDto,
    SourceEvaluation,
} from "@/lib/types";

/** Ce que la liste contient, dit au candidat plutôt que deviné par lui. */
export const HISTORIQUE_TITLE = "Vos résultats";
/**
 * ⚠️ **Formulée pour rester vraie même quand la liste est vide.** « Les
 * évaluations qui déterminent votre niveau » était faux en EE/EO : le profil y
 * compte aussi l'entraînement libre, que cette page ne montre pas (arbitrage
 * ouvert, cf. `EpreuveHistoriqueService`). On dit donc ce que la liste
 * **contient**, pas ce qu'elle prétend expliquer.
 */
export const HISTORIQUE_LEAD =
    "Vos épreuves complètes et vos diagnostics sur cette épreuve. "
    + "Vos entraînements libres et vos petits sujets n'y figurent pas.";

/** 🛑 Une absence de mesure n'est pas une erreur, et se dit comme telle. */
export const HISTORIQUE_VIDE = "Aucune évaluation qualifiante pour l'instant.";
export const HISTORIQUE_VIDE_AIDE =
    "Un examen blanc, une épreuve passée seule ou un diagnostic apparaîtront "
    + "ici dès qu'ils auront été corrigés.";

export const HISTORIQUE_ERREUR =
    "Vos résultats n'ont pas pu être chargés. Réessayez dans un instant.";

/* -------------------------------------------------------------- le héros -- */

export const HISTORIQUE_NIVEAU_LABEL = "Niveau actuel";
export const HISTORIQUE_OBJECTIF_LABEL = "Objectif";

/* ------------------------------------------------------------ la courbe -- */

export const HISTORIQUE_COURBE_TITLE = "Votre évolution";
export const HISTORIQUE_COURBE_SUB = "Touchez un point pour voir l'évaluation.";

/* --------------------------------------------------------- l'historique -- */

export const HISTORIQUE_LISTE_TITLE = "Historique";

/** « 4 évaluations complètes ». 🛑 On compte des lignes servies, rien d'autre. */
export function historiqueCountLabel(n: number): string {
    return `${n} évaluation${n > 1 ? "s" : ""} complète${n > 1 ? "s" : ""}`;
}

/** Les trois filtres de la liste. 🛑 Ils partitionnent les **quatre** sources. */
export type HistoriqueFiltre = "TOUT" | "DIAGNOSTIC" | "EXAMEN";

export const HISTORIQUE_FILTRES: ReadonlyArray<{id: HistoriqueFiltre; label: string}> = [
    {id: "TOUT", label: "Tout"},
    {id: "DIAGNOSTIC", label: "Diagnostics"},
    {id: "EXAMEN", label: "Examens"},
];

/**
 * À quel filtre appartient une source.
 *
 * 🛑 **Les quatre valeurs ne se fondent pas deux à deux** ailleurs : ici on ne
 * les fond que pour **filtrer**, jamais pour les nommer — chaque ligne garde
 * son libellé gelé (`SOURCE_EVALUATION_LABEL`).
 */
export function historiqueFamille(source: SourceEvaluation): HistoriqueFiltre {
    return source === "DIAGNOSTIC_RAPIDE" || source === "DIAGNOSTIC_COMPLET"
        ? "DIAGNOSTIC"
        : "EXAMEN";
}

/**
 * Ce que le détail d'une ligne raconte : d'où vient la mesure.
 *
 * 🛑 **Rien qui prétende expliquer le palier courant.** Le niveau affiché est
 * la moyenne des trois derniers examens qualifiants (règle serveur) : écrire
 * « résultat pris en compte dans votre niveau actuel » sur une ligne précise
 * serait une affirmation que le front ne peut pas vérifier.
 */
export const HISTORIQUE_SOURCE_DETAIL: Record<SourceEvaluation, string> = {
    DIAGNOSTIC_RAPIDE: "Mesure issue de votre diagnostic rapide.",
    DIAGNOSTIC_COMPLET: "Mesure issue de votre diagnostic complet.",
    EPREUVE_SEULE: "Épreuve passée seule, en dehors d'un examen complet.",
    EXAMEN_BLANC: "Cette épreuve faisait partie d'un examen blanc complet.",
};

/** « Niveau estimé : B1. » — le palier servi, remis en tête du détail. */
export function historiqueNiveauEstime(niveau: NiveauCecrl): string {
    return `Niveau estimé : ${niveauCecrlShort(niveau)}.`;
}

/** Le pictogramme d'une provenance. */
const HISTORIQUE_SOURCE_ICON: Record<SourceEvaluation, LucideIcon> = {
    DIAGNOSTIC_RAPIDE: Compass,
    DIAGNOSTIC_COMPLET: ClipboardCheck,
    EPREUVE_SEULE: CircleCheck,
    EXAMEN_BLANC: FileText,
};

/** Ce que la liste compte, et ce qu'elle ne compte pas. */
export const HISTORIQUE_PORTEE_TITLE = "Ce qui compte ici :";
export const HISTORIQUE_PORTEE_TEXT =
    " diagnostics et épreuves complètes. Les petits sujets et les entraînements "
    + "libres restent disponibles ailleurs, mais ne modifient pas cet historique.";

/** Le lien vers le hub des historiques. */
export const HISTORIQUE_TOUS_LABEL = "Tous mes résultats";

/* ------------------------------------------------------------- l'échelle -- */

/**
 * L'échelle de paliers du profil TCF IRN, du plus bas au plus haut.
 *
 * 🛑 **Indexée par `cecrlIndex`**, l'autorité déjà en place : C1 et C2 y sont
 * rabattus sur B2, comme partout ailleurs dans le produit.
 */
const ECHELLE = ["<A1", "A1", "A2", "B1", "B2"] as const;

/** Sa position dans `ECHELLE` (0 = « <A1 »). */
function rang(niveau: NiveauCecrl | null): number {
    return cecrlIndex(niveau) + 1;
}

/**
 * L'échelle **affichée**, du haut vers le bas.
 *
 * 🛑 **Elle suit les données servies**, elle ne les rabat pas : une mesure en
 * dessous de A2 ouvre l'échelle vers le bas. La fenêtre minimale est A2 → B2,
 * celle de la maquette — trois lignes, l'amplitude utile du TCF IRN.
 */
function echelleAffichee(rangs: number[]): string[] {
    const bas = Math.min(2, ...rangs);
    const haut = Math.max(4, ...rangs);
    const ladder: string[] = [];
    for (let i = haut; i >= bas; i -= 1) ladder.push(ECHELLE[i]);
    return ladder;
}

/* --------------------------------------------------------------- dates --- */

/** « 14 sept. 2026 ». `null` quand le serveur n'a pas de date. */
function jourLong(iso: string | null): string | null {
    if (!iso) return null;
    return new Date(iso).toLocaleDateString("fr-FR", {
        day: "numeric", month: "short", year: "numeric",
    });
}

/** « 14 sept. » — l'abscisse de la courbe, où l'année ne tient pas. */
function jourCourt(iso: string | null): string {
    if (!iso) return "—";
    return new Date(iso).toLocaleDateString("fr-FR", {day: "numeric", month: "short"});
}

/* ----------------------------------------------------------------- vue --- */

/**
 * **« D'où sort mon niveau ? »** — les dernières évaluations *qualifiantes*
 * d'une épreuve TCF, refondues sur la maquette du propriétaire (2026-09-16).
 *
 * 🛑 **Rien n'est dérivé ici** : date, provenance et palier sont **servis**
 * (`GET /api/me/progress/tcf/{epreuve}/historique`), le palier courant,
 * l'objectif et le sens d'évolution viennent de `GET /api/me/progress`, et le
 * libellé d'une provenance vient de la table gelée `SOURCE_EVALUATION_LABEL`.
 *
 * 🛑 **Aucun appel de plus dans le cas nominal** : les deux lectures passent
 * par le cache de `progressApi`, que l'Accueil vient de remplir.
 *
 * 🛑 **Miroir de `EpreuveHistoriqueScreen` côté mobile**, bloc pour bloc.
 */
export function EpreuveHistoriqueView() {
    const params = useParams<{domaine: string}>();
    const {status} = useAuth();
    const epreuve = planDomainFromSlug(params?.domaine ?? "");

    const [historique, setHistorique] = useState<EpreuveHistoriqueDto | null>(null);
    const [progres, setProgres] = useState<ProgressDto | null>(null);
    const [erreur, setErreur] = useState(false);
    const [chargement, setChargement] = useState(true);
    const [filtre, setFiltre] = useState<HistoriqueFiltre>("TOUT");
    /** L'index **dans la liste servie** (la plus récente d'abord). */
    const [choisi, setChoisi] = useState<number | null>(null);

    useEffect(() => {
        // 🛑 **Sortir en laissant `chargement` à `true` fige la carte sur
        // « Chargement… » pour toujours** : une session non authentifiée ou en
        // erreur n'a rien à charger, et l'écran doit le dire. Le pendant mobile
        // n'a pas ce trou — un `FutureProvider` se résout toujours.
        if (status === "loading") return;
        if (status !== "authenticated" || !epreuve) {
            setChargement(false);
            return;
        }
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
        // 🛑 **Le palier courant est un CONFORT** : son échec laisse la liste
        // entière, il ne doit jamais empêcher de lire son historique.
        progressApi
            .get()
            .then((p) => {
                if (vivant) setProgres(p);
            })
            .catch(() => undefined);
        return () => {
            vivant = false;
        };
    }, [status, epreuve]);

    const evaluations = useMemo(
        () => historique?.evaluations ?? [],
        [historique],
    );

    /** L'épreuve, telle que l'Accueil la montre. `null` = pas encore chargée. */
    const situation: ProgressEpreuveDto | null = useMemo(() => {
        if (!progres || !epreuve) return null;
        return progres.tcf.epreuves.find((e) => e.epreuve === epreuve) ?? null;
    }, [progres, epreuve]);

    /** Du plus ancien au plus récent : une courbe se lit dans ce sens. */
    const chronologie = useMemo(
        () => [...evaluations].reverse(),
        [evaluations],
    );

    const ladder = useMemo(() => {
        const rangs = chronologie.map((e) => rang(e.niveau));
        if (progres?.tcf.objectif) rangs.push(rang(progres.tcf.objectif));
        return echelleAffichee(rangs);
    }, [chronologie, progres]);

    const points: ChartPoint[] = useMemo(() => {
        const haut = ECHELLE.indexOf(ladder[0] as (typeof ECHELLE)[number]);
        return chronologie.map((e) => ({
            date: jourCourt(e.mesureA),
            level: niveauCecrlShort(e.niveau),
            row: haut - rang(e.niveau),
        }));
    }, [chronologie, ladder]);

    // Une clé de domaine inconnue ne fabrique pas d'épreuve.
    if (!epreuve) {
        return (
            <SejourApp>
                {/* Même retour que le cas nominal : on arrive de l'Accueil dans
                    les deux cas, et deux destinations pour la même flèche se
                    lisent comme un bug. */}
                <Top title={HISTORIQUE_TITLE} backTo="/dashboard" />
                <Pad>
                    <Card>
                        <p className={sejourStyles.tiny}>{HISTORIQUE_VIDE}</p>
                    </Card>
                </Pad>
            </SejourApp>
        );
    }

    const visibles = evaluations
        .map((e, index) => ({e, index}))
        .filter(({e}) => filtre === "TOUT" || historiqueFamille(e.source) === filtre);

    return (
        <SejourApp>
            <Top
                kicker={planDomainLabel(epreuve)}
                title={HISTORIQUE_TITLE}
                backTo="/dashboard"
            />
            <Pad>
                <Stack>
                    {/* 🛑 **Le palier et l'objectif sont SERVIS**, et « — » est le
                        rendu d'une absence de mesure : jamais « A1 ». */}
                    <ResultHero
                        label={HISTORIQUE_NIVEAU_LABEL}
                        level={niveauCecrlShort(situation?.niveau ?? null)}
                        goalLabel={HISTORIQUE_OBJECTIF_LABEL}
                        goal={progres?.tcf.objectif
                            ? niveauCecrlShort(progres.tcf.objectif)
                            : null}
                        trend={situation ? progresEvolutionLabel(situation) : null}
                        note={HISTORIQUE_LEAD}
                    />

                    {/* 🛑 **Pas de courbe sans point** : un panneau vide
                        raconterait une absence comme un incident. */}
                    {points.length > 0 && (
                        <Card>
                            <PanelHead
                                title={HISTORIQUE_COURBE_TITLE}
                                sub={points.length > 1 ? HISTORIQUE_COURBE_SUB : null}
                            />
                            <LevelChart
                                ladder={ladder}
                                points={points}
                                activeIndex={choisi === null
                                    ? points.length - 1
                                    : evaluations.length - 1 - choisi}
                                onSelect={(i) =>
                                    setChoisi(evaluations.length - 1 - i)}
                            />
                        </Card>
                    )}

                    <Card>
                        <PanelHead
                            title={HISTORIQUE_LISTE_TITLE}
                            sub={evaluations.length > 0
                                ? historiqueCountLabel(evaluations.length)
                                : null}
                        />
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
                            <>
                                {/* 🛑 **Le filtre ne se montre que s'il a de quoi
                                    trier** : une rangée d'onglets au-dessus
                                    d'une ligne unique ne filtre rien. */}
                                {evaluations.length > 1 && (
                                    <FilterChips
                                        options={HISTORIQUE_FILTRES}
                                        value={filtre}
                                        onChange={setFiltre}
                                    />
                                )}
                                <Stack>
                                    {visibles.map(({e, index}) => (
                                        <Ligne
                                            key={`${e.source}-${e.mesureA ?? index}`}
                                            evaluation={e}
                                            open={choisi === index}
                                            onToggle={() =>
                                                setChoisi(choisi === index ? null : index)}
                                        />
                                    ))}
                                </Stack>
                            </>
                        )}
                        <InfoNote>
                            <b>{HISTORIQUE_PORTEE_TITLE}</b>
                            {HISTORIQUE_PORTEE_TEXT}
                        </InfoNote>
                        <Link href="/historique" className={sejourStyles.link}>
                            <ArrowLeft size={15} strokeWidth={2.4} aria-hidden />{" "}
                            {HISTORIQUE_TOUS_LABEL}
                        </Link>
                    </Card>
                </Stack>
            </Pad>
            <Styles />
        </SejourApp>
    );
}

/** Une évaluation : sa provenance, sa date, son palier, et son détail. */
function Ligne({evaluation, open, onToggle}: {
    evaluation: EvaluationQualifianteDto;
    open: boolean;
    onToggle: () => void;
}) {
    return (
        <HistoryRow
            icon={HISTORIQUE_SOURCE_ICON[evaluation.source]}
            title={SOURCE_EVALUATION_LABEL[evaluation.source]}
            date={jourLong(evaluation.mesureA)}
            level={niveauCecrlShort(evaluation.niveau)}
            active={open}
            open={open}
            onToggle={onToggle}
            detail={
                <>
                    <strong>{historiqueNiveauEstime(evaluation.niveau)}</strong>{" "}
                    {HISTORIQUE_SOURCE_DETAIL[evaluation.source]}
                </>
            }
        />
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`** — styled-jsx scope ses règles aux
 * éléments rendus par le même composant, et un `Styles()` qui ne rend que la
 * balise n'en applique aucune.
 *
 * 🛑 **Une seule règle reste ici** : l'état vide. Tout le reste de l'écran est
 * passé dans le KIT (`ResultHero`, `LevelChart`, `FilterChips`, `HistoryRow`,
 * `InfoNote`, `PanelHead`), avec son miroir Flutter dans la même passe.
 *
 * 🛑 **Aucune couleur en dur** : tokens `--color-*` uniquement.
 */
function Styles() {
    return (
        <style>{`
            .eh-vide {
                margin: 0 0 4px;
                font-size: 14.5px;
                font-weight: 800;
                color: var(--color-ink);
            }
        `}</style>
    );
}
