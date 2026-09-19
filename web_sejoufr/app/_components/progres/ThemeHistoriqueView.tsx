"use client";

import Link from "next/link";
import {useParams} from "next/navigation";
import {useEffect, useMemo, useState} from "react";
import {ArrowRight, FileText} from "lucide-react";
import {attemptApi, progressApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {civicThemeExamsHref, themeSlug} from "@/lib/themes";
import {CIVIQUE_LABEL} from "@/lib/preparation";
import {
    Card,
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
} from "@/app/_components/sejour/SejourKit";
import {
    civiqueThemeCourbe,
    jourLong,
    NON_MESURE_LABEL,
    THEME_RESULTATS_COURBE_SUB,
    THEME_RESULTATS_COURBE_TITLE,
    THEME_RESULTATS_COURBE_UN_POINT,
    THEME_RESULTATS_ERREUR,
    THEME_RESULTATS_EXAMENS_LABEL,
    THEME_RESULTATS_HERO_LABEL,
    THEME_RESULTATS_LEAD,
    THEME_RESULTATS_LISTE_TITLE,
    THEME_RESULTATS_PORTEE_TEXT,
    THEME_RESULTATS_PORTEE_TITLE,
    THEME_RESULTATS_SANS_SEUIL,
    THEME_RESULTATS_SEUIL_LABEL,
    THEME_RESULTATS_TITLE,
    THEME_RESULTATS_VIDE,
    THEME_RESULTATS_VIDE_AIDE,
    themeResultatsCountLabel,
    themeResultatsExamenTitle,
    themeResultatsScore,
    themeResultatsSeuilDetail,
    themeResultatsVerdict,
} from "@/lib/progres";
import {CIVIC_THEME_STATE_LABEL} from "@/lib/types";
import type {
    AttemptSummaryResponse,
    CivicPlanThemeLigneDto,
    ProgressDto,
} from "@/lib/types";

/** Un examen blanc de thème réduit à ce que l'écran en montre. */
type Mesure = {
    id: string;
    slot: number | null;
    date: string | null;
    score: number;
    total: number;
    seuil: number | null;
};

/**
 * Les examens qui portent réellement une mesure, dans l'**ordre servi**.
 *
 * 🛑 Un examen non terminé, sans score ou sans total n'est pas un résultat : il
 * ne compte ni sur la courbe, ni dans « N examens blancs ».
 */
function mesurables(servis: AttemptSummaryResponse[]): Mesure[] {
    const out: Mesure[] = [];
    for (const a of servis) {
        if (!a.finishedAt || a.score == null) continue;
        if (a.totalQuestions == null || a.totalQuestions <= 0) continue;
        out.push({
            id: a.id,
            slot: a.slotNumber ?? null,
            date: a.finishedAt,
            score: a.score,
            total: a.totalQuestions,
            seuil: a.passThreshold ?? null,
        });
    }
    return out;
}

/**
 * **« Où j'en suis sur ce thème ? »** — l'écran ouvert par « Voir mes
 * résultats » d'une ligne de thème civique de l'Accueil.
 *
 * 🛑 **Ce n'est pas la grille des examens blancs.**
 * `/entrainement/civique/[theme]/examens` est là où l'on **passe** un examen ;
 * celle-ci est là où l'on **lit** ses résultats — d'où le lien de pied qui mène
 * à l'autre, et pas l'inverse.
 *
 * 🛑 **Rien n'est classé ici, et le civique n'a AUCUN palier CECRL.** L'état du
 * thème arrive **servi** (`CivicThemeState`, via `GET /api/me/progress` — que
 * l'Accueil vient de mettre en cache, donc aucun appel de plus dans le cas
 * nominal), et chaque examen porte son score, son total et son seuil **servis**
 * avec lui (`GET /api/me/attempts?type=MOCK_EXAM&module=CIVIQUE&themeId=…`).
 * Une absence de mesure se **dit** : jamais un `0 / 20`, jamais un palier
 * inventé.
 *
 * 🛑 **Miroir de `ThemeHistoriqueScreen` côté mobile**, bloc pour bloc.
 */
export function ThemeHistoriqueView() {
    const params = useParams<{theme: string}>();
    const ref = params?.theme ?? "";
    const {status} = useAuth();

    const [progres, setProgres] = useState<ProgressDto | null>(null);
    const [examens, setExamens] = useState<AttemptSummaryResponse[] | null>(null);
    const [erreur, setErreur] = useState(false);
    const [chargement, setChargement] = useState(true);
    /** L'index **dans la liste servie** (la plus récente d'abord). */
    const [choisi, setChoisi] = useState<number | null>(null);

    useEffect(() => {
        // 🛑 **Sortir en laissant `chargement` à `true` fige la carte sur
        // « Chargement… » pour toujours** : une session non authentifiée n'a
        // rien à charger, et l'écran doit le dire. Le pendant mobile n'a pas ce
        // trou — un `FutureProvider` se résout toujours.
        if (status === "loading") return;
        if (status !== "authenticated" || !ref) {
            setChargement(false);
            return;
        }
        let vivant = true;
        setChargement(true);
        // 🛑 **Le thème et son état viennent de la MÊME lecture que l'Accueil** :
        // c'est elle qui porte `themeId`, et c'est ce `themeId` servi que
        // l'historique filtre — aucun identifiant n'est fabriqué.
        progressApi
            .get()
            .then((p) => {
                if (!vivant) return null;
                setProgres(p);
                const ligne = p.civique.themes.find(
                    (t) => t.themeId === ref || themeSlug(t.code) === ref,
                );
                if (!ligne) return null;
                return attemptApi.listMine({
                    type: "MOCK_EXAM",
                    module: "CIVIQUE",
                    themeId: ligne.themeId,
                    limit: 30,
                });
            })
            .then((liste) => {
                if (vivant && liste) setExamens(liste);
            })
            .catch(() => {
                // 🛑 Un échec de chargement n'est pas « aucun examen » : on ne
                // range pas une panne dans le verdict le plus bas.
                if (vivant) setErreur(true);
            })
            .finally(() => {
                if (vivant) setChargement(false);
            });
        return () => {
            vivant = false;
        };
    }, [status, ref]);

    /** La ligne de thème, telle que l'Accueil la montre. */
    const theme: CivicPlanThemeLigneDto | null = useMemo(() => {
        if (!progres) return null;
        return (
            progres.civique.themes.find(
                (t) => t.themeId === ref || themeSlug(t.code) === ref,
            ) ?? null
        );
    }, [progres, ref]);

    const mesures = useMemo(() => mesurables(examens ?? []), [examens]);

    /* 🛑 **L'échelle et les points viennent de `civiqueThemeCourbe`**, l'unique
       autorité : le maximum et le seuil sont ceux des examens SERVIS, jamais
       les 20 / 16 du format recopiés dans un écran. */
    const {rungs, points} = useMemo(() => civiqueThemeCourbe(mesures), [mesures]);

    const dernier = mesures[0] ?? null;
    /* Le segment d'URL de la grille : le slug du thème dès qu'il est servi,
       sinon la référence reçue (un UUID hérité résout des deux côtés). */
    const examensHref = civicThemeExamsHref(theme ? themeSlug(theme.code) : ref);

    return (
        <SejourApp>
            <Top
                kicker={theme?.label ?? CIVIQUE_LABEL}
                title={THEME_RESULTATS_TITLE}
                backTo="/dashboard"
            />
            <Pad>
                <Stack>
                    {/* 🛑 **Le dernier score et le seuil sont SERVIS**, et « — »
                        est le rendu d'une absence de mesure : jamais un « 0 ». */}
                    <ResultHero
                        label={THEME_RESULTATS_HERO_LABEL}
                        level={dernier
                            ? themeResultatsScore(dernier.score, dernier.total)
                            : "—"}
                        goalLabel={THEME_RESULTATS_SEUIL_LABEL}
                        goal={dernier && dernier.seuil != null
                            ? themeResultatsScore(dernier.seuil, dernier.total)
                            : null}
                        /* 🛑 **L'état arrive servi**, avec son libellé gelé :
                           `NON_EVALUE` se dit « À évaluer », jamais « faible ». */
                        trend={theme
                            ? theme.etat === "NON_EVALUE"
                                ? NON_MESURE_LABEL
                                : CIVIC_THEME_STATE_LABEL[theme.etat]
                            : null}
                        note={THEME_RESULTATS_LEAD}
                    />

                    {/* 🛑 **Pas de courbe sans point** : un panneau vide
                        raconterait une absence comme un incident. Un seul examen
                        rend un seul point — la courbe reste honnête. */}
                    {points.length > 0 && (
                        <Card>
                            <PanelHead
                                title={THEME_RESULTATS_COURBE_TITLE}
                                sub={points.length > 1
                                    ? THEME_RESULTATS_COURBE_SUB
                                    : THEME_RESULTATS_COURBE_UN_POINT}
                            />
                            <LevelChart
                                rungs={rungs}
                                points={points}
                                activeIndex={choisi === null
                                    ? points.length - 1
                                    : mesures.length - 1 - choisi}
                                onSelect={(i) =>
                                    setChoisi(mesures.length - 1 - i)}
                            />
                        </Card>
                    )}

                    <Card>
                        <PanelHead
                            title={THEME_RESULTATS_LISTE_TITLE}
                            sub={mesures.length > 0
                                ? themeResultatsCountLabel(mesures.length)
                                : null}
                        />
                        {chargement ? (
                            <p className={sejourStyles.tiny}>Chargement…</p>
                        ) : erreur ? (
                            <p className={sejourStyles.tiny} role="alert">
                                {THEME_RESULTATS_ERREUR}
                            </p>
                        ) : mesures.length === 0 ? (
                            <>
                                <p className="th-vide">{THEME_RESULTATS_VIDE}</p>
                                <p className={sejourStyles.tiny}>
                                    {THEME_RESULTATS_VIDE_AIDE}
                                </p>
                            </>
                        ) : (
                            /* 🛑 **Aucun filtre** : les lignes sont toutes de la
                               même nature. Une rangée d'onglets au-dessus d'une
                               liste homogène ne filtre rien. */
                            <Stack>
                                {mesures.map((m, index) => (
                                    <Ligne
                                        key={m.id}
                                        mesure={m}
                                        open={choisi === index}
                                        onToggle={() =>
                                            setChoisi(choisi === index ? null : index)}
                                    />
                                ))}
                            </Stack>
                        )}
                        <InfoNote>
                            <b>{THEME_RESULTATS_PORTEE_TITLE}</b>
                            {THEME_RESULTATS_PORTEE_TEXT}
                        </InfoNote>
                        {/* 🛑 **La grille des examens blancs**, adresse déclarée
                            une seule fois (`civicThemeExamsHref`) : c'est là
                            qu'on PASSE un examen, pas là qu'on lit ses
                            résultats. */}
                        <Link href={examensHref} className={sejourStyles.link}>
                            {THEME_RESULTATS_EXAMENS_LABEL}{" "}
                            <ArrowRight size={15} strokeWidth={2.4} aria-hidden />
                        </Link>
                    </Card>
                </Stack>
            </Pad>
            <Styles />
        </SejourApp>
    );
}

/** Un examen : son rang de créneau, sa date, son score, et son détail. */
function Ligne({mesure, open, onToggle}: {
    mesure: Mesure;
    open: boolean;
    onToggle: () => void;
}) {
    const verdict = themeResultatsVerdict(mesure.score, mesure.seuil);
    return (
        <HistoryRow
            icon={FileText}
            title={themeResultatsExamenTitle(mesure.slot)}
            date={jourLong(mesure.date)}
            level={themeResultatsScore(mesure.score, mesure.total)}
            active={open}
            open={open}
            onToggle={onToggle}
            /* 🛑 **Deux nombres servis et leur comparaison**, jamais un état
               pédagogique : « au-dessus du seuil » n'est pas un palier. Sans
               seuil servi, on dit l'absence plutôt que d'inventer la barre. */
            detail={mesure.seuil == null ? (
                <span className={sejourStyles.tiny}>
                    {THEME_RESULTATS_SANS_SEUIL}
                </span>
            ) : (
                <>
                    <strong>{verdict}</strong>{" "}
                    {themeResultatsSeuilDetail(mesure.seuil, mesure.total)}
                </>
            )}
        />
    );
}

/**
 * 🛑 **`<style>` SANS l'attribut `jsx`** — styled-jsx scope ses règles aux
 * éléments rendus par le même composant, et un `Styles()` qui ne rend que la
 * balise n'en applique aucune.
 *
 * 🛑 **Une seule règle reste ici** : l'état vide, exactement comme sur « Vos
 * résultats » d'une épreuve. Tout le reste de l'écran est dans le KIT
 * (`ResultHero`, `LevelChart`, `HistoryRow`, `InfoNote`, `PanelHead`), avec son
 * miroir Flutter.
 *
 * 🛑 **Aucune couleur en dur** : tokens `--color-*` uniquement.
 */
function Styles() {
    return (
        <style>{`
            .th-vide {
                margin: 0 0 4px;
                font-size: 14.5px;
                font-weight: 800;
                color: var(--color-ink);
            }
        `}</style>
    );
}
