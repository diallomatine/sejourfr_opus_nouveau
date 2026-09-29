import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/list_group.dart';
import 'account_labels.dart';
import 'account_widgets.dart';

/// « Mes informations » : les trois données du compte, chacune ouvrant son
/// écran d'édition (nom et prénom, adresse e-mail, mot de passe). Un compte
/// Google / Apple garde son nom modifiable ; e-mail et mot de passe y sont en
/// lecture, avec la raison. Miroir de
/// `web_sejoufr/app/_components/compte/InformationsView.tsx`.
class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = auth.user;
    final provider = user.authProvider;
    final isLocal = compteIsLocal(provider);
    final fullName = [user.firstName, user.lastName]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');

    return AccountScaffold(
      title: kCompteInfoTitle,
      lead: kCompteInfoLead,
      children: [
        ListGroup(
          children: [
            ListRow(
              icon: LucideIcons.userRound,
              title: kCompteRowIdentity,
              sub: fullName.isEmpty ? kCompteIdentityEmpty : fullName,
              onTap: () => context.push(AppRoutes.personalInfoIdentity),
            ),
            ListRow(
              icon: LucideIcons.mail,
              iconBg: isLocal ? null : AppColors.surface2,
              iconColor: isLocal ? null : AppColors.muted,
              title: kCompteRowEmail,
              sub: user.email,
              onTap: isLocal
                  ? () => context.push(AppRoutes.personalInfoEmail)
                  : null,
            ),
            ListRow(
              icon: LucideIcons.keyRound,
              iconBg: isLocal ? null : AppColors.surface2,
              iconColor: isLocal ? null : AppColors.muted,
              title: kCompteRowPassword,
              sub: isLocal ? kComptePasswordMask : compteProviderManaged(provider),
              onTap: isLocal
                  ? () => context.push(AppRoutes.personalInfoPassword)
                  : null,
            ),
          ],
        ),
        if (!isLocal) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${compteEmailProviderNote(provider)}\n${comptePasswordProviderNote(provider)}',
              style: AppFonts.ui(size: 13, color: AppColors.muted, height: 1.5),
            ),
          ),
        ],
      ],
    );
  }
}
