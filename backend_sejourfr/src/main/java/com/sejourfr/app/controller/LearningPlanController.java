package com.sejourfr.app.controller;

import com.sejourfr.app.dto.LearningPlanDto;
import com.sejourfr.app.security.CurrentUser;
import com.sejourfr.app.service.LearningPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/me/plan")
@RequiredArgsConstructor
public class LearningPlanController {

    private final LearningPlanService learningPlanService;
    private final CurrentUser currentUser;

    @GetMapping
    public LearningPlanDto get() {
        return learningPlanService.get(currentUser.getId());
    }
}
