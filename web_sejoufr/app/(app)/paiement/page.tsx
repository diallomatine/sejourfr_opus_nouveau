"use client";

import Link from "next/link";
import {usePathname, useRouter, useSearchParams} from "next/navigation";
import {Suspense, useEffect, useRef, useState} from "react";
import {ArrowLeft} from "lucide-react";
import {retourDe, retourOuRepli} from "@/lib/retour";
import {purchaseOriginDe} from "@/lib/purchase-origin";
import {ApiException, billingApi, type PlanPeriodicity} from "@/lib/api";
import {track} from "@/lib/analytics";
import {useAppBarBack} from "@/app/_components/AppBarTitle";
import {useAuth} from "@/lib/auth-context";
import {trackPaywallViewed, trackSubscribeClicked} from "@/lib/funnel-events";
import type {PlanPublicResponse} from "@/lib/types";
import {isOneTimeCatalog, PASS_MODULES_IN_ORDER} from "@/lib/passes";
import {PassOffers} from "@/app/_components/paiement/PassOffers";
import {
    CanceledBanner,
    CurrentAccessCard,
    PaiementHeader,
    periodicityFromParam,
    SubscriptionOffers,
} from "@/app/_components/paiement/PaiementParts";
import {deriveCurrentPlan} from "@/app/_components/paiement/paiement-access";
import s from "@/app/_components/paiement/paiement.module.css";

/**
 * `/paiement` — le choix d'un pass. En-tête sobre, réassurance une fois, puis
 * une carte par module (`PASS_MODULES_IN_ORDER` : l'Intégral d'abord), chacune
 * sur la carte de prix partagée (`components/pricing/PassCard`). Prix, durées,
 * simulations et « populaire » viennent des passes actifs servis
 * (`billingApi.listPlans`) ; les puces de `PASS_FEATURES` (`lib/passes.ts`).
 *
 * Paramètres : `?plan=` (pass pré-sélectionné et mis à l'écran), `?canceled=1`
 * (retour Stripe sans achat), `?period=` (mode abonnement dormant), `?retour=` /
 * `?cta=` / `?journey=` (relayés jusqu'à Stripe). `?module=` ne réordonne rien :
 * les deux modules sont TOUJOURS affichés (demande du propriétaire, 2026-09-20).
 */
export default function PaiementPage() {
    return (
        <Suspense fallback={<PayingSkeleton/>}>
            <PaiementInner/>
        </Suspense>
    );
}

