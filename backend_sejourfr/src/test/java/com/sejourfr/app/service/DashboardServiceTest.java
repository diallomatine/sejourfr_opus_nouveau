package com.sejourfr.app.service;

import com.sejourfr.app.dto.DashboardDto;
import com.sejourfr.app.enums.Module;
import com.sejourfr.app.manager.ConversationManager;
import com.sejourfr.app.manager.QuestionManager;
import com.sejourfr.app.manager.UserManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * Test unitaire pur de l'agrégat admin : projection des compteurs managers
 * dans le DTO (ordre et valeurs).
 */
class DashboardServiceTest {

    private QuestionManager questionManager;
    private UserManager userManager;
    private ConversationManager conversationManager;
    private DashboardService service;

    @BeforeEach
    void setUp() {
        questionManager = mock(QuestionManager.class);
        userManager = mock(UserManager.class);
        conversationManager = mock(ConversationManager.class);
        service = new DashboardService(questionManager, userManager, conversationManager);
    }

    @Test
    void getDashboard_mapsAllCounters() {
        when(questionManager.countByModule(Module.CIVIQUE)).thenReturn(100L);
        when(questionManager.countByModuleAndActive(Module.CIVIQUE, true)).thenReturn(80L);
        when(questionManager.countByModule(Module.TCF)).thenReturn(60L);
        when(questionManager.countByModuleAndActive(Module.TCF, true)).thenReturn(50L);
        when(userManager.count()).thenReturn(42L);
        when(conversationManager.countUnreadForAdmin()).thenReturn(3L);

        DashboardDto dto = service.getDashboard();

        assertThat(dto.questionsCivique()).isEqualTo(100L);
        assertThat(dto.questionsCiviqueActive()).isEqualTo(80L);
        assertThat(dto.questionsTcf()).isEqualTo(60L);
        assertThat(dto.questionsTcfActive()).isEqualTo(50L);
        assertThat(dto.usersTotal()).isEqualTo(42L);
        assertThat(dto.conversationsUnread()).isEqualTo(3L);
    }
}
