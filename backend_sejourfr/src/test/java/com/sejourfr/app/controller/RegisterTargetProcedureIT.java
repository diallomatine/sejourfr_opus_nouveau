package com.sejourfr.app.controller;

import com.sejourfr.app.entity.User;
import com.sejourfr.app.enums.TargetLevel;
import com.sejourfr.app.enums.TargetProcedure;
import com.sejourfr.app.repository.UserRepository;
import com.sejourfr.app.support.AbstractIntegrationTest;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * {@code POST /api/auth/register} et la <b>démarche visée</b>, de bout en bout
 * (vraies migrations Flyway, vraie base).
 *
 * <p>Ce que ça verrouille, et pourquoi : le web fait choisir la démarche sur
 * l'écran de compte qui clôt le diagnostic et l'envoie dans le corps de
 * l'inscription, mais le serveur ne portait pas le champ — il était
 * <b>silencieusement jeté</b>, et les comptes issus du parcours le plus
 * important du produit ressortaient sans démarche ni palier. Trois invariants :
 * <ul>
 *   <li>avec une démarche : les <b>deux</b> colonnes sont posées, le palier
 *       étant celui que la démarche exige (CSP→A2, CR→B1, NAT→B2) ;</li>
 *   <li>sans démarche : rien n'est posé (le mobile n'en envoie pas, il a son
 *       écran de parcours dédié) ;</li>
 *   <li>démarche inconnue : 400 nommé, jamais persistée ni ignorée.</li>
 * </ul>
 */
class RegisterTargetProcedureIT extends AbstractIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private EntityManager entityManager;

    private static String body(String email, String targetProcedure) {
        String procedure = targetProcedure == null
                ? ""
                : ",\"targetProcedure\":\"" + targetProcedure + "\"";
        return "{\"email\":\"" + email + "\",\"password\":\"MotDePasse1!\","
                + "\"firstName\":\"Awa\",\"lastName\":\"Diallo\"" + procedure + "}";
    }

    /**
     * Relit le compte depuis Postgres : {@code flush} pousse l'INSERT (donc les
     * contraintes du schéma réel s'appliquent) et {@code clear} force un vrai
     * SELECT au lieu de relire le cache de premier niveau.
     */
    private User reloadFromDatabase(String email) {
        entityManager.flush();
        entityManager.clear();
        Optional<User> found = userRepository.findByEmail(email);
        assertThat(found).isPresent();
        return found.get();
    }

    @Test
    void register_withCsp_setsProcedureAndItsRequiredLevel() throws Exception {
        String email = "csp.register@test.sejourfr";

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(email, "CSP")))
                .andExpect(status().isOk())
                // La réponse d'inscription porte déjà le couple : le front lit
                // `user` ici, il ne doit pas avoir à rappeler /api/auth/me.
                .andExpect(jsonPath("$.user.targetProcedure").value("CSP"))
                .andExpect(jsonPath("$.user.targetLevel").value("A2"));

        User persisted = reloadFromDatabase(email);
        assertThat(persisted.getTargetProcedure()).isEqualTo(TargetProcedure.CSP);
        assertThat(persisted.getTargetLevel()).isEqualTo(TargetLevel.A2);
    }

    @Test
    void register_withCr_setsProcedureAndItsRequiredLevel() throws Exception {
        String email = "cr.register@test.sejourfr";

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(email, "CR")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.targetProcedure").value("CR"))
                .andExpect(jsonPath("$.user.targetLevel").value("B1"));

        User persisted = reloadFromDatabase(email);
        assertThat(persisted.getTargetProcedure()).isEqualTo(TargetProcedure.CR);
        assertThat(persisted.getTargetLevel()).isEqualTo(TargetLevel.B1);
    }

    @Test
    void register_withNat_setsProcedureAndItsRequiredLevel() throws Exception {
        String email = "nat.register@test.sejourfr";

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(email, "NAT")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.targetProcedure").value("NAT"))
                .andExpect(jsonPath("$.user.targetLevel").value("B2"));

        User persisted = reloadFromDatabase(email);
        assertThat(persisted.getTargetProcedure()).isEqualTo(TargetProcedure.NAT);
        // Le palier vient de l'enum, jamais du client : NAT exige le B2.
        assertThat(persisted.getTargetLevel()).isEqualTo(TargetLevel.B2);
    }

    @Test
    void register_withoutTargetProcedure_leavesBothColumnsEmpty() throws Exception {
        String email = "sans.demarche@test.sejourfr";

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(email, null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.targetProcedure").doesNotExist())
                .andExpect(jsonPath("$.user.targetLevel").doesNotExist());

        User persisted = reloadFromDatabase(email);
        assertThat(persisted.getTargetProcedure()).isNull();
        assertThat(persisted.getTargetLevel()).isNull();
    }

    @Test
    void register_withUnknownProcedure_is400_andCreatesNothing() throws Exception {
        String email = "demarche.inconnue@test.sejourfr";

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(email, "VISA_ETUDIANT")))
                .andExpect(status().isBadRequest())
                // Nommé : le champ, la valeur reçue et les valeurs acceptées.
                // C'est le silence sur ce champ qui a produit le bug.
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("targetProcedure")))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("VISA_ETUDIANT")))
                .andExpect(jsonPath("$.message").value(
                        org.hamcrest.Matchers.containsString("CSP, CR, NAT")));

        entityManager.flush();
        entityManager.clear();
        assertThat(userRepository.findByEmail(email)).isEmpty();
    }
}
