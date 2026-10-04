import 'dart:async';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';

import '../analytics/client_context.dart';
import '../analytics/traffic_source.dart';
import '../auth/token_storage.dart';
import '../models/auth_models.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Construit le client Dio avec :
///  - en-tête Authorization auto si access token présent
///  - refresh automatique sur 401 + rejeu de la requête
///  - mapping des erreurs vers [ApiException]
class ApiClient {
  ApiClient({required TokenStorage tokenStorage, ClientContext? clientContext})
      : _tokenStorage = tokenStorage,
        _clientContext = clientContext {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'User-Agent': userAgent,
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  /// User-agent qui **nomme le système**, et rien d'autre.
  ///
  /// Sans lui, Dart envoie « Dart/3.x (dart:io) » : le serveur
  /// (`DeviceTypeResolver`) refuse — à juste titre — de deviner, et **tous**
  /// les événements de l'app ressortent avec un type d'appareil inconnu. Le
  /// système sur lequel tourne l'app est un **fait** lisible localement, pas
  /// une affirmation : on le dit.
  ///
  /// 🛑 Rien d'identifiant n'y entre : ni modèle d'appareil, ni identifiant
  /// d'installation, ni compte. Le serveur ne conserve d'ailleurs pas cette
  /// chaîne, seulement sa conclusion.
  static String get userAgent {
    final os = Platform.isIOS || Platform.isMacOS
        ? 'ios'
        : Platform.isAndroid
            ? 'android'
            : 'unknown';
    return 'SejourFR ($os)';
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;
  final ClientContext? _clientContext;

  /// Callback déclenché si le refresh échoue → déconnexion globale.
  void Function()? onUnauthorized;

  /// Callback déclenché à chaque réponse reçue du serveur : le réseau répond.
  /// C'est le signal « retour réseau » de la file d'événements d'analytics,
  /// sans dépendance de plus sur un détecteur de connectivité.
  void Function()? onReachable;

  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Interceptors
  // ---------------------------------------------------------------------------

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await _tokenStorage.readAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    _applyTrafficSource(options.headers);
    await _applyClientContext(options.headers);
    handler.next(options);
  }

  /// Pose `X-Sejourfr-Client` (`ios` | `android`), `X-Sejourfr-Anonymous-Id`
  /// et `X-Sejourfr-App-Version` sur **toutes** les requêtes, `skipAuth`
  /// comprises — l'inscription et les routes publiques du diagnostic en font
  /// partie. Un seul point de câblage : [ClientContext]. Un en-tête déjà posé
  /// par l'appelant n'est pas écrasé.
  Future<void> _applyClientContext(Map<String, dynamic> headers) async {
    final context = _clientContext;
    if (context == null) return;
    final values = await context.headers();
    values.forEach((name, value) => headers.putIfAbsent(name, () => value));
  }

  /// Pose `X-Sejourfr-Source` **quand, et seulement quand, une provenance a
  /// réellement été observée** — miroir de ce que fait `lib/api.ts` côté web,
  /// où l'en-tête n'est ajouté que si `detectTrafficSource()` rend une valeur.
  ///
  /// 🛑 **Jamais de `direct` fabriqué.** Sans en-tête, le serveur rend
  /// « inconnu », qui est vrai ; un `direct` posé par défaut ferait passer
  /// toutes les inscriptions mobiles pour de l'accès direct — c'est exactement
  /// le défaut qu'on corrige.
  ///
  /// Posé dans l'intercepteur plutôt que dans `BaseOptions` parce que la
  /// provenance peut arriver **après** la construction du client (deep link de
  /// campagne ouvert alors que l'app tourne déjà), comme le web la recalcule à
  /// chaque appel. S'applique à **toutes** les requêtes, `skipAuth` comprises —
  /// l'inscription en fait partie.
  static void _applyTrafficSource(Map<String, dynamic> headers) {
    final source = AnalyticsTrafficSource.current;
    if (source != null) headers['X-Sejourfr-Source'] = source.wire;
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    onReachable?.call();
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      // `validateStatus` laisse passer les 4xx comme des réponses "réussies".
      // Le 2e argument `true` (callFollowingErrorInterceptor) est indispensable :
      // sans lui, le rejet court-circuite `_onError` → ni refresh ni forceLogout,
      // et le 401 « Authentification requise » remonte tel quel à l'écran.
      handler.reject(_toDioException(response), true);
      return;
    }
    handler.next(response);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode ?? 0;
    final opts = err.requestOptions;

    if (status == 401 && opts.extra['skipRefresh'] != true) {
      // Tentative de récupération via refresh (une seule fois par requête).
      if (opts.extra['retry'] != true) {
        final outcome = await _refreshFor(opts);
        if (outcome == _RefreshOutcome.ok) {
          try {
            final newAccess = await _tokenStorage.readAccess();
            final retried = await _dio.fetch(
              opts
                ..headers['Authorization'] = 'Bearer $newAccess'
                ..extra['retry'] = true,
            );
            handler.resolve(retried);
            return;
          } on DioException catch (e) {
            // Le rejeu a aussi échoué : si c'est encore un 401, la session
            // est morte → déconnexion globale.
            if ((e.response?.statusCode ?? 0) == 401) {
              await _forceLogout();
            }
            handler.reject(e);
            return;
          }
        }
        if (outcome == _RefreshOutcome.unavailable) {
          // 🛑 Le serveur n'a pas pu répondre au refresh (réseau, 5xx) : ce
          // n'est pas un refus, la session survit. On remonte une erreur
          // RÉSEAU (statusCode 0), que l'amorçage sait traiter sans
          // effacer les jetons.
          handler.reject(DioException(
            requestOptions: opts,
            type: DioExceptionType.connectionError,
            error: err.error,
          ));
          return;
        }
      }
      // 401 non récupérable (refresh refusé, ou requête déjà rejouée, ou refresh
      // désactivé sur la requête) : session invalide → déconnexion globale.
      // Sans ça, le 401 remonte aux écrans qui affichent "Authentification
      // requise" au lieu de rebasculer vers l'écran de connexion.
      await _forceLogout();
    }

    handler.next(err);
  }

