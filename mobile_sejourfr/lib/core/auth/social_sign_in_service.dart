import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'social_auth_config.dart';

/// Resultat brut d'un sign-in natif. Le backend recoit le token + nom (si
/// dispo) et renvoie la session SejourFR.
class SocialSignInResult {
  SocialSignInResult.google({required this.idToken})
      : provider = SocialProvider.google,
        firstName = null,
        lastName = null;

  SocialSignInResult.apple({
    required this.idToken,
    this.firstName,
    this.lastName,
  }) : provider = SocialProvider.apple;

  final SocialProvider provider;
  final String idToken;
  final String? firstName;
  final String? lastName;
}

enum SocialProvider { google, apple }

/// Levee quand l'utilisateur annule le flow ou que le provider n'a pas
/// renvoye de token valide. Les callers doivent l'attraper et afficher un
/// message non bloquant (ou rien pour une annulation).
class SocialSignInException implements Exception {
  SocialSignInException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;

  @override
  String toString() => 'SocialSignInException($message, cancelled=$cancelled)';
}

/// Encapsule les packages `google_sign_in` + `sign_in_with_apple`.
/// Expose deux methodes : `signInWithGoogle()` et `signInWithApple()`.
class SocialSignInService {
  SocialSignInService();

  GoogleSignIn? _google;

  GoogleSignIn _googleClient() {
    return _google ??= GoogleSignIn(
      serverClientId: SocialAuthConfig.googleServerClientId.isEmpty
          ? null
          : SocialAuthConfig.googleServerClientId,
      clientId: Platform.isIOS && SocialAuthConfig.googleIosClientId.isNotEmpty
          ? SocialAuthConfig.googleIosClientId
          : null,
      scopes: const ['email', 'profile', 'openid'],
    );
  }

  Future<SocialSignInResult> signInWithGoogle() async {
    if (!SocialAuthConfig.isGoogleConfigured) {
      throw SocialSignInException(
        'Google sign-in non configure (GOOGLE_SERVER_CLIENT_ID manquant).',
      );
    }
    final client = _googleClient();
    GoogleSignInAccount? account;
    try {
      account = await client.signIn();
    } catch (e) {
      throw SocialSignInException('Erreur Google : $e');
    }
    if (account == null) {
      throw SocialSignInException('Connexion Google annulee.', cancelled: true);
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      // Cas classique : `serverClientId` absent ou mal configure → le token
      // produit est un access_token, pas un id_token.
      throw SocialSignInException(
        'Google n\'a pas renvoye d\'id_token. Verifier GOOGLE_SERVER_CLIENT_ID.',
      );
    }
    return SocialSignInResult.google(idToken: idToken);
  }

  /// Disponible uniquement sur iOS (cf. CLAUDE.md racine — choix produit).
  Future<SocialSignInResult> signInWithApple() async {
    if (!Platform.isIOS) {
      throw SocialSignInException(
        'Apple Sign In disponible uniquement sur iOS.',
      );
    }
    AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw SocialSignInException(
          'Connexion Apple annulee.',
          cancelled: true,
        );
      }
      throw SocialSignInException('Erreur Apple : ${e.message}');
    } catch (e) {
      throw SocialSignInException('Erreur Apple : $e');
    }
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw SocialSignInException('Apple n\'a pas renvoye d\'identityToken.');
    }
    return SocialSignInResult.apple(
      idToken: idToken,
      firstName: credential.givenName,
      lastName: credential.familyName,
    );
  }

  /// A appeler depuis le logout pour vider la session Google native (sinon
  /// le prochain `signIn()` reutilise silencieusement le dernier compte).
  Future<void> signOutAll() async {
    try {
      await _googleClient().signOut();
    } catch (_) {
      // Best effort.
    }
  }
}
