"use client";

/**
 * L'accueil du diagnostic **civique** (`20_` §4) — l'écran d'intro.
 *
 * 🛑 **Ce n'est PAS un examen blanc**, et l'écran le dit avant de commencer :
 * il sert à repérer quoi travailler, pas à vérifier si on est prêt. Sans cette
 * phrase, le candidat lit son résultat comme un pronostic de réussite.
 *
 * 🛑 **Aucun écran de passation n'est créé** : le diagnostic ouvre le runner de
 * session existant. Un second runner divergerait du premier à la première
 * évolution.
 *
 * 🛑 **Un seul diagnostic civique**, pas de rapide + complet : le civique est du
 * QCM déterministe et rapide, un pré-diagnostic n'apporterait rien et
 * dupliquerait le tunnel du TCF (arbitrage du propriétaire, 2026-09-10).
 *
 * 🛑 **On peut le passer AVANT de créer son compte** (`V053`, arbitrage du
 * propriétaire du 2026-09-10). Le visiteur déclare sa démarche — c'est elle qui
 * choisit les questions —, répond à ses 40 questions, et le compte n'est
 * demandé qu'au résultat. Dès qu'il s'authentifie, la session invitée est
 * **adoptée** : mêmes questions, mêmes réponses, rien n'est rejoué.
 */
import {useCallback, useEffect, useState} from "react";
import {useRouter} from "next/navigation";
import {AlertCircle} from "lucide-react";
import {
    ApiException,
    civicDiagnosticApi,
    publicCivicDiagnosticApi,
    publicThemeApi,
    userContentApi,
} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {
    adopterSiInvite,
    ecrireInvite,
    etatInvite,
} from "@/lib/civic-diagnostic-guest";
import {
    CIVIC_DIAGNOSTIC_EN_COURS_LABEL,
    CIVIC_DIAGNOSTIC_GUEST_BADGE,
    CIVIC_DIAGNOSTIC_GUEST_NOTE,
    CIVIC_DIAGNOSTIC_GUEST_TITLE,
    CIVIC_DIAGNOSTIC_NOT_EXAM,
    CIVIC_DIAGNOSTIC_PARAM,
    CIVIC_DIAGNOSTIC_RESULT_CTA,
    CIVIC_DIAGNOSTIC_RESUME_CTA,
    CIVIC_DIAGNOSTIC_START_CTA,
    CIVIC_EXAM_QUESTIONS,
    CIVIC_EXAM_SEUIL_REUSSITE,
    CIVIC_INTRO_FREE_CAPTION,
    CIVIC_INTRO_KICKER,
    CIVIC_INTRO_LEAD,
    CIVIC_INTRO_SITUATIONS_NOTE,
    CIVIC_INTRO_STAT_QUESTIONS,
    CIVIC_INTRO_STAT_SEUIL,
    CIVIC_INTRO_STAT_THEMES,
    CIVIC_INTRO_THEMES_TITLE,
    CIVIC_INTRO_TITLE,
    CIVIC_THEMES_COUNT,
    civicDiagnosticResultHref,
    MENTION_LABEL,
    progressionLabel,
} from "@/lib/civic-diagnostic";
import {
    Card,
    ChoiceCard,
    Cta,
    NoteCard,
    Pad,
    Section,
    sejourStyles as s,
    SejourApp,
    Stack,
    Top,
} from "@/app/_components/sejour/SejourKit";
import type {CivicDiagnosticDto, TargetProcedure} from "@/lib/types";

/** Le runner, avec le marqueur de retour vers le diagnostic. */
function runnerHref(attemptId: string, sessionId: string): string {
    return `/sessions/${attemptId}?${CIVIC_DIAGNOSTIC_PARAM}=${sessionId}`;
}

const MENTIONS: TargetProcedure[] = ["CSP", "CR", "NAT"];

type Etat =
    | {kind: "loading"}
    /** Aucun diagnostic ouvert : le candidat choisit sa démarche. */
    | {kind: "intro"}
    | {kind: "pret"; diagnostic: CivicDiagnosticDto; invite: boolean}
    | {kind: "erreur"; message: string};

