package com.sejourfr.app.service.journey;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.manager.JourneyManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * <b>Le PREMIER plan est offert, les suivants sont reserves aux abonnes</b>
 * (decision du proprietaire, 2026-10-05, A178).
 *
 * <blockquote>« C'est seulement le PREMIER plan (le cycle d'examens) où on peut
 * faire les examens normalement s'ils sont dans le plan, si on n'est pas
 * abonné. Seuls les abonnés peuvent travailler via le plan après le premier
 * plan. Le premier plan = le diagnostic offert ; pour les autres on
 * s'abonne. »</blockquote>
 *
 * <p>🛑 <b>Seule autorite</b> de « ce cycle est-il le plan offert ? », lue par le
 * verrou servi des etapes ({@code JourneyReadService.raisonDuVerrou}). Le
 * travail ({@code TRAIN_SKILL}) est premium dans TOUT cycle (D-18, D-33) ; ce
 * qui change ici, ce sont les <b>examens</b> d'un cycle qui n'est pas le
 * premier : {@code lockReason = ACCESS} pour un compte sans acces au module.
 *
 * <p><b>Definition (derivee, jamais persistee)</b> : aucun plan anterieur
 * <b>termine ou mis de cote par le candidat</b> sur ce module. Ne comptent pas
 * les cycles que le lancement D-69 ter a remplaces (marques V082) ni ceux
 * historises avant V077 (sans {@code fin_de_cycle}) : pour ces comptes, le
 * cycle d'examens du lancement EST le premier plan. Le cycle d'affinage D-64
 * (rang 1) l'est aussi.
 */
@Component
@RequiredArgsConstructor
public class JourneyPlanOffert {

    private final JourneyManager journeyManager;

    /** Ce cycle EN COURS est-il le premier plan du candidat sur son module ? */
    public boolean pour(Journey journey) {
        return journeyManager.compterPlansAnterieurs(
                journey.getUser().getId(), journey.getModule()) == 0;
    }
}
