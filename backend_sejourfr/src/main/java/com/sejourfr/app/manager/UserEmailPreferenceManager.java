package com.sejourfr.app.manager;

import com.sejourfr.app.entity.UserEmailPreference;
import com.sejourfr.app.repository.UserEmailPreferenceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Les preferences email. 🛑 Une ligne absente vaut les valeurs par defaut :
 * {@link #find} rend un {@code Optional}, jamais une ligne fabriquee.
 */
@Component
@RequiredArgsConstructor
public class UserEmailPreferenceManager {

    private final UserEmailPreferenceRepository repository;

    public Optional<UserEmailPreference> find(UUID userId) {
        return repository.findById(userId);
    }

    public UserEmailPreference save(UserEmailPreference preference) {
        return repository.save(preference);
    }

    public int deleteByUserId(UUID userId) {
        return repository.deleteByUserIdQuery(userId);
    }
}
