import '../config/env.dart';

/// Configuration des providers de social sign-in cote mobile.
///
/// Les valeurs sensibles sont lues a l'execution depuis `.env` (cf.
/// `core/config/env.dart`). Tant qu'une cle est vide, le bouton correspondant
/// n'est pas rendu (pas d'erreur silencieuse a l'execution).
///
/// Exemple `.env` :
/// ```
/// API_BASE_URL=http://localhost:8080
/// GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
/// GOOGLE_IOS_CLIENT_ID=yyy.apps.googleusercontent.com
/// ```
class SocialAuthConfig {
  SocialAuthConfig._();

  /// **Web client ID** Google (cree dans Google Cloud Console > Credentials >
  /// OAuth 2.0 Client IDs > Web application).
  ///
  /// C'est ce client qui doit etre passe en `serverClientId` au package
  /// `google_sign_in` pour que le `idToken` produit ait pour audience le
  /// client web — c'est ce que le backend attend.
  ///
  /// Aussi liste dans `sejourfr.oauth.google.audiences` cote backend.
  static String get googleServerClientId => Env.read('GOOGLE_SERVER_CLIENT_ID');

  /// **iOS client ID** Google (cree dans Google Cloud Console > Credentials >
  /// OAuth 2.0 Client IDs > iOS application). Sert au plugin iOS pour le
  /// scheme d'URL de retour. Le `idToken` produit en passant
  /// `serverClientId` (ci-dessus) a son audience egale au Web client ID, pas
  /// au client iOS — donc inutile de l'ajouter aux audiences backend.
  static String get googleIosClientId => Env.read('GOOGLE_IOS_CLIENT_ID');

  static bool get isGoogleConfigured => googleServerClientId.isNotEmpty;

  /// Apple Sign In ne necessite pas de cle cote mobile : l'identite est
  /// negociee directement avec le systeme iOS via `sign_in_with_apple`.
  /// L'activation se fait au niveau de l'Apple Developer Portal (capability
  /// "Sign in with Apple" + Bundle ID) et de l'entitlement
  /// `Runner.entitlements`. Le backend valide ensuite via JWKS.
  static const bool isAppleConfigured = true;
}
