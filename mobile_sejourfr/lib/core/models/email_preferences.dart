/// Miroir de `EmailPreferencesResponse` — `GET|PATCH /api/me/email-preferences`.
///
/// Seul [engagementEnabled] est affiché (V1) ; [marketingEnabled] n'a aucun
/// écran. Miroir web : `EmailPreferences` (`web_sejoufr/lib/types.ts`).
class EmailPreferences {
  const EmailPreferences({
    required this.engagementEnabled,
    required this.marketingEnabled,
  });

  final bool engagementEnabled;
  final bool marketingEnabled;

  factory EmailPreferences.fromJson(Map<String, dynamic> json) {
    return EmailPreferences(
      engagementEnabled: json['engagementEnabled'] as bool? ?? true,
      marketingEnabled: json['marketingEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'engagementEnabled': engagementEnabled,
        'marketingEnabled': marketingEnabled,
      };

  EmailPreferences copyWith({bool? engagementEnabled, bool? marketingEnabled}) {
    return EmailPreferences(
      engagementEnabled: engagementEnabled ?? this.engagementEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
    );
  }
}
