"use client";

/**
 * Le résultat du diagnostic **civique** (`20_` §4.5).
 *
 * Ordre imposé par la spec : résultat → vos thèmes → mises en situation → ce
 * qui coûte le plus de points → rassurance → teaser du plan.
 *
 * 🛑 **Le constat est intégralement gratuit.** « Le paywall porte sur
 * l'accompagnement » (`20_` §4.5) : ce DTO ne porte aucun `locked`, et cet
 * écran n'en invente pas.
 *
 * 🛑 **La projection /40 vient du SERVEUR.** Ni écrite en dur, ni recalculée
 * ici : deux calculs de la même chose finissent par afficher deux nombres. Et
 * c'est une projection, jamais un pronostic de réussite.
 *
 * 🛑 **Un thème NON ÉVALUÉ n'est pas faible.** Il se dit « Non évalué », en
 * atténué, et n'entre dans aucune priorité.
 */
import {useCallback, useEffect, useState} from "react";
import {AlertCircle, Check} from "lucide-react";
import {ApiException, civicDiagnosticApi, publicCivicDiagnosticApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {adopterSiInvite, lireInvite} from "@/lib/civic-diagnostic-guest";
import {CivicDiagnosticGate} from "./CivicDiagnosticGate";
import {
    autresPrioritesLine,
    CIVIC_DIAGNOSTIC_PLAN_CTA,
    CIVIC_PLAN_TEASER_TITLE,
    CIVIC_PRIORITES_TITLE,
    CIVIC_PRIORITES_VISIBLES,
    CIVIC_RASSURANCE_TITLE,
    CIVIC_RESULT_BADGE,
    CIVIC_RESULT_KICKER,
    CIVIC_RESULT_SCORE_LABEL,
    CIVIC_RESULT_TITLE,
    CIVIC_SITUATIONS_LABEL,
    CIVIC_SITUATIONS_TEXT,
    CIVIC_SITUATIONS_TITLE,
    CIVIC_THEMES_TITLE,
    kitTone,
    perspectiveLine,
    rassuranceText,
    situationsLine,
    thresholdLine,
} from "@/lib/civic-diagnostic";
import {CIVIC_THEME_STATE_LABEL} from "@/lib/types";
import {
    Card,
    Cta,
    MiniPlan,
    NoteCard,
    Pad,
    Prio,
    Section,
    sejourStyles as s,
    SejourApp,
    Stack,
    ThemeLine,
    Top,
} from "@/app/_components/sejour/SejourKit";
import type {CivicDiagnosticResultDto, TargetProcedure} from "@/lib/types";

type Etat =
    | {kind: "loading"}
    /** Visiteur : le résultat est ce qu'on échange contre le compte (`V053`). */
    | {kind: "compte"; repondues: number; total: number; procedure: TargetProcedure}
    | {kind: "pret"; resultat: CivicDiagnosticResultDto}
    | {kind: "erreur"; message: string};

export function CivicDiagnosticResult({sessionId}: {sessionId: string}) {
    const {status} = useAuth();
    const [etat, setEtat] = useState<Etat>({kind: "loading"});

    const charger = useCallback(async () => {
        try {
            if (status !== "authenticated") {
                // 🛑 **Aucun résultat pour un visiteur.** On ne montre que ce
                // qu'il a déjà : combien de questions il a traitées. Le
                // serveur n'expose d'ailleurs pas de résultat public — cet
                // écran ne pourrait pas mentir même s'il le voulait.
                const invite = lireInvite();
                if (invite?.sessionId === sessionId) {
                    const dto = await publicCivicDiagnosticApi.get(sessionId);
                    setEtat({
                        kind: "compte",
                        repondues: dto.repondues,
                        total: dto.total,
                        procedure: invite.procedure,
                    });
                    return;
                }
                // Session inconnue de cet appareil : le compte tranchera.
                setEtat({
                    kind: "erreur",
                    message: "Connectez-vous pour retrouver ce diagnostic.",
                });
                return;
            }

            // 🛑 **L'adoption d'abord**, et son échec n'arrête rien : un compte
            // qui avait déjà son diagnostic gratuit se voit refuser l'adoption
            // et doit tout de même voir SON résultat.
            await adopterSiInvite();
            // 🛑 `result()` (POST) et non `readResult()` : c'est lui qui
            // CLÔTURE la session. Sans cette clôture, le diagnostic reste
            // « en cours » pour toujours et le Plan continue de réclamer un
            // diagnostic que le candidat vient de terminer — le défaut constaté
            // à l'usage. L'appel est idempotent : une session déjà close est
            // rendue telle quelle.
            setEtat({kind: "pret", resultat: await civicDiagnosticApi.result(sessionId)});
        } catch (e) {
            setEtat({
                kind: "erreur",
                message:
                    e instanceof ApiException
                        ? e.message
                        : "Impossible de charger votre résultat.",
            });
        }
    }, [sessionId, status]);

    useEffect(() => {
        // `loading` = l'auth n'a pas tranché. Décider ici montrerait l'écran de
        // compte à quelqu'un qui en a déjà un, le temps du refresh de jeton.
        if (status === "loading") return;
        void charger();
    }, [charger, status]);

    if (etat.kind === "compte") {
        return (
            <CivicDiagnosticGate
                repondues={etat.repondues}
                total={etat.total}
                procedure={etat.procedure}
            />
        );
    }

    if (etat.kind === "loading") {
        return (
            <SejourApp>
                <Top kicker={CIVIC_RESULT_KICKER} title={CIVIC_RESULT_TITLE} />
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
                <Top kicker={CIVIC_RESULT_KICKER} title={CIVIC_RESULT_TITLE} />
                <Section>
                    <Pad>
                        <NoteCard variant="warn" icon={AlertCircle} title={etat.message} />
                    </Pad>
                </Section>
            </SejourApp>
        );
    }

    const r = etat.resultat;
    const perspective = perspectiveLine(r);
    const situations = situationsLine(r);
    const rassurance = rassuranceText(r);
    const prioritesVisibles = r.priorites.slice(0, CIVIC_PRIORITES_VISIBLES);
    const autres = autresPrioritesLine(r.priorites.length);

    return (
        <SejourApp>
            <Top
                kicker={CIVIC_RESULT_KICKER}
                title={CIVIC_RESULT_TITLE}
                badge={CIVIC_RESULT_BADGE}
            />

            {/* 1 — le résultat. L'élément dominant. */}
            <Pad>
                <Card variant="hero">
                    <p className={s.label}>{CIVIC_RESULT_SCORE_LABEL}</p>
                    <p className={s.score}>
                        {r.bonnes} <small>/ {r.posees}</small>
                    </p>
                    {/* 🛑 Absente si rien n'a été posé : « on n'a rien mesuré »
                        ne se dit pas « vous auriez 0 sur 40 ». */}
                    {perspective && <p className={s.insight}>{perspective}</p>}
                    <p className={s.threshold}>{thresholdLine(r)}</p>
                </Card>
            </Pad>

            {/* 2 — les 5 thèmes, TOUS, y compris les non évalués. */}
            <Section title={CIVIC_THEMES_TITLE}>
                <Pad>
                    <Card padding="tight">
                        {r.themes.map((t) => (
                            <ThemeLine
                                key={t.code}
                                tone={kitTone(t.etat)}
                                name={t.label}
                                status={CIVIC_THEME_STATE_LABEL[t.etat]}
                            />
                        ))}
                    </Card>
                </Pad>
            </Section>

            {/* 3 — les mises en situation, bloc distinct : c'est une compétence
                différente, et c'est souvent ce qui fait la différence.
                🛑 Masqué quand aucune n'a été posée (mode dégradé) : un bloc à
                « 0 sur 0 » ne dit rien et se lit comme un échec. */}
            {situations && (
                <Section title={CIVIC_SITUATIONS_TITLE} flush>
                    <Card>
                        <p className={s.label}>{CIVIC_SITUATIONS_LABEL}</p>
                        <p className={s.sitScore}>{situations}</p>
                        <p className={s.tiny}>{CIVIC_SITUATIONS_TEXT}</p>
                    </Card>
                </Section>
            )}

            {/* 4 — ce qui coûte le plus de points. Titre volontairement concret.
                Le rang, le thème et l'état sont SERVIS ; aucune phrase
                explicative n'existe côté serveur, on n'en invente pas. */}
            {prioritesVisibles.length > 0 && (
                <Section title={CIVIC_PRIORITES_TITLE}>
                    <Pad>
                        <Stack>
                            {prioritesVisibles.map((p, i) => (
                                <Prio
                                    key={p.code}
                                    rank={(i + 1) as 1 | 2 | 3}
                                    tag={CIVIC_THEME_STATE_LABEL[p.etat]}
                                    title={p.label}
                                />
                            ))}
                        </Stack>
                    </Pad>
                </Section>
            )}

            {/* 5 — rassurance. 🛑 Absente si aucun thème n'est solide : « 0 thème
                est déjà solide » sonnerait faux au pire moment. */}
            {rassurance && (
                <Section>
                    <Pad>
                        <NoteCard
                            variant="ok"
                            icon={Check}
                            iconTone="ok"
                            title={CIVIC_RASSURANCE_TITLE}
                        >
                            <p className={s.tiny}>{rassurance}</p>
                        </NoteCard>
                    </Pad>
                </Section>
            )}

            {/* 6 — le teaser du plan. */}
            <Section title={CIVIC_PLAN_TEASER_TITLE}>
                <Pad>
                    <Stack>
                        {prioritesVisibles.length > 0 && (
                            <Card>
                                <MiniPlan
                                    rows={prioritesVisibles.map((p) => ({
                                        label: p.label,
                                        pill: CIVIC_THEME_STATE_LABEL[p.etat],
                                        tone: kitTone(p.etat),
                                    }))}
                                />
                                {autres && <p className={s.tiny}>{autres}</p>}
                            </Card>
                        )}
                        <Cta href="/plan?module=CIVIQUE" variant="blue">
                            {CIVIC_DIAGNOSTIC_PLAN_CTA}
                        </Cta>
                    </Stack>
                </Pad>
            </Section>
        </SejourApp>
    );
}
