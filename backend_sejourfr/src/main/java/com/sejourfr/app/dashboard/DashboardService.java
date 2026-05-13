package com.sejourfr.app.dashboard;

import com.sejourfr.app.message.ConversationRepository;
import com.sejourfr.app.question.QuestionRepository;
import com.sejourfr.app.theme.enums.Module;
import com.sejourfr.app.user.UserRepository;
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
