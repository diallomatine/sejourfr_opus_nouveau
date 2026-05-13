package com.sejourfr.app.service;

import com.sejourfr.app.dto.DashboardDto;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.repository.ConversationRepository;
import com.sejourfr.app.repository.QuestionRepository;
import com.sejourfr.app.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class DashboardService {

    private final QuestionRepository questionRepository;
    private final UserRepository userRepository;
    private final ConversationRepository conversationRepository;

    public DashboardService(QuestionRepository questionRepository,
                            UserRepository userRepository,
                            ConversationRepository conversationRepository) {
        this.questionRepository = questionRepository;
        this.userRepository = userRepository;
        this.conversationRepository = conversationRepository;
    }

    public DashboardDto getDashboard() {
        return new DashboardDto(
                questionRepository.countByModule(Module.CIVIQUE),
                questionRepository.countByModuleAndActive(Module.CIVIQUE, true),
                questionRepository.countByModule(Module.TCF),
                questionRepository.countByModuleAndActive(Module.TCF, true),
                userRepository.count(),
                conversationRepository.countByUnreadForAdminTrue()
        );
    }
}
