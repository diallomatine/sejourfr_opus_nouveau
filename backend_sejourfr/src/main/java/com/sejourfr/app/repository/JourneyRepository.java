package com.sejourfr.app.repository;

import com.sejourfr.app.entity.Journey;
import com.sejourfr.app.enums.TargetLevel;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface JourneyRepository extends JpaRepository<Journey, UUID> {

    Optional<Journey> findByUserIdAndTargetLevel(UUID userId, TargetLevel targetLevel);

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
