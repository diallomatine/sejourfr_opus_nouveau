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
 * **Un seul rendu depuis 2026-09-12.** Elle en avait deux — le second existait
 * uniquement parce que l'Accueil n'était pas dans le scope `.app` du KIT et
 * n'avait donc ni ses rayons ni ses ombres. L'Accueil est passé sur le KIT :
 * la copie a disparu avec sa raison d'être.
 */
"use client";

import {Card, Cta, Pad, ProgressMini, Section, Stack, sejourStyles} from "../sejour/SejourKit";
import type {AffinerPlan} from "../../../lib/preparation";

export function AffinerPlanCard({info}: {info: AffinerPlan}) {
    // Le ratio est **servi**, jamais un pourcentage reconstruit : il vaut
    // exactement « épreuves terminées sur épreuves du diagnostic ».
    const ratio = info.total > 0 ? info.fait / info.total : 0;

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
