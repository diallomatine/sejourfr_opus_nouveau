package com.sejourfr.app.service.examenblanc;

import com.sejourfr.app.entity.ExamTemplate;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.ExamTemplateManager;
import com.sejourfr.app.service.SubscriptionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.UUID;

/**
 * <b>L'autorité du verrou des examens blancs QCM</b>, créneau par créneau.
 *
 * <p>🛑 Arbitrage du propriétaire du 2026-09-24 : « c'est le serveur qui décide
 * du verrouillage ». Chaque règle ci-dessous est lue <b>à la fois</b> par le
 * démarrage (403) et par la grille servie ({@link ExamSlotsService},
 * {@code CivicThemeExamSlotsService}) : les fronts lisent un {@code locked}, ils
 * ne le déduisent jamais du rang.
 *
 * <p>Les examens blancs de <b>production</b> (EE / EO) ont leur propre règle,
 * chez {@code ProductionAccessService.isProductionExamSlotLocked} : leur
 * gratuité est un ledger consommable (D-17), pas un créneau.
 */
@Service
@RequiredArgsConstructor
public class ExamenBlancAccessService {

    private final SubscriptionService subscriptionService;
    private final ExamTemplateManager examTemplateManager;

    /**
     * <b>Le créneau d'une grille d'examens blancs QCM</b> : examens d'épreuve
     * TCF (CO / CE / STRUCTURE), examens de thème civique (D-62) et examens
     * blancs TCF complets.
     *
     * <p>Créneau 1 offert et rejouable à volonté, à un compte gratuit comme à
     * un visiteur ; créneaux 2+ réservés aux abonnés <b>du module</b> (jamais
     * {@code isPremium}, qui est un agrégat).
     *
     * @param userId {@code null} pour un visiteur sans compte
     * @param slot   le créneau, déjà borné
     */
    @Transactional(readOnly = true)
    public boolean isExamenBlancVerrouille(UUID userId, Module module, int slot) {
        if (slot <= 1) return false;
        return !aAcces(userId, module);
    }

    /**
     * <b>Un examen blanc lancé sur un gabarit</b> ({@code ExamTemplate}) : un
     * abonné du module les ouvre tous ; sinon seul le créneau 1 d'un gabarit
     * <b>gratuit</b> est offert ({@code civique-decouverte}, {@code tcf-diagnostic}),
     * rejouable à volonté, et un gabarit payant reste fermé.
     *
     * @param userId {@code null} pour un visiteur sans compte
     */
    @Transactional(readOnly = true)
    public boolean isGabaritVerrouille(UUID userId, ExamTemplate template, int slot) {
        if (aAcces(userId, template.getModule())) return false;
        return !template.isFree() || slot > 1;
    }

    /**
     * La grille des examens blancs <b>globaux</b> d'un module, jouée sur son
     * gabarit gratuit : l'examen civique de 40 questions, et — pour un
     * visiteur — l'examen TCF de /examens-blancs. Sans gabarit gratuit publié,
     * elle n'offre rien à qui n'a pas accès au module.
     *
     * @param userId {@code null} pour un visiteur sans compte
     */
    @Transactional(readOnly = true)
    public boolean isGrilleGabaritVerrouillee(UUID userId, Module module, int slot) {
        return gabaritOffert(module)
                .map(template -> isGabaritVerrouille(userId, template, slot))
                .orElseGet(() -> !aAcces(userId, module));
    }

    /** Le gabarit gratuit publié d'un module, s'il en existe un (le premier par position). */
    @Transactional(readOnly = true)
    public Optional<ExamTemplate> gabaritOffert(Module module) {
        return examTemplateManager.findPublishedByModule(module).stream()
                .filter(ExamTemplate::isFree)
                .findFirst();
    }

    /** L'accès se lit PAR MODULE, jamais sur l'agrégat {@code isPremium}. */
    public boolean aAcces(UUID userId, Module module) {
        if (userId == null) return false;
        return switch (module) {
            case CIVIQUE -> subscriptionService.hasCivique(userId);
            case TCF -> subscriptionService.hasTcf(userId);
        };
    }
}
