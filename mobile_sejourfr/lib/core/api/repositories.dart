import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'audience_repository.dart';
import 'attempts_repository.dart';
import 'billing_repository.dart';
import 'contact_repository.dart';
import 'diagnostic_repository.dart';
import 'full_tcf_exam_repository.dart';
import 'lots_repository.dart';
import 'learning_plan_repository.dart';
import 'production_repository.dart';
import 'profile_repository.dart';
import 'realtime_repository.dart';
import 'skill_repository.dart';
import 'themes_repository.dart';
import 'user_content_repository.dart';

final themesRepositoryProvider = Provider<ThemesRepository>(
  (ref) => ThemesRepository(ref.watch(apiClientProvider)),
);

final audienceRepositoryProvider = Provider<AudienceRepository>(
  (ref) => AudienceRepository(ref.watch(apiClientProvider)),
);

final attemptsRepositoryProvider = Provider<AttemptsRepository>(
  (ref) => AttemptsRepository(ref.watch(apiClientProvider)),
);

final userContentRepositoryProvider = Provider<UserContentRepository>(
  (ref) => UserContentRepository(ref.watch(apiClientProvider)),
);

final productionRepositoryProvider = Provider<ProductionRepository>(
  (ref) => ProductionRepository(ref.watch(apiClientProvider)),
);

final realtimeRepositoryProvider = Provider<RealtimeRepository>(
  (ref) => RealtimeRepository(ref.watch(apiClientProvider)),
);

final skillRepositoryProvider = Provider<SkillRepository>(
  (ref) => SkillRepository(ref.watch(apiClientProvider)),
);

final lotsRepositoryProvider = Provider<LotsRepository>(
  (ref) => LotsRepository(ref.watch(apiClientProvider)),
);

final fullTcfExamRepositoryProvider = Provider<FullTcfExamRepository>(
  (ref) => FullTcfExamRepository(ref.watch(apiClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

final contactRepositoryProvider = Provider<ContactRepository>(
  (ref) => ContactRepository(ref.watch(apiClientProvider)),
);

final diagnosticRepositoryProvider = Provider<DiagnosticRepository>(
  (ref) => DiagnosticRepository(ref.watch(apiClientProvider)),
);

final learningPlanRepositoryProvider = Provider<LearningPlanRepository>(
  (ref) => LearningPlanRepository(ref.watch(apiClientProvider)),
);

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepository(ref.watch(apiClientProvider)),
);
