package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * <b>Quelle competence occupe la premiere place du Plan</b> — l'etape que le
 * candidat lit sous « A faire maintenant ».
 *
 * <p>Elle a deux lecteurs qui doivent dire exactement la meme chose :
 * {@link LearningPlanService}, qui la sert au candidat, et
 * {@link SkillAccessService}, qui l'<b>ouvre</b> a un compte sans acces TCF.
 * Comme {@link LearningPlanPriorityResolver} avant elle, cette classe existe
 * pour qu'il n'y ait pas deux reponses a la meme question.
 *
 * <h2>Pourquoi une autorite de plus</h2>
 * Depuis que le Plan sait <b>enseigner</b> et pas seulement <b>reparer</b>
 * ({@code PlanActionNature.A_ACQUERIR}), la premiere place peut etre occupee par
 * une competence <b>jamais travaillee</b>. Or {@code currentPrioritySkillId} ne
 * connait que les <b>fragilites observees</b> : elle se lit sur l'historique, et
 * une competence a acquerir n'y figure pas, par construction. La priorite n&deg;1
 * etait donc <b>designee, visible… et verrouillee</b> — le Plan promettait une
 * action que le candidat ne pouvait pas commencer.
 *
 * <p><b>Arbitrage du proprietaire (2026-08-21)</b> : « un candidat non abonne
 * pourra travailler sa priorite 1, vu qu'elle est visible ». La regle freemium
 * redevient donc entiere — <b>la premiere place est toujours ouverte, quelle que
 * soit la nature de l'action</b>.
 *
 * <h2>La regle, en une phrase</h2>
 * La premiere <b>fragilite actionnable</b> ; a defaut, la premiere
 * <b>acquisition</b>. C'est exactement l'ordre dans lequel
 * {@link LearningPlanService} empile ses cartes — on repare ce qui bloque avant
 * d'apprendre ce qui vient — et c'est pour cela que la forme
 * {@link #focus(List, List) en memoire} suffit au Plan.
 *
 * <h2>🛑 Le cout, et le retour anticipe qui le tient</h2>
 * <b>Une acquisition ne peut occuper la premiere place que si le candidat n'a
 * AUCUNE fragilite actionnable</b> (elles passent toutes devant). Le chemin
 * complet n'est donc emprunte que dans ce cas :
 * <ul>
 *   <li>candidat avec au moins une fragilite — l'immense majorite : <b>une
 *       requete</b>, l'historique, exactement comme avant ce chantier ;</li>
 *   <li>sans fragilite et sans diagnostic termine : <b>+1</b>, puis sortie — le
 *       Plan ne rend aucune acquisition sans diagnostic termine ;</li>
 *   <li>sans fragilite, diagnostic termine : le cycle de palier et le
 *       referentiel du palier, soit une dizaine de requetes <b>bornees</b>
 *       (jamais une par competence).</li>
 * </ul>
 * ⚠️ <b>Ce retour anticipe est l'inverse de la regle du Plan</b>, qui exige au
 * contraire un cout <b>inconditionnel</b> ({@code PlanAcquisitionSelector}, §
 * Cout). Les deux se defendent parce qu'ils protegent des choses differentes :
 * le Plan est <b>un</b> ecran dont on veut pouvoir verifier le cout par une
 * egalite, {@link SkillAccessService} est appele par <b>tous</b> les ecrans de
 * competences et son cout doit rester au plus bas. C'est aussi pourquoi
 * {@link LearningPlanService} ne passe jamais par
 * {@link #currentFocusSkillId(UUID)} : il connait deja ses deux listes et
 * appelle la forme en memoire, donc <b>zero requete de plus</b> sur le Plan.
 */
@Component
@RequiredArgsConstructor
public class PlanFocusResolver {

    private final LearningPlanObservationManager observationManager;
    private final LearningPlanPriorityResolver priorityResolver;
    private final DiagnosticSessionManager sessionManager;
    private final UserManager userManager;
    private final PlanCycleResolver cycleResolver;
    private final PlanAcquisitionSelector acquisitionSelector;
    private final PlanContentAvailability contentAvailability;

    /**
     * La regle, sur des listes <b>deja calculees</b> : la premiere fragilite
     * actionnable, a defaut la premiere acquisition.
     *
     * <p>C'est la forme qu'utilise {@link LearningPlanService}, qui a construit
     * les deux listes quelques lignes plus haut. Aucune requete, aucun calcul
     * refait — et surtout aucune seconde regle.
     *
     * <p>⚠️ <b>Limite assumee et sans consequence</b> : le Plan ecarte de ses
     * cartes une acquisition <b>sans exercice publie</b> (« jamais une carte sans
     * action »), ce que cette methode ne peut pas savoir — l'exercice se choisit
     * apres, et le choisir avant creerait un cycle (le selecteur d'exercice lit
     * l'acces). Une competence d'expression sans aucun sujet actif serait donc
     * ouverte sans etre affichee : elle n'a aucun sujet, donc rien a produire, et
     * l'ouverture ne donne acces a rien. Le catalogue publie n'en compte aucune.
     */
    public static Optional<UUID> focus(
            List<LearningPlanObservation> actionable, List<Skill> acquisitions) {
        if (actionable != null && !actionable.isEmpty()) {
            return Optional.ofNullable(actionable.get(0).getSkill()).map(Skill::getId);
        }
        if (acquisitions != null && !acquisitions.isEmpty()) {
            return Optional.ofNullable(acquisitions.get(0)).map(Skill::getId);
        }
        return Optional.empty();
    }

    /**
     * La meme regle, pour un appelant qui ne dispose de rien — c'est le cas de
     * {@link SkillAccessService}, appele depuis n'importe quel ecran.
     *
     * <p><b>On n'exige pas de diagnostic termine pour la fragilite</b>, alors que
     * le Plan ne rend ses priorites qu'une fois le diagnostic {@code COMPLETED} :
     * une observation probante venue d'une correction de production suffit.
     * Comportement historique de {@code currentPrioritySkillId}, conserve tel
     * quel — le pire cas est une competence ouverte de plus, jamais une
     * competence fermee a tort, et c'est le bon sens de l'erreur pour un verrou
     * commercial. L'<b>acquisition</b>, elle, exige ce diagnostic : le Plan n'en
     * designe aucune sans lui, et l'ouvrir quand meme couterait le cycle entier a
     * tous les comptes neufs.
     */
    @Transactional(readOnly = true)
    public Optional<UUID> currentFocusSkillId(UUID userId) {
        List<LearningPlanObservation> history = observationManager.findAllByUserWithSkill(userId);
        List<LearningPlanObservation> actionable = priorityResolver.actionable(history);
        if (!actionable.isEmpty()) {
            return focus(actionable, List.of());
        }
        // Aucune fragilite : la premiere place revient peut-etre a une
        // competence a ACQUERIR. C'est le seul cas ou le cycle doit tourner.
        if (sessionManager.findLatestCompleted(userId).isEmpty()) {
            return Optional.empty();
        }
        User user = userManager.findById(userId).orElse(null);
        PlanCycleResolver.Resolution profil = cycleResolver.resolve(user, history, List.of());
        // MEME FILTRE QUE LE PLAN : la competence ouverte d'office doit etre
        // celle que le Plan met reellement en premiere place. Ouvrir une
        // competence sans contenu publie donnerait un cadenas leve sur du vide.
        List<Skill> acquisitions = acquisitionSelector.select(
                userId, profil.domaines(),
                priorityResolver.lastActivityBySkill(history).keySet(),
                profil.cycle().objectiveLevel(), contentAvailability.charger());
        return focus(List.of(), acquisitions);
    }
}