  /// Vide les tokens et notifie l'app (→ retour écran de connexion).
  Future<void> _forceLogout() async {
    await _tokenStorage.clear();
    onUnauthorized?.call();
  }

  // ---------------------------------------------------------------------------
  // Refresh token (avec mutex pour éviter les appels parallèles)
  // ---------------------------------------------------------------------------
  //
  // Le serveur fait TOURNER le refresh token : l'ancien est révoqué dès qu'un
  // successeur est émis. Un second refresh avec l'ancien jeton est donc refusé
  // (« Session révoquée ») et déconnectait. D'où le mutex, et la relecture de
  // l'access avant de rafraîchir : une requête partie avec un access que le
  // storage a déjà remplacé n'a qu'à être rejouée.

  Future<_RefreshOutcome>? _refreshing;

  Future<_RefreshOutcome> _refreshFor(RequestOptions opts) async {
    final current = await _tokenStorage.readAccess();
    final sent = opts.headers['Authorization'];
    if (current != null && sent != null && sent != 'Bearer $current') {
      return _RefreshOutcome.ok;
    }
    return _tryRefresh();
  }

  Future<_RefreshOutcome> _tryRefresh() {
    _refreshing ??= _doRefresh().whenComplete(() {
      Timer(const Duration(milliseconds: 50), () => _refreshing = null);
    });
    return _refreshing!;
  }

  /// 🛑 Seul un REFUS du serveur (4xx hors 408/429) met fin à la session. Une
  /// coupure réseau, un timeout ou un 5xx gardent les jetons : le candidat
  /// entré dans le métro ne doit pas retrouver l'écran de connexion. Miroir
  /// de `isDefinitiveAuthFailure` (web, `lib/api.ts`).
  Future<_RefreshOutcome> _doRefresh() async {
    final refresh = await _tokenStorage.readRefresh();
    if (refresh == null) return _RefreshOutcome.rejected;
    try {
      final context = await _clientContext?.headers() ?? const {};
      final res = await Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          ...context,
          'User-Agent': userAgent,
          // Le refresh sort du Dio principal : sans ce rappel, il serait la
          // seule requête de l'app à perdre la provenance.
          if (AnalyticsTrafficSource.current != null)
            'X-Sejourfr-Source': AnalyticsTrafficSource.current!.wire,
        },
      )).post(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = res.data as Map<String, dynamic>;
      await _tokenStorage.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      );
      return _RefreshOutcome.ok;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final refused = status != null &&
          status >= 400 &&
          status < 500 &&
          status != 408 &&
          status != 429;
      return refused ? _RefreshOutcome.rejected : _RefreshOutcome.unavailable;
    } catch (_) {
      return _RefreshOutcome.unavailable;
    }
  }

  // ---------------------------------------------------------------------------
  // Mapping erreurs
  // ---------------------------------------------------------------------------

  DioException _toDioException(Response response) {
    final status = response.statusCode ?? 0;
    String message = 'Erreur HTTP $status';
    Map<String, String>? fieldErrors;

    final data = response.data;
    if (data is Map<String, dynamic>) {
      message = (data['message'] as String?) ?? message;
      final raw = data['fieldErrors'];
      if (raw is List) {
        fieldErrors = {
          for (final e in raw)
            if (e is Map<String, dynamic>)
              (e['field'] as String): (e['message'] as String),
        };
      }
    }

    return DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: ApiException(
        statusCode: status,
        message: message,
        fieldErrors: fieldErrors,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  /// Convertit n'importe quelle erreur Dio en ApiException prête à présenter dans l'UI.
  static ApiException toApiException(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      if (error.error is ApiException) return error.error as ApiException;
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return ApiException(
          statusCode: 0,
          message: 'Connexion au serveur impossible. Vérifiez votre réseau.',
        );
      }
      return ApiException(
        statusCode: error.response?.statusCode ?? 0,
        message: error.message ?? 'Erreur réseau',
      );
    }
    return ApiException(statusCode: -1, message: error.toString());
  }
}

enum _RefreshOutcome { ok, rejected, unavailable }
