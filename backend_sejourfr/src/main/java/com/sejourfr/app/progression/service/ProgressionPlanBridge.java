package com.sejourfr.app.progression.service;

import com.sejourfr.app.enums.SkillSection;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.progression.config.ProgressionProperties;
import com.sejourfr.app.progression.domain.DomainProjection;
import com.sejourfr.app.progression.domain.ProgressionStatus;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Le seul endroit où le moteur V4.2 touche au Plan servi</b> — et il ne le
 * touche que si on le lui a explicitement permis (V4.2 §47, phase 2).
 *
 * <p>Tant que {@code sejourfr.progression.mode} vaut {@code SHADOW}, toutes les
 * méthodes de ce pont rendent {@link Optional#empty()}, ce qui se lit
 * « le Plan garde sa propre règle ». Le moteur continue d'enregistrer, de
 * calculer et de prédire à côté, sans que le candidat en voie quoi que ce soit.
 *
 * <p>Passer en {@code ACTIVE} devient alors <b>un changement de variable
 * d'environnement, pas un déploiement de code</b> — et le retour arrière aussi.
 * C'est exactement la propriété qu'il faut pour un moteur dont les seuils sont
 * encore des hypothèses produit : on peut arrêter en une minute.
 *
 * <h2>Ce que ce pont ne fait pas</h2>
 *
 * <p>Il ne recopie <b>aucune</b> règle du moteur. {@code prescriptionLevel},
 * {@code prerequisiteSatisfied} et les états viennent de
 * {@link ProgressionReadService}, qui les tient de l'unique machine à états. Une
 * seconde interprétation ici finirait par désigner un autre niveau que celui que
 * le moteur enregistre — et c'est le défaut le plus cher du dépôt.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ProgressionPlanBridge {

    private final ProgressionProperties properties;
    private final ProgressionReadService readService;

    /**
     * <b>Le seul niveau que le Plan a le droit de proposer</b> pour ce domaine
     * (§19, §20, invariant I15).
     *
     * <p>Un palier en {@code WATCH} prend la main sur l'apprentissage normal :
     * c'est ce qui empêche d'afficher {@code CO A2} et {@code CO B1} le même
     * jour quand B1 est contredit et que son prérequis A2 vient d'être révoqué.
     * Le candidat vérifie d'abord ce qui vacille.
     *
     * @return {@link Optional#empty()} en {@code SHADOW} — le Plan garde sa
     *         règle — ou le niveau prescrit en {@code ACTIVE}. Un
     *         {@code Optional} <b>présent mais vide de niveau</b> n'existe pas :
     *         quand le moteur n'a rien à prescrire, il rend {@code null} dedans,
     *         ce qui veut dire « objectif atteint ».
     */
    public Optional<TargetLevel> prescriptionLevel(UUID userId, SkillSection section,
                                                   TargetLevel objectif) {
        if (!properties.isActive() || userId == null || objectif == null
                || !section.isComprehension()) {
            return Optional.empty();
        }
        DomainProjection projection = readService.domaine(userId, section, objectif, Instant.now());
        return Optional.ofNullable(projection.prescriptionLevel());
    }

    /**
     * La lecture complète d'un domaine, pour qui a besoin du détail —
     * {@code prerequisiteSatisfied}, les états, le niveau prescrit.
     *
     * <p>Vide en {@code SHADOW}, comme le reste : rien de ce que le moteur
     * calcule ne doit atteindre un écran avant que ses seuils aient été
     * confrontés à de vrais candidats.
     */
    public Optional<DomainProjection> domaine(UUID userId, SkillSection section,
                                              TargetLevel objectif) {
        if (!properties.isActive() || userId == null || objectif == null
                || !section.isComprehension()) {
            return Optional.empty();
        }
        return Optional.of(readService.domaine(userId, section, objectif, Instant.now()));
    }

    /**
     * Y a-t-il un acquis à re-vérifier sur ce domaine ? (§15, §30)
     *
     * <p>C'est la priorité n°1 du Plan quand elle existe : un {@code SOLID}
     * contredit une fois n'est pas encore perdu, mais il ne doit plus servir de
     * fondation tant qu'on n'a pas regardé.
     */
    public boolean aUneVerificationEnAttente(UUID userId, SkillSection section,
                                             TargetLevel objectif) {
        return domaine(userId, section, objectif)
                .map(projection -> projection.levels().values().stream()
                        .anyMatch(etat -> etat.status() == ProgressionStatus.WATCH))
                .orElse(false);
    }

    /** Le moteur pilote-t-il réellement le Plan en ce moment ? */
    public boolean actif() {
        return properties.isActive();
    }
}
