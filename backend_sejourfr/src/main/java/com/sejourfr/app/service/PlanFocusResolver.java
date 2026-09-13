package com.sejourfr.app.service;

import com.sejourfr.app.entity.LearningPlanObservation;
import com.sejourfr.app.entity.PlanPinnedPriority;
import com.sejourfr.app.entity.Skill;
import com.sejourfr.app.entity.User;
import com.sejourfr.app.manager.DiagnosticSessionManager;
import com.sejourfr.app.manager.LearningPlanObservationManager;
import com.sejourfr.app.manager.PlanPinnedPriorityManager;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
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
 *
 * <h2>🛑 La premiere place est EPINGLEE, et l'epingle est persistee</h2>
 * <b>Une nouvelle observation ne deplace plus l'etape en cours</b> (regle
 * produit du 2026-09-13). Le classement ci-dessus trie par statut, confiance
 * puis <b>recence</b> : une production rendue sur une <i>autre</i> competence
 * devenait donc, par sa seule fraicheur, la nouvelle premiere place, et l'etape
 * commencee disparaissait de l'ecran au milieu de son cycle. Cas reel : EE3
 * « Developper un argument » affichee a 0/5, remplacee par EO1 des la premiere
 * production orale.
 *
 * <p>La competence designee est donc <b>ecrite</b>
 * ({@code plan_pinned_priorities}, une ligne par candidat) et <b>maintenue</b>
 * tant qu'elle reste dans le pool. C'est la seule chose que le Plan persiste en
 * dehors de ses observations, parce que c'est la seule qui ne se derive de
 * rien : l'etape sautait a <b>0/5</b>, donc aucun sujet traite ne permettait de
 * retrouver apres coup laquelle avait ete designee.
 *
 * <p><b>La file d'attente, elle, reste entierement derivee</b> :
 * {@link PlanActionRanker} ordonne deja le pool <b>entier</b> par score, une
 * action par competence — donc sans doublon par construction, et sans plafond
 * (seul l'affichage coupe). Une nouvelle faiblesse s'y range a son rang ; elle
 * n'ecrase rien.
 *
 * <h2>Quand l'epingle est liberee</h2>
 * <b>Aucune regle de cycle n'est reecrite ici.</b> La sortie de cycle est deja
 * ecrite dans {@link LearningPlanPriorityResolver#actionable} : elle ecarte une
 * competence dont le <b>transfert est prouve</b> ({@code transferProven}) ou
 * dont la <b>verification a ete rendue</b> ({@code verificationSubmitted}).
 * D'ou la regle entiere, en une phrase : <i>tant que la competence epinglee est
 * dans le pool, elle reste premiere ; des qu'elle en sort, l'epingle passe a la
 * tete du classement</i>.
 *
 * <p>Consequences voulues, et c'est exactement la demande :
 * <ul>
 *   <li>micro-entrainement a 3/5, nouvelle faiblesse observee ailleurs : la
 *       premiere place <b>ne bouge pas</b> ;</li>
 *   <li>5/5 atteint : la carte passe a {@code A_VERIFIER} — son poids de nature
 *       tombe de 1000 a 800 dans {@link PlanActionRanker} — et elle reste
 *       <b>quand meme</b> premiere, parce que l'epingle passe avant le score ;</li>
 *   <li>verification rendue : {@code actionable} ne la rend plus, l'epingle est
 *       liberee, la meilleure en attente est promue — <b>meme si la competence
 *       n'est pas SOLID</b>. Elle reviendra selon les regles du moteur, elle ne
 *       sera pas interrompue au milieu.</li>
 * </ul>
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
    private final PlanDomainTargetLevelResolver targetLevelResolver;
    private final PlanPinnedPriorityManager pinManager;

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
     * <b>La premiere place, epinglee</b> : maintenue tant que la competence
     * qu'elle designe est encore dans le pool, sinon reposee sur la tete du
     * classement. C'est la forme qu'utilise {@link LearningPlanService}, et la
     * <b>seule</b> qui ecrit.
     *
     * <p>Deux lectures du Plan sans action du candidat rendent donc la meme
     * premiere place, quelle que soit la production rendue entre les deux.
     *
     * <p>🛑 <b>{@code candidats} doit etre le pool DEJA FILTRE</b> — les
     * fragilites executables puis les acquisitions, dans l'ordre de
     * {@link #focus(List, List)}. Epingler une competence sans contenu publie
     * reviendrait a epingler une carte que le Plan n'affiche pas : la premiere
     * place serait designee sur du vide, et le freemium ouvrirait une competence
     * qui ne propose rien.
     *
     * @param user      le candidat, deja charge par l'appelant. {@code null}
     *                  n'arrive pas sur un Plan {@code ACTIVE} ; on retombe alors
     *                  sur le classement seul, sans rien ecrire.
     * @param candidats le pool ordonne, fragilites executables d'abord.
     */
    @Transactional
    public Optional<Skill> epingler(User user, List<Skill> candidats) {
        if (user == null) return premier(candidats);
        // UNE SEULE lecture de l'epingle par construction du Plan : elle sert a
        // la fois a savoir si on la maintient et, le cas echeant, a la reecrire
        // en place. La relire pour ecrire aurait coute une requete de plus a
        // chaque ouverture de l'ecran.
        PlanPinnedPriority epingle = pinManager.find(user.getId()).orElse(null);
        Optional<Skill> choisie = maintenue(epingle, candidats).or(() -> premier(candidats));
        if (choisie.isEmpty()) {
            // Plus rien a faire : l'epingle ne survit pas au pool qu'elle
            // designait. La laisser ferait revivre une etape que le moteur a
            // fermee des que le catalogue lui rendrait une action.
            if (epingle != null) pinManager.release(user.getId());
            return Optional.empty();
        }
        Skill premiere = choisie.get();
        // 🛑 ON NE REECRIT PAS UNE EPINGLE INCHANGEE. `pinned_at` date la PRISE
        // de la premiere place ; une ecriture a chaque lecture en ferait un
        // horodatage de consultation, et le GET du Plan un UPDATE par appel.
        if (epingle != null && premiere.getId().equals(epingle.getSkill().getId())) {
            return choisie;
        }
        PlanPinnedPriority ligne = epingle == null ? new PlanPinnedPriority() : epingle;
        ligne.setUser(user);
        ligne.setSkill(premiere);
        ligne.setPinnedAt(Instant.now());
        pinManager.save(ligne);
        return choisie;
    }

    /**
     * <b>La competence epinglee si elle est encore dans le pool</b>, sinon rien.
     * Regle de maintien unique, partagee par la forme qui ecrit
     * ({@link #epingler}) et par celles qui ne font que lire.
     *
     * <p>L'appartenance au pool <b>est</b> la condition de cycle : une etape
     * dont la verification a ete rendue, ou dont le transfert est prouve, n'y
     * figure deja plus ({@link LearningPlanPriorityResolver#actionable}). Rien
     * n'est reecrit ici — ni « 5/5 », ni « a verifier », ni {@code SOLID}.
     */
    private static Optional<Skill> maintenue(PlanPinnedPriority epingle, List<Skill> candidats) {
        if (epingle == null || candidats == null || candidats.isEmpty()) return Optional.empty();
        UUID skillId = epingle.getSkill().getId();
        return candidats.stream()
                .filter(skill -> skill != null && skillId.equals(skill.getId()))
                .findFirst();
    }

    private static Optional<Skill> premier(List<Skill> candidats) {
        if (candidats == null || candidats.isEmpty()) return Optional.empty();
        return Optional.ofNullable(candidats.get(0));
    }

    /**
     * <b>L'observation qui porte la premiere place</b>, ou {@code null} quand
     * celle-ci est une acquisition (rien n'y a ete observe) ou qu'il n'y en a
     * aucune.
     *
     * <p>Elle existe parce que deux blocs du Plan nomment la priorite n&deg;1 en
     * toutes lettres — « ce qui a change » et le retour de production — et
     * lisaient {@code actionable.getFirst()} en direct. Ils auraient annonce une
     * etape que la carte, epinglee, ne montrait pas.
     */
    public static LearningPlanObservation observationDe(
            List<LearningPlanObservation> actionable, UUID focusSkillId) {
        if (actionable == null || focusSkillId == null) return null;
        return actionable.stream()
                .filter(item -> item.getSkill() != null
                        && focusSkillId.equals(item.getSkill().getId()))
                .findFirst()
                .orElse(null);
    }

    /**
     * <b>La premiere place, en LECTURE SEULE</b>, pour un appelant qui tient
     * deja {@code actionable} : l'etape epinglee si elle y figure encore, sinon
     * la tete du classement.
     *
     * <p>Une requete, et aucune ecriture — designer une premiere place est
     * l'affaire du Plan, pas celle d'un ecran qui la cite. C'est ce dont a
     * besoin le retour de production, affiche juste avant que le candidat
     * n'ouvre son Plan : lui annoncer une etape qu'il n'y verrait pas serait
     * pire que de ne rien lui annoncer.
     */
    @Transactional(readOnly = true)
    public LearningPlanObservation premierePlace(
            UUID userId, List<LearningPlanObservation> actionable) {
        if (actionable == null || actionable.isEmpty()) return null;
        List<Skill> fragilites = actionable.stream()
                .map(LearningPlanObservation::getSkill).toList();
        UUID focus = maintenue(pinManager.find(userId).orElse(null), fragilites)
                .map(Skill::getId)
                .orElseGet(() -> actionable.getFirst().getSkill().getId());
        return observationDe(actionable, focus);
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
            // MEME EPINGLE que le Plan, en LECTURE SEULE : cet appelant n'a
            // designe personne, il n'a donc rien a ecrire. Le pool est ici celui
            // d'avant le filtre de contenu, donc un SUR-ensemble de celui du
            // Plan : une epingle valide pour le Plan l'est toujours ici, et
            // l'inverse ne peut ouvrir qu'une competence de plus — jamais en
            // fermer une a tort, le bon sens de l'erreur pour un verrou
            // commercial.
            List<Skill> fragilites = actionable.stream()
                    .map(LearningPlanObservation::getSkill).toList();
            return maintenue(pinManager.find(userId).orElse(null), fragilites)
                    .map(Skill::getId)
                    .or(() -> focus(actionable, List.of()));
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
                profil.domaines(), priorityResolver.lastActivityBySkill(history).keySet(),
                targetLevelResolver.parSection(
                        userId, profil.domaines(), profil.cycle().objectiveLevel()),
                contentAvailability.charger());
        return maintenue(pinManager.find(userId).orElse(null), acquisitions)
                .map(Skill::getId)
                .or(() -> focus(List.of(), acquisitions));
    }
}
