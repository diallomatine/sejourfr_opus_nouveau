"use client";

import {useParams, useRouter} from "next/navigation";
import {useEffect, useState} from "react";
import {ApiException, attemptApi} from "@/lib/api";
import {useAuth} from "@/lib/auth-context";
import {type AttemptSummaryResponse, canAccessModule, type QuestionType} from "@/lib/types";
import {DualChromeShell} from "@/app/_components/DualChromeShell";
import {PaywallSheet} from "@/app/_components/PaywallSheet";
import {ModuleDetailGate, moduleDetailStyles as ds} from "@/app/_components/module_detail/parts";
import {HubDetailHeader} from "@/app/_components/hub/HubParts";
import {ExamSlotsView} from "@/app/_components/hub/ExamSlotsView";
import hub from "@/app/_components/hub/hub.module.css";

const SLOTS = 10;

const TCF_QCM = {
    co: {questionType: "CO" as QuestionType, title: "Compréhension orale", duration: "20 min"},
    ce: {questionType: "CE" as QuestionType, title: "Compréhension écrite", duration: "35 min"},
    structure: {
        questionType: "STRUCTURE" as QuestionType,
        title: "Structure de la langue",
        duration: "20 min",
    },
} as const;
type TcfCode = keyof typeof TCF_QCM;

/**
 * Examens blancs d'une épreuve TCF QCM (25 Q A2→B1→B2, score /50) — grille de
 * 10 slots, miroir de `TcfQcmExamsScreen` mobile. Connecté uniquement.
 */
export default function TcfModuleExamsPage() {
    const params = useParams<{ code: string }>();
    const code = (params?.code ?? "").toLowerCase() as TcfCode;
    const config = TCF_QCM[code];
    const router = useRouter();
    const {user, status} = useAuth();
    const isPremium = user ? canAccessModule(user, "TCF") : false;

    const [exams, setExams] = useState<AttemptSummaryResponse[]>([]);
    const [starting, setStarting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [paywallOpen, setPaywallOpen] = useState(false);

    const questionType = config?.questionType;

    useEffect(() => {
        if (status !== "authenticated" || !questionType) return;
        let cancelled = false;
        attemptApi
            .listMine({type: "MOCK_EXAM", module: "TCF", moduleExamQuestionType: questionType, limit: 30})
            .then((list) => {
                if (cancelled) return;
                setExams(
                    list
                        .filter((a) => a.finishedAt)
                        .sort((a, b) => b.startedAt.localeCompare(a.startedAt)),
                );
            })
            .catch(() => undefined);
        return () => {
            cancelled = true;
        };
    }, [status, questionType]);

    async function start() {
        if (starting || !questionType) return;
        setError(null);
        setStarting(true);
        try {
            const a = await attemptApi.start({
                type: "MOCK_EXAM",
                module: "TCF",
                moduleExamQuestionType: questionType,
            });
            router.push(`/sessions/${a.id}`);
        } catch (e) {
            setError(e instanceof ApiException ? e.message : "Impossible de démarrer l'examen.");
            setStarting(false);
        }
    }

    if (status === "loading") return <div className={ds.gate}/>;
    if (!user) return <ModuleDetailGate next={`/entrainement/tcf/${code}/examens`}/>;
    if (!config) return <div className={hub.loading}>Épreuve inconnue.</div>;

    return (
        <DualChromeShell>
            <main className={hub.hub}>
                <HubDetailHeader
                    backHref={`/entrainement/tcf/${code}`}
                    title="Examens blancs"
                    subtitle={`${config.title} · 25 questions · ${config.duration} · score /50`}
                />
                {error && <div className={hub.error}>{error}</div>}
                <ExamSlotsView
                    count={SLOTS}
                    exams={exams}
                    premium={isPremium}
                    starting={starting}
                    accent="red"
                    onStart={start}
                    onLocked={() => setPaywallOpen(true)}
                />
                <PaywallSheet open={paywallOpen} onClose={() => setPaywallOpen(false)} module="INTEGRAL"/>
            </main>
        </DualChromeShell>
    );
}
