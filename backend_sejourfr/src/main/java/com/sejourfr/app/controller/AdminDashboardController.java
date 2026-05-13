package com.sejourfr.app.controller;

import com.sejourfr.app.dto.DashboardDto;
import com.sejourfr.app.service.DashboardService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/dashboard")
public class AdminDashboardController {

    private final DashboardService service;

    public AdminDashboardController(DashboardService service) {
        this.service = service;
    }

    @GetMapping
    public DashboardDto getDashboard() {
        return service.getDashboard();
    }
}
