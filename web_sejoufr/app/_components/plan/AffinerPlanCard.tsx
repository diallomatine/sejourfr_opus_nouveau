/**
 * **Affiner votre Plan** — l'invitation au diagnostic complet, en action
 * **secondaire**.
 *
 * 🛑 **Le diagnostic complet ne bloque jamais le Plan** (arbitrage du
 * propriétaire, 2026-09-12). Il l'affine. Cette carte se pose donc **après** le
 * contenu principal, et ne concurrence jamais le CTA d'abonnement d'un compte
 * gratuit : bouton `line` (contour), jamais `primary`.
 *
 * 🛑 **Un seul composant, trois lecteurs** — Plan gratuit, Plan abonné,
 * Accueil. Ses phrases vivent dans une **autorité unique**, `affinerPlan()`
 * (`lib/preparation.ts`), miroir de
 * `mobile_sejourfr/lib/core/models/preparation_labels.dart`. Trois copies
 * auraient fini par inviter à trois choses différentes.
 *
 * 🛑 **Rien n'est compté ici.** `fait`, `total` et la prochaine épreuve sont
 * **servis** ; à `4 / 4` l'autorité rend `null` et la carte n'existe pas.
 *
 * Deux surfaces, deux rendus — parce que l'Accueil **n'est pas** un des sept
 * écrans du KIT et n'a pas le scope `.app` dont les primitives tirent leurs
 * rayons et leurs ombres. Les mots, eux, restent les mêmes.
 */
"use client";

import {Card, Cta, Pad, ProgressMini, Section, Stack, sejourStyles} from "../sejour/SejourKit";
import type {AffinerPlan} from "../../../lib/preparation";

export function AffinerPlanCard({
    info,
    surface,
}: {
    info: AffinerPlan;
    surface: "plan" | "accueil";
}) {
    // Le ratio est **servi**, jamais un pourcentage reconstruit : il vaut
    // exactement « épreuves terminées sur épreuves du diagnostic ».
    const ratio = info.total > 0 ? info.fait / info.total : 0;

    if (surface === "accueil") {
        return (
            <section className="affiner-home" aria-labelledby="affiner-home-title">
                <h2 id="affiner-home-title">{info.titre}</h2>
                {info.progression ? <p className="affiner-home-count">{info.progression}</p> : null}
                {info.enCours ? (
                    <div
                        className="affiner-home-bar"
                        role="progressbar"
                        aria-valuemin={0}
                        aria-valuemax={info.total}
                        aria-valuenow={info.fait}
                        aria-label={info.progression ?? info.titre}
                    >
                        <span style={{width: `${Math.round(ratio * 100)}%`}} />
                    </div>
                ) : null}
                <p className="affiner-home-text">{info.texte}</p>
                {info.prochaineEpreuve ? (
                    <p className="affiner-home-next">{info.prochaineEpreuve}</p>
                ) : null}
                <a className="affiner-home-cta" href={info.href}>
                    {info.cta}
                </a>
                <style jsx>{`
                    .affiner-home {
                        margin-top: 18px;
                        padding: 16px;
                        border-radius: 16px;
                        background: var(--color-blue-soft);
                        box-shadow: 0 0 0 1px rgba(30, 58, 140, 0.08);
                    }
                    .affiner-home h2 {
                        margin: 0;
                        font-family: var(--font-display);
                        font-size: 17px;
                        font-weight: 700;
                        color: var(--color-ink);
                    }
                    .affiner-home-count {
                        margin: 6px 0 0;
                        font-family: var(--font-mono);
                        font-size: 12px;
                        letter-spacing: 0.02em;
                        color: var(--color-blue);
                    }
                    .affiner-home-bar {
                        margin-top: 10px;
                        height: 6px;
                        border-radius: 99px;
                        background: var(--color-line);
                        overflow: hidden;
                    }
                    .affiner-home-bar span {
                        display: block;
                        height: 100%;
                        border-radius: 99px;
                        background: var(--color-blue);
                    }
                    .affiner-home-text {
                        margin: 10px 0 0;
                        font-size: 14px;
                        line-height: 1.5;
                        color: var(--color-ink-2);
                    }
                    .affiner-home-next {
                        margin: 6px 0 0;
                        font-size: 13px;
                        color: var(--color-muted);
                    }
                    .affiner-home-cta {
                        display: inline-flex;
                        align-items: center;
                        margin-top: 12px;
                        min-height: 40px;
                        padding: 0 16px;
                        border-radius: 12px;
                        background: #fff;
                        box-shadow: 0 0 0 1px rgba(30, 58, 140, 0.14);
                        color: var(--color-blue);
                        font-size: 14px;
                        font-weight: 700;
                        text-decoration: none;
                    }
                    .affiner-home-cta:hover {
                        background: var(--color-blue-light);
                    }
                    @media (max-width: 420px) {
                        .affiner-home-cta {
                            width: 100%;
                            justify-content: center;
                        }
                    }
                `}</style>
            </section>
        );
    }

    return (
        <Section>
            <Pad>
                <Card variant="soft">
                    <Stack>
                        <p className={sejourStyles.noteTitle}>{info.titre}</p>
                        {info.progression ? (
                            <p className={sejourStyles.label}>{info.progression}</p>
                        ) : null}
                        {info.enCours ? (
                            <ProgressMini ratio={ratio} label={info.progression ?? undefined} />
                        ) : null}
                        <p className={sejourStyles.sub}>{info.texte}</p>
                        {info.prochaineEpreuve ? (
                            <p className={sejourStyles.tiny}>{info.prochaineEpreuve}</p>
                        ) : null}
                        {/* 🛑 `line`, jamais `primary` : sur un Plan gratuit, le
                            seul bouton plein de la page reste « Débloquer mon Plan ». */}
                        <Cta href={info.href} variant="line">
                            {info.cta}
                        </Cta>
                    </Stack>
                </Card>
            </Pad>
        </Section>
    );
}
