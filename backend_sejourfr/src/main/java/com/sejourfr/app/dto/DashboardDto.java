package com.sejourfr.app.dto;

public record DashboardDto(
        long questionsCivique,
        long questionsCiviqueActive,
        long questionsTcf,
        long questionsTcfActive,
        long usersTotal,
        long conversationsUnread
) {}
