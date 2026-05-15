import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'attempts_repository.dart';
import 'exams_repository.dart';
import 'themes_repository.dart';
import 'user_content_repository.dart';

final themesRepositoryProvider = Provider<ThemesRepository>(
  (ref) => ThemesRepository(ref.watch(apiClientProvider)),
);

final attemptsRepositoryProvider = Provider<AttemptsRepository>(
  (ref) => AttemptsRepository(ref.watch(apiClientProvider)),
);

final examsRepositoryProvider = Provider<ExamsRepository>(
  (ref) => ExamsRepository(ref.watch(apiClientProvider)),
);

final userContentRepositoryProvider = Provider<UserContentRepository>(
  (ref) => UserContentRepository(ref.watch(apiClientProvider)),
);
