package com.sejourfr.app.dto;

/**
 * Ce que cette production a change dans le Plan — <b>une ligne, pas un rapport</b>.
 *
 * <p>Le resultat d'une tache complete n'enumere pas les competences observees :
 * il dit, quand il y a lieu, « telle competence est confirmee » et « voici la
 * nouvelle priorite ». Les deux champs sont <b>independamment nullables</b>, et
 * le bloc entier vaut {@code null} quand rien n'a bouge.
 *
 * <p><b>Un bloc absent est un cas NORMAL, jamais une erreur.</b> Les observations
 * sont ecrites <b>apres</b> la correction, en best-effort et hors transaction
 * (invariant de {@code ProductionPipelineAsyncRunner}) : un front qui lit le
 * resultat dans la seconde peut arriver avant elles. Le bloc est donc calcule
 * <b>a la lecture</b>, jamais fige a l'ecriture — la lecture suivante le rend
 * des que les observations sont la, sans etat d'echec ni rejeu.
 *
 * <p><b>Aucun libelle ici.</b> Le serveur expose des faits ; la phrase montree au
 * candidat appartient aux fronts. En particulier, un transfert manque ne se dit
 * jamais « vous avez perdu votre progression » : la competence est reussie en
 * exercice cible, elle n'est pas encore automatique en production complete.
 */
public record PlanChangeDto(
        /** Competence que cette production vient de confirmer en situation, ou {@code null}. */
        PlanSkillRefDto confirmedSkill,
        /** Nouvelle priorite n&deg;1 issue de cette meme production, ou {@code null}. */
        PlanSkillRefDto newPriority
) {}
