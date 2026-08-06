import '../../core/models/enums.dart';

/// Règle de l'info one-time « 1 essai d'entraînement gratuit par épreuve »
/// (EE/EO), annoncée sur la liste des sujets TCF complets.
///
/// Source de la règle : `ProductionAccessService.enforceQuota` (1 essai
/// d'entraînement par épreuve à vie pour un compte gratuit) +
/// `AttemptService.startProductionAttempt` (1 examen blanc de production
/// offert, dont les soumissions ne consomment pas ce quota).
///
/// La clé est **la même que celle du web** (`lib/production-quota-info.ts`) :
/// mémorisation **par épreuve**, puisque l'essai gratuit se compte par
/// épreuve — une fois pour l'écrit, une fois pour l'oral.
String prodQuotaInfoKey(EpreuveType epreuve) =>
    'sejourfr.prodQuotaInfo.${epreuve.wire}';
