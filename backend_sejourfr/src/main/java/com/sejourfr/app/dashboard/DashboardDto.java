package com.sejourfr.app.dashboard;

public record DashboardDto(
        long questionsCivique,
        long questionsCiviqueActive,
        long questionsTcf,
        long questionsTcfActive,
        long usersTotal,
        long conversationsUnread
) {}
