package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.enums.JourneyStatus;
import com.sejourfr.app.enums.Module;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface JourneyRepository extends JpaRepository<Journey, UUID> {

    /**
     * Le cycle du candidat sur ce module, dans cet etat.
     *
     * <p>🛑 <b>La cle de lecture est {@code (user, module, status)}, plus le
     * niveau cible</b> (D-13). L'ancienne lecture par niveau cible creait un
     * second cycle des que le candidat changeait d'objectif — ce que les index
     * uniques partiels de V067 refusent desormais, et pour une bonne raison :
     * historiser le cycle en cours jetterait le plan qu'il a sous les yeux.
     * Le cycle survit, c'est son {@code target_level} qui change.
     */
    Optional<Journey> findByUserIdAndModuleAndStatus(
            UUID userId, Module module, JourneyStatus status);

    /**
     * Combien de cycles sont deja <b>historises</b> — le rang du cycle courant
     * s'en deduit (« Cycle 2 »).
     *
     * <p>Les {@link JourneyStatus#HISTORISE} sont libres et multiples : ils
     * <b>sont</b> l'historique des cycles. L'index
     * {@code idx_journey_user_module_status} sert cette requete.
     */
    long countByUserIdAndModuleAndStatus(UUID userId, Module module, JourneyStatus status);

    /**
     * <b>Les cycles du module qui se racontent</b> : l'historique et le cycle en
     * cours, <b>par ordre chronologique de creation</b>.
     *
     * <p>C'est la <b>seule</b> requete de collection de la page Progression cote
     * cycles. Elle sert trois choses d'un coup :
     * <ul>
     *   <li>les cycles <b>historises</b>, que l'ecran liste ;</li>
     *   <li>le <b>rang</b> de chacun, qui est sa place dans cet ordre
     *       ({@code JourneyCycleRank}) — d'ou le tri par {@code created_at} et
     *       non par {@code historise_at} ;</li>
     *   <li>le cycle <b>en cours</b>, dont les etapes closes entrent dans les
     *       compteurs d'en-tete (« tout ce que vous avez deja travaille »).</li>
     * </ul>
     *
     * <p>🛑 <b>Le cycle {@code EN_ATTENTE} est exclu en base</b>, pas filtre
     * apres coup : il est <b>invisible du candidat</b> (D-13), et le laisser
     * remonter jusqu'au service laisserait a chaque lecteur la charge de s'en
     * souvenir. Un filtre oublie une fois suffit a exposer un cycle qui n'existe
     * pas encore pour lui — et a decaler tous les rangs.
     *
     * <p>Index : {@code idx_journey_user_module_status}.
     */
    @Query("""
            SELECT j FROM Journey j
            WHERE j.user.id = :userId
              AND j.module = :module
              AND j.status <> com.sejourfr.app.enums.JourneyStatus.EN_ATTENTE
            ORDER BY j.createdAt ASC, j.id ASC
            """)
    List<Journey> findRacontables(@Param("userId") UUID userId, @Param("module") Module module);

    /**
     * Le parcours, <b>verrouille</b> pour ecriture (R14).
     *
     * <p>🛑 <b>Un verrou pessimiste, pas un optimiste.</b> Deux evaluations
     * peuvent se terminer en meme temps — une production EE corrigee en
     * asynchrone pendant que le candidat finit un QCM sur son telephone — et
     * chacune veut ajouter des etapes en fin de file. Un {@code @Version}
     * aurait fait echouer la seconde, donc <b>perdu</b> son lot : ces
     * traitements sont declenches en best-effort, personne ne les rejoue. Le
     * verrou les <b>serialise</b> a la place, et les deux lots entrent.
     *
     * <p>C'est aussi ce qui rend {@code next_position} fiable sans sequence
     * dediee : la reservation d'une position se fait sous ce verrou.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT j FROM Journey j WHERE j.id = :id")
    Optional<Journey> findByIdForUpdate(@Param("id") UUID id);

    @Modifying
    @Query("DELETE FROM Journey j WHERE j.user.id = :userId")
    int deleteByUserId(@Param("userId") UUID userId);
}
