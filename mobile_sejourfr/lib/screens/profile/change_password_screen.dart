import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import 'account_labels.dart';
import 'account_widgets.dart';

/// « Mot de passe » — `POST /api/me/change-password`. Miroir de
/// `web_sejoufr/app/_components/compte/MotDePasseForm.tsx`.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  PasswordErrors _errors = const PasswordErrors();
  bool _submitted = false;
  bool _saving = false;
  bool _done = false;
  String? _serverError;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  PasswordErrors _validate() =>
      validatePasswordChange(_current.text, _next.text, _confirm.text);

  void _changed(String _) {
    setState(() {
      _serverError = null;
      if (_submitted) _errors = _validate();
    });
  }

  Future<void> _submit() async {
    final errors = _validate();
    setState(() {
      _submitted = true;
      _errors = errors;
    });
    if (errors.any) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _serverError = null;
    });
    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (!mounted) return;
      setState(() => _done = true);
    } catch (e) {
      if (!mounted) return;
      final message = ApiClient.toApiException(e).message;
      setState(
        () =>
            _serverError = message.isNotEmpty ? message : kComptePasswordFailed,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final provider = auth.user.authProvider;
    final isLocal = compteIsLocal(provider);

    return AccountScaffold(
      title: kComptePasswordTitle,
      lead: isLocal && !_done ? kComptePasswordLead : null,
      children: [
        if (!isLocal)
          AccountProviderNote(note: comptePasswordProviderNote(provider))
        else if (_done)
          const AccountDone(
            title: kComptePasswordSuccessTitle,
            body: kComptePasswordSuccessBody,
          )
        else
          AccountFormCard(
            children: [
              AccountField(
                label: kCompteCurrentPasswordLabel,
                controller: _current,
                onChanged: _changed,
                error: _errors.current,
                password: true,
                enabled: !_saving,
                autofillHints: const [AutofillHints.password],
              ),
              AccountField(
                label: kCompteNewPasswordLabel,
                controller: _next,
                onChanged: _changed,
                error: _errors.next,
                hint: kCompteNewPasswordHint,
                password: true,
                enabled: !_saving,
                autofillHints: const [AutofillHints.newPassword],
              ),
              AccountField(
                label: kCompteConfirmPasswordLabel,
                controller: _confirm,
                onChanged: _changed,
                error: _errors.confirm,
                password: true,
                enabled: !_saving,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (_serverError != null) AccountAlert(message: _serverError!),
              AccountSubmit(
                label: kComptePasswordSubmit,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
      ],
    );
  }
}
