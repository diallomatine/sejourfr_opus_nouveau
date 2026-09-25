import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/repositories.dart';
import '../../core/models/email_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/list_group.dart';
import 'account_labels.dart';
import 'account_widgets.dart';

/// Les préférences d'e-mails de l'utilisateur. [setEngagement] bascule
/// d'abord l'état (optimiste), puis le rétablit si l'envoi échoue.
class EmailPreferencesNotifier
    extends AutoDisposeAsyncNotifier<EmailPreferences> {
  @override
  Future<EmailPreferences> build() =>
      ref.read(profileRepositoryProvider).getEmailPreferences();

  Future<void> setEngagement(bool enabled) async {
    final previous = state.valueOrNull;
    if (previous == null) return;
    state = AsyncData(previous.copyWith(engagementEnabled: enabled));
    try {
      final saved = await ref
          .read(profileRepositoryProvider)
          .updateEmailPreferences(engagementEnabled: enabled);
      state = AsyncData(saved);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final emailPreferencesProvider = AsyncNotifierProvider.autoDispose<
    EmailPreferencesNotifier, EmailPreferences>(EmailPreferencesNotifier.new);

/// « Notifications par e-mail » — `GET|PATCH /api/me/email-preferences`.
/// Un seul interrupteur en V1 : les e-mails d'accompagnement. Miroir de
/// `web_sejoufr/app/_components/compte/NotificationsView.tsx`.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

enum _Feedback { saved, failed }

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _saving = false;
  _Feedback? _feedback;
  Timer? _savedTimer;

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggle(bool next) async {
    _savedTimer?.cancel();
    setState(() {
      _saving = true;
      _feedback = null;
    });
    try {
      await ref.read(emailPreferencesProvider.notifier).setEngagement(next);
      if (!mounted) return;
      setState(() => _feedback = _Feedback.saved);
      _savedTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _feedback = null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _feedback = _Feedback.failed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(emailPreferencesProvider);
    return AccountScaffold(
      title: kCompteNotifTitle,
      lead: kCompteNotifLead,
      children: prefs.when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
        error: (_, __) => const [AccountAlert(message: kCompteNotifLoadFailed)],
        data: (p) => [
          ListGroup(
            children: [
              ListRow(
                icon: LucideIcons.bell,
                title: kCompteNotifEngagementLabel,
                sub: kCompteNotifEngagementSub,
                subMaxLines: 4,
                right: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AccountSwitch(
                    value: p.engagementEnabled,
                    busy: _saving,
                    semanticLabel: kCompteNotifEngagementLabel,
                    onChanged: _toggle,
                  ),
                ),
              ),
            ],
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 14),
            AccountAlert(
              message: _feedback == _Feedback.saved
                  ? kCompteNotifSaved
                  : kCompteNotifSaveFailed,
              ok: _feedback == _Feedback.saved,
            ),
          ],
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              kCompteNotifFootnote,
              style: AppFonts.ui(size: 13, color: AppColors.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