export function CivicDiagnosticHub() {
    const router = useRouter();
    const {status, user, refreshUser} = useAuth();
    const [etat, setEtat] = useState<Etat>({kind: "loading"});
    const [action, setAction] = useState(false);
    const [procedure, setProcedure] = useState<TargetProcedure | null>(null);
    /** Les 5 thèmes du livret : **libellés éditoriaux servis**, jamais recopiés. */
    const [themes, setThemes] = useState<string[]>([]);

    const charger = useCallback(async () => {
        try {
            if (status === "authenticated") {
                // 🛑 **L'adoption d'abord.** Le visiteur qui vient de créer son
                // compte doit retrouver SON diagnostic, pas s'en voir proposer
                // un neuf : lire l'état avant d'adopter afficherait « aucun
                // diagnostic » une fraction de seconde puis changerait d'avis.
                const adopte = await adopterSiInvite();
                if (adopte) {
                    setEtat({kind: "pret", diagnostic: adopte, invite: false});
                    return;
                }
                const courant = await civicDiagnosticApi.current();
                setEtat(courant ? {kind: "pret", diagnostic: courant, invite: false} : {kind: "intro"});
                return;
            }
            const invite = await etatInvite();
            setEtat(invite ? {kind: "pret", diagnostic: invite, invite: true} : {kind: "intro"});
        } catch (e) {
            setEtat({
                kind: "erreur",
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible de charger votre diagnostic.",
            });
        }
    }, [status]);

    useEffect(() => {
        // `loading` = l'auth n'a pas encore tranché. Décider ici enverrait un
        // utilisateur connecté dans le tunnel invité le temps du refresh.
        if (status === "loading") return;
        void charger();
    }, [charger, status]);

    // La démarche déjà déclarée présélectionne le choix : la redemander à vide
    // à quelqu'un qui l'a donnée au parcours serait une question de plus.
    useEffect(() => {
        if (user?.targetProcedure) setProcedure(user.targetProcedure);
    }, [user?.targetProcedure]);

    useEffect(() => {
        if (etat.kind !== "intro") return;
        // Lecture publique pour tout le monde : un 401 sur un catalogue ne se
        // montre jamais au visiteur. Un échec laisse simplement la carte de
        // côté — on ne déclare pas le livret vide sur une panne réseau.
        publicThemeApi
            .list("CIVIQUE")
            .then((liste) =>
                setThemes(
                    [...liste]
                        .sort((a, b) => a.displayOrder - b.displayOrder)
                        .map((t) => t.name),
                ),
            )
            .catch(() => setThemes([]));
    }, [etat.kind]);

    /** Ouvrir est idempotent côté compte : un double appui ne retire pas. */
    const ouvrir = useCallback(async () => {
        if (action || !procedure) return;
        setAction(true);
        try {
            let ouvert: CivicDiagnosticDto;
            if (status === "authenticated") {
                // 🛑 Côté compte, le serveur tire sur `users.target_procedure` :
                // changer de démarche ici doit donc la **déclarer** avant le
                // tirage, sinon l'écran promet un programme et le serveur en
                // sert un autre.
                if (procedure !== user?.targetProcedure) {
                    await userContentApi.updateTargetPath(procedure);
                    await refreshUser();
                }
                ouvert = await civicDiagnosticApi.open();
            } else {
                ouvert = await publicCivicDiagnosticApi.open(procedure);
                // L'adresse de la session, pour la reprise après rechargement
                // et pour l'adoption au moment du compte.
                ecrireInvite(ouvert, procedure);
            }
            // 🛑 Le marqueur voyage avec l'attempt : c'est LUI qui ramène au
            // diagnostic à la fin. Sans lui, le candidat termine ses questions
            // et atterrit sur le bilan de série générique.
            router.push(runnerHref(ouvert.attemptId, ouvert.sessionId));
        } catch (e) {
            setEtat({
                kind: "erreur",
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible d'ouvrir votre diagnostic.",
            });
            setAction(false);
        }
    }, [action, procedure, refreshUser, router, status, user?.targetProcedure]);

    /**
     * Voir le résultat.
     *
     * 🛑 **Un visiteur n'obtient aucun résultat ici** : il est envoyé sur
     * l'écran de résultat, qui lui demande son compte. Le résultat est
     * exactement ce qu'on échange contre l'inscription.
     */
    const voirResultat = useCallback(
        async (sessionId: string, invite: boolean) => {
            if (action) return;
            if (invite) {
                router.push(civicDiagnosticResultHref(sessionId));
                return;
            }
            setAction(true);
            try {
                await civicDiagnosticApi.result(sessionId);
                router.push(civicDiagnosticResultHref(sessionId));
            } catch (e) {
                setEtat({
                    kind: "erreur",
                    message:
                        e instanceof ApiException
                            ? e.message
                            : "Impossible de calculer votre résultat.",
                });
                setAction(false);
            }
        },
        [action, router],
    );

    if (etat.kind === "loading") {
        return (
            <SejourApp>
                <Top kicker={CIVIC_INTRO_KICKER} title={CIVIC_INTRO_TITLE} />
                <Pad>
                    <p className={s.sub} aria-busy="true">
                        Chargement…
                    </p>
                </Pad>
            </SejourApp>
        );
    }

    if (etat.kind === "erreur") {
        return (
            <SejourApp>
                <Top kicker={CIVIC_INTRO_KICKER} title={CIVIC_INTRO_TITLE} />
                <Section>
                    <Pad>
                        <Stack>
                            <NoteCard variant="warn" icon={AlertCircle} title={etat.message} />
                            <Cta variant="line" onClick={() => void charger()}>
                                Réessayer
                            </Cta>
                        </Stack>
                    </Pad>
                </Section>
            </SejourApp>
        );
    }

    if (etat.kind === "pret") {
        const d = etat.diagnostic;
        const termine = d.status === "COMPLETED";
        return (
            <SejourApp>
                <Top
                    kicker={CIVIC_INTRO_KICKER}
                    title={CIVIC_INTRO_TITLE}
                    badge={etat.invite ? CIVIC_DIAGNOSTIC_GUEST_BADGE : undefined}
                />
                <Section>
                    <Pad>
                        <Stack>
                            <Card>
                                <p className={s.label}>{CIVIC_DIAGNOSTIC_EN_COURS_LABEL}</p>
                                <p className={s.sitScore}>
                                    {progressionLabel(d.repondues, d.total)}
                                </p>
                                {!termine && (
                                    <p className={s.tiny}>{CIVIC_DIAGNOSTIC_NOT_EXAM}</p>
                                )}
                            </Card>
                            {termine ? (
                                <Cta
                                    variant="blue"
                                    disabled={action}
                                    onClick={() => void voirResultat(d.sessionId, etat.invite)}
                                >
                                    {CIVIC_DIAGNOSTIC_RESULT_CTA}
                                </Cta>
                            ) : (
                                <>
                                    <Cta
                                        variant="blue"
                                        disabled={action}
                                        onClick={() =>
                                            router.push(runnerHref(d.attemptId, d.sessionId))
                                        }
                                    >
                                        {d.repondues > 0
                                            ? CIVIC_DIAGNOSTIC_RESUME_CTA
                                            : CIVIC_DIAGNOSTIC_START_CTA}
                                    </Cta>
                                    {/* Le résultat reste demandable même sans avoir tout
                                        répondu : une question sautée sort du dénominateur,
                                        elle ne devient jamais une mauvaise réponse. */}
                                    {d.repondues > 0 && (
                                        <Cta
                                            variant="line"
                                            disabled={action}
                                            onClick={() =>
                                                void voirResultat(d.sessionId, etat.invite)
                                            }
                                        >
                                            {CIVIC_DIAGNOSTIC_RESULT_CTA}
                                        </Cta>
                                    )}
                                </>
                            )}
                        </Stack>
                    </Pad>
                    {etat.invite && (
                        <p className={s.footNote}>{CIVIC_DIAGNOSTIC_GUEST_NOTE}</p>
                    )}
                </Section>
            </SejourApp>
        );
    }

    return (
        <SejourApp>
            <Top kicker={CIVIC_INTRO_KICKER} title={CIVIC_INTRO_TITLE} />

            <Pad>
                <p className={s.sub}>{CIVIC_INTRO_LEAD}</p>
            </Pad>

            {/* 🛑 Le format de l'épreuve, pas celui de la maquette : 40 questions
                et un seuil de 32, miroir de `CivicExamFormat`. Aucune durée n'est
                annoncée — le diagnostic n'a pas de chrono et le serveur n'en sert
                aucune : l'inventer serait promettre un temps qui n'existe pas. */}
            <Section>
                <Pad>
                    <Card>
                        <div className={s.statGrid}>
                            <div>
                                <b>{CIVIC_EXAM_QUESTIONS}</b>
                                <span>{CIVIC_INTRO_STAT_QUESTIONS}</span>
                            </div>
                            <div>
                                <b>{CIVIC_THEMES_COUNT}</b>
                                <span>{CIVIC_INTRO_STAT_THEMES}</span>
                            </div>
                            <div>
                                <b>
                                    {CIVIC_EXAM_SEUIL_REUSSITE} / {CIVIC_EXAM_QUESTIONS}
                                </b>
                                <span>{CIVIC_INTRO_STAT_SEUIL}</span>
                            </div>
                        </div>
                    </Card>
                </Pad>
            </Section>

            {themes.length > 0 && (
                <Section>
                    <Pad>
                        <Card>
                            <p className={s.label}>{CIVIC_INTRO_THEMES_TITLE}</p>
                            <ul className={s.themeList}>
                                {themes.map((nom) => (
                                    <li key={nom}>{nom}</li>
                                ))}
                            </ul>
                            <p className={s.tiny}>{CIVIC_INTRO_SITUATIONS_NOTE}</p>
                        </Card>
                    </Pad>
                </Section>
            )}

            {/* 🛑 La démarche n'est pas un confort : elle choisit les questions.
                Un candidat naturalisation mesuré sur le programme d'une carte de
                séjour repart avec un diagnostic flatteur et un plan incomplet. */}
            <Section title={CIVIC_DIAGNOSTIC_GUEST_TITLE}>
                <Pad>
                    <Stack>
                        {MENTIONS.map((m) => (
                            <ChoiceCard
                                key={m}
                                label={MENTION_LABEL[m]}
                                selected={procedure === m}
                                onSelect={() => setProcedure(m)}
                            />
                        ))}
                    </Stack>
                </Pad>
            </Section>

            <Section>
                <Pad>
                    <Cta
                        variant="blue"
                        disabled={action || !procedure}
                        onClick={() => void ouvrir()}
                        caption={CIVIC_INTRO_FREE_CAPTION}
                    >
                        {CIVIC_DIAGNOSTIC_START_CTA}
                    </Cta>
                </Pad>
                <p className={s.footNote}>{CIVIC_DIAGNOSTIC_NOT_EXAM}</p>
                {status !== "authenticated" && (
                    <p className={s.footNote}>{CIVIC_DIAGNOSTIC_GUEST_NOTE}</p>
                )}
            </Section>
        </SejourApp>
    );
}
