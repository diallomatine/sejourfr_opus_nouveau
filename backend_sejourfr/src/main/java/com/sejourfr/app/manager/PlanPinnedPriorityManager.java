package com.sejourfr.app.manager;

import com.sejourfr.app.entity.PlanPinnedPriority;
import com.sejourfr.app.repository.PlanPinnedPriorityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/** La priorite courante epinglee : une ligne par candidat, lue et reecrite en place. */
@Component
@RequiredArgsConstructor
public class PlanPinnedPriorityManager {

    private final PlanPinnedPriorityRepository repository;

    public Optional<PlanPinnedPriority> find(UUID userId) {
        return repository.findByUserIdWithSkill(userId);
    }

    /**
     * Ecrit la ligne. <b>L'appelant decide s'il faut ecrire</b> — c'est
     * {@code PlanFocusResolver} qui porte la regle « ne rien reecrire quand
     * c'est deja la meme competence », parce que {@code pinned_at} doit dater la
     * <b>prise</b> de la premiere place et non la derniere lecture du Plan.
     */
    public PlanPinnedPriority save(PlanPinnedPriority pin) {
        return repository.save(pin);
    }

    public int release(UUID userId) {
        return repository.deleteByUserId(userId);
    }
}