function PaiementInner() {
    const {user, status} = useAuth();
    const router = useRouter();
    // Écran d'arrivée (Plan, paywall, Profil) : la barre porte le menu, pas
    // une flèche ; le « Retour » de la page reste pour revenir en arrière.
    const backInBar = useAppBarBack(null);
    const pathname = usePathname();
    const searchParams = useSearchParams();
    const currentPlan = deriveCurrentPlan(user);

    const targetPlanCode = searchParams.get("plan");

    // Cible de retour après auth : l'URL complète, pour retomber sur le même pass.
    const currentUrl = `${pathname}${searchParams.toString() ? `?${searchParams}` : ""}`;

    const canceledParam = searchParams.get("canceled");
    const [showCanceled, setShowCanceled] = useState<boolean>(
        canceledParam === "1" || canceledParam === "true",
    );

    const [plans, setPlans] = useState<PlanPublicResponse[]>([]);
    const [plansLoaded, setPlansLoaded] = useState(false);
    const [plansError, setPlansError] = useState<string | null>(null);
    const [periodicity, setPeriodicity] = useState<PlanPeriodicity>(
        periodicityFromParam(searchParams.get("period")) ?? "quarterly",
    );
    const [loadingCode, setLoadingCode] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const errorRef = useRef<HTMLDivElement | null>(null);

    // Deux mesures volontairement séparées : `trackPaywallViewed` est une étape
    // de funnel rattachée au COMPTE, `PRICING_VIEWED` une vue d'audience (la
    // seule qui compte les visiteurs qui regardent les prix sans compte).
    useEffect(() => {
        track("PRICING_VIEWED", {}, {once: true});
        trackPaywallViewed();
    }, []);

    useEffect(() => {
        let cancelled = false;
        billingApi
            .listPlans()
            .then((list) => {
                if (!cancelled) setPlans(list);
            })
            .catch(() => {
                if (!cancelled) setPlansError("Tarifs indisponibles pour le moment. Réessayez dans un instant.");
            })
            .finally(() => {
                if (!cancelled) setPlansLoaded(true);
            });
        return () => {
            cancelled = true;
        };
    }, []);

    // Une erreur de paiement naît au pied d'une carte : on l'amène à l'écran.
    useEffect(() => {
        if (error) errorRef.current?.scrollIntoView({block: "center", behavior: "smooth"});
    }, [error]);

    function dismissCanceled() {
        setShowCanceled(false);
        router.replace(pathname);
    }

    const oneTime = isOneTimeCatalog(plans);

    /* Le chemin d'où le candidat est parti acheter, relayé tel quel jusqu'à
       Stripe (`null` = cas nominal). Le CTA d'origine et le parcours affiché
       (Q12) voyagent de même ; rien d'arrivé ⇒ cet écran de prix est l'origine. */
    const retour = retourDe(searchParams);
    const origin = purchaseOriginDe(searchParams, "PRICING");

    async function handleSubscribe(planCode: string) {
        // Ce clic engage réellement l'achat (ouverture de la Checkout Stripe) :
        // « la page des prix a déclenché l'achat » et « c'est ce pass-là ».
        track("PREMIUM_CTA_CLICKED", {ctaLocation: "PRICING", planCode, screen: "paiement"});
        track("PRICING_CTA_CLICKED", {planCode});
        trackSubscribeClicked();
        setError(null);
        setLoadingCode(planCode);
        try {
            const {url} = await billingApi.getPaymentLink(planCode, retour, origin);
            window.location.assign(url);
        } catch (err) {
            if (err instanceof ApiException) {
                if (err.status === 503) {
                    setError("Le paiement n'est pas encore activé côté serveur (clés Stripe à configurer). Réessayez plus tard.");
                } else if (err.status === 404) {
                    setError("Ce plan n'est plus disponible. Rechargez la page pour voir les tarifs à jour.");
                } else if (err.status === 401) {
                    setError("Connexion expirée. Reconnectez-vous puis recommencez.");
                } else {
                    setError(err.message);
                }
            } else {
                setError("Impossible d'initier le paiement. Réessayez dans un instant.");
            }
            setLoadingCode(null);
        }
    }

    if (status === "loading" || !plansLoaded) return <PayingSkeleton/>;

    if (!user) {
        return (
            <main className={s.gate}>
                <p>Connectez-vous pour obtenir ou gérer votre accès.</p>
                <Link href={`/connexion?next=${encodeURIComponent(currentUrl)}`} className={s.gateCta}>
                    Se connecter
                </Link>
                <Link href={`/inscription?next=${encodeURIComponent(currentUrl)}`} className={s.gateAlt}>
                    Créer un compte
                </Link>
            </main>
        );
    }

    if (plansError) {
        return (
            <main className={s.gate}>
                <p>{plansError}</p>
                <button type="button" onClick={() => window.location.reload()} className={s.gateCta}>
                    Réessayer
                </button>
            </main>
        );
    }

    return (
        <main className={s.page}>
            <div className={s.inner}>
                <button
                    type="button"
                    className={`${s.back}${backInBar ? " in-bar-back" : ""}`}
                    onClick={() => retourOuRepli(router, "/dashboard")}
                >
                    <ArrowLeft size={15} aria-hidden/> Retour
                </button>

                <PaiementHeader currentPlan={currentPlan} firstName={user.firstName ?? null} oneTime={oneTime}/>

                {showCanceled && <CanceledBanner onDismiss={dismissCanceled}/>}

                {currentPlan !== "FREE" && <CurrentAccessCard user={user} currentPlan={currentPlan}/>}

                {oneTime ? (
                    <PassOffers
                        plans={plans}
                        modules={PASS_MODULES_IN_ORDER}
                        currentPlan={currentPlan}
                        loadingCode={loadingCode}
                        targetPlanCode={targetPlanCode}
                        onSubscribe={handleSubscribe}
                    />
                ) : (
                    <SubscriptionOffers
                        plans={plans}
                        modules={PASS_MODULES_IN_ORDER}
                        currentPlan={currentPlan}
                        periodicity={periodicity}
                        onPeriodicity={setPeriodicity}
                        loadingCode={loadingCode}
                        onSubscribe={handleSubscribe}
                    />
                )}

                {error && (
                    <div ref={errorRef} className={`form-error ${s.error}`} role="alert">
                        {error}
                    </div>
                )}

                <p className={s.foot}>
                    Une question avant de payer ?{" "}
                    <a href="mailto:support@sejourfr.fr">support@sejourfr.fr</a>
                </p>
            </div>
        </main>
    );
}

function PayingSkeleton() {
    return (
        <main className={s.page} aria-busy="true">
            <div className={s.inner}>
                <div className={`${s.skel} ${s.skelHead}`}/>
                <div className={s.cards}>
                    <div className={`${s.skel} ${s.skelCard}`}/>
                    <div className={`${s.skel} ${s.skelCard}`}/>
                </div>
            </div>
        </main>
    );
}
