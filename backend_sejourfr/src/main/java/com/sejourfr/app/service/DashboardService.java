package com.sejourfr.app.service;

import com.sejourfr.app.dto.DashboardDto;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.ConversationManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.UserManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class DashboardService {

    private final QuestionManager questionManager;
    private final UserManager userManager;
    private final ConversationManager conversationManager;

    public DashboardDto getDashboard() {
        return new DashboardDto(
                questionManager.countByModule(Module.CIVIQUE),
                questionManager.countByModuleAndActive(Module.CIVIQUE, true),
                questionManager.countByModule(Module.TCF),
                questionManager.countByModuleAndActive(Module.TCF, true),
                userManager.count(),
                conversationManager.countUnreadForAdmin()
        );
    }
}
