/// Miroir de `AccountDeletionResponse` (backend `DELETE /api/account`).
///
/// La suppression aboutit toujours côté serveur ; [manualActionMessage]
/// n'est rempli que quand l'abonnement (Apple/Google) doit être résilié à la
/// main par l'utilisateur dans son store.
class AccountDeletionResult {
  const AccountDeletionResult({
    required this.deleted,
    required this.hasActiveSubscription,
    this.subscriptionProvider,
    this.manualActionMessage,
  });

  final bool deleted;
  final bool hasActiveSubscription;
  final String? subscriptionProvider;
  final String? manualActionMessage;

  factory AccountDeletionResult.fromJson(Map<String, dynamic> json) {
    return AccountDeletionResult(
      deleted: json['deleted'] as bool? ?? true,
      hasActiveSubscription: json['hasActiveSubscription'] as bool? ?? false,
      subscriptionProvider: json['subscriptionProvider'] as String?,
      manualActionMessage: json['manualActionMessage'] as String?,
    );
  }
}
