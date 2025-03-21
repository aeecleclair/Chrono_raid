
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:chrono_raid/tools/constants.dart';
import 'package:chrono_raid/auth/providers/is_connected_provider.dart';
import 'package:chrono_raid/auth/repository/openid_repository.dart';
import 'package:chrono_raid/tools/cache/cache_manager.dart';
import 'package:chrono_raid/tools/repository/repository.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';


final authTokenProvider =
    StateNotifierProvider<OpenIdTokenProvider, AsyncValue<Map<String, String>>>(
        (ref) {
  OpenIdTokenProvider openIdTokenProvider = OpenIdTokenProvider();
  final isConnected = ref.watch(isConnectedProvider);
  if (isConnected) {
    openIdTokenProvider.getTokenFromStorage();
  }
  return openIdTokenProvider;
});

class IsLoggedInProvider extends StateNotifier<bool> {
  IsLoggedInProvider(super.b);

  void refresh(AsyncValue<Map<String, String>> token) {
    state = token.maybeWhen(
      data: (tokens) => tokens["token"] == ""
          ? false
          : !JwtDecoder.isExpired(tokens["token"] as String),
      orElse: () => false,
    );
  }
}

class IsCachingProvider extends StateNotifier<bool> {
  IsCachingProvider(super.b);

  void set(bool b) {
    state = b;
  }
}

final isCachingProvider = StateNotifierProvider<IsCachingProvider, bool>((ref) {
  final IsCachingProvider isCachingProvider = IsCachingProvider(false);

  final isConnected = ref.watch(isConnectedProvider);
  CacheManager().readCache("id").then(
    (value) {
      isCachingProvider.set(!isConnected && value != "");
    },
  );
  return isCachingProvider;
});

final isLoggedInProvider =
    StateNotifierProvider<IsLoggedInProvider, bool>((ref) {
  final IsLoggedInProvider isLoggedInProvider = IsLoggedInProvider(false);

  final isConnected = ref.watch(isConnectedProvider);
  final authToken = ref.watch(authTokenProvider);
  final isCaching = ref.watch(isCachingProvider);
  if (isConnected) {
    isLoggedInProvider.refresh(authToken);
  } else if (isCaching) {
    return IsLoggedInProvider(true);
  }
  return isLoggedInProvider;
});

final loadingProvider = FutureProvider<bool>((ref) {
  final isCaching = ref.watch(isCachingProvider);
  return isCaching ||
      ref.watch(authTokenProvider).when(
            data: (tokens) =>
                tokens["token"] != "" && ref.watch(isLoggedInProvider),
            error: (e, s) => false,
            loading: () => true,
          );
});

final idProvider = FutureProvider<String>((ref) {
  final cacheManager = CacheManager();
  return ref.watch(authTokenProvider).when(
        data: (tokens) {
          final id = tokens["token"] == ""
              ? ""
              : JwtDecoder.decode(tokens["token"] as String)["sub"];
          cacheManager.writeCache("id", id);
          return id;
        },
        error: (e, s) => "",
        loading: () => cacheManager.readCache("id"),
      );
});

final tokenProvider = Provider((ref) {
  return ref.watch(authTokenProvider).maybeWhen(
        data: (tokens) => tokens["token"] as String,
        orElse: () => "",
      );
});
class OpenIdTokenProvider
    extends StateNotifier<AsyncValue<Map<String, String>>> {
  final OpenIdRepository openIdRepository = OpenIdRepository();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String tokenName = "my_ecl_auth_token";
  final String clientId = "ChronoRaid";
  final String tokenKey = "token";
  final String refreshTokenKey = "refresh_token";
  final List<String> scopes = ["API"];
  final FlutterAppAuth appAuth = const FlutterAppAuth();
  final String redirectUrl = "chronoraid://authorized";   // TODO :
  final String redirectUrlHost = InternetAddress.loopbackIPv4.address;
  final int redirectUrlPort = 8001;
  final String discoveryUrl =
      "${Repository.host}.well-known/openid-configuration";
  OpenIdTokenProvider() : super(const AsyncValue.loading());

  String generateRandomString(int len) {
    var r = Random.secure();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
  }

  String hash(String codeVerifier) {
    var bytes = utf8.encode(codeVerifier);
    var digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<void> getTokenFromRequest() async {
    try {
      if (kIsDesktop) {
        final redirectUri = Uri(
          scheme: "http",
          host: redirectUrlHost,
          port: redirectUrlPort,
          path: "/static.html",
        );
        final codeVerifier = generateRandomString(128);
        final codeChallenge = hash(codeVerifier);

        startLocalServer(redirectUri.toString(), redirectUrlHost, redirectUrlPort, codeVerifier);

        final Uri monUrl = Uri.parse("${Repository.host}auth/authorize?client_id=$clientId&response_type=code&scope=API&redirect_uri=http://$redirectUrlHost:$redirectUrlPort/static.html&code_challenge=$codeChallenge&code_challenge_method=S256");

        
        if (await canLaunchUrl(monUrl)) {
          await launchUrl(monUrl, mode: LaunchMode.externalApplication);
        } else {
          print("Impossible d'ouvrir l'URL : $monUrl");
        }
      } else {
        AuthorizationTokenResponse resp =
            await appAuth.authorizeAndExchangeCode(
          AuthorizationTokenRequest(
            clientId,
            redirectUrl,
            discoveryUrl: discoveryUrl,
            scopes: scopes,
            allowInsecureConnections: kDebugMode,
          ),
        );
        await _secureStorage.write(key: tokenName, value: resp.refreshToken);
        state = AsyncValue.data({
          tokenKey: resp.accessToken!,
          refreshTokenKey: resp.refreshToken!,
        });
      }
    } catch (e) {
      state = AsyncValue.error("Error $e", StackTrace.empty);
    }
  }

  void startLocalServer(String redirectUri, String redirectUrlHost, int redirectUrlPort, String codeVerifier) async {
    final server = await HttpServer.bind(InternetAddress(redirectUrlHost), redirectUrlPort);
    print("Serveur local démarré : $redirectUrlHost:$redirectUrlPort");

    await for (HttpRequest request in server) {
      final uri = request.uri;
      if (uri.path == "/static.html" && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code'] ?? "";
        print("Code reçu : $code");
        _exchangeCodeForToken(code, redirectUri, codeVerifier);

        // Réponse HTML affichée dans le navigateur
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('<html><head><title>Connexion réussie</title></head><body>Connexion réussie. Vous pouvez fermer cette fenêtre.</body></html>');
        await request.response.close();

        // Arrêter le serveur après réception du code
        await server.close();
        print("Serveur local arrêté.");
        break; // Sortir de la boucle après traitement
      }
    }
  }

  Future<void> _exchangeCodeForToken(String code, String redirectUri, String codeVerifier) async {
    try {
      final resp = await openIdRepository.getToken(
        code,
        clientId,
        redirectUri,
        codeVerifier,
        "authorization_code",
      );
      final accessToken = resp[tokenKey]!;
      final refreshToken = resp[refreshTokenKey]!;

      await _secureStorage.write(key: tokenName, value: refreshToken);
      state = AsyncValue.data({
        tokenKey: accessToken,
        refreshTokenKey: refreshToken,
      });

      print("Access Token : $accessToken");
      print("Refresh Token : $refreshToken");
    } catch (e) {
      print("Erreur lors de l'échange du code : $e");
    }
  }

  Future getTokenFromStorage() async {
    state = const AsyncValue.loading();
    _secureStorage.read(key: tokenName).then((token) async {
      if (token != null) {
        try {
          if (kIsDesktop) {
            final resp = await openIdRepository.getToken(
              token,
              clientId,
              "",
              "",
              refreshTokenKey,
            );
            final accessToken = resp[tokenKey]!;
            final refreshToken = resp[refreshTokenKey]!;
            await _secureStorage.write(key: tokenName, value: refreshToken);
            state = AsyncValue.data({
              tokenKey: accessToken,
              refreshTokenKey: refreshToken,
            });
          } else {
            final resp = await appAuth.token(
              TokenRequest(
                clientId,
                redirectUrl,
                discoveryUrl: discoveryUrl,
                scopes: scopes,
                refreshToken: token,
                allowInsecureConnections: kDebugMode,
              ),
            );
            state = AsyncValue.data({
              tokenKey: resp.accessToken!,
              refreshTokenKey: resp.refreshToken!,
            });
            storeToken();
          }
        } catch (e) {
          state = AsyncValue.error(e, StackTrace.empty);
        }
      } else {
        state = const AsyncValue.error("No token found", StackTrace.empty);
      }
    });
  }

  Future<void> getAuthToken(String authorizationToken) async {
    appAuth
        .token(
      TokenRequest(
        clientId,
        redirectUrl,
        discoveryUrl: discoveryUrl,
        scopes: scopes,
        authorizationCode: authorizationToken,
        allowInsecureConnections: kDebugMode,
      ),
    )
        .then((resp) {
      state = AsyncValue.data({
        tokenKey: resp.accessToken!,
        refreshTokenKey: resp.refreshToken!,
      });
    });
  }

  Future<bool> refreshToken() async {
    return state.when(
      data: (token) async {
        if (token[refreshTokenKey] != null && token[refreshTokenKey] != "") {
          TokenResponse? resp = await appAuth.token(
            TokenRequest(
              clientId,
              redirectUrl,
              discoveryUrl: discoveryUrl,
              scopes: scopes,
              refreshToken: token[refreshTokenKey] as String,
              allowInsecureConnections: kDebugMode,
            ),
          );
          state = AsyncValue.data({
            tokenKey: resp.accessToken!,
            refreshTokenKey: resp.refreshToken!,
          });
          storeToken();
          return true;
        }
        state = const AsyncValue.error(e, StackTrace.empty);
        return false;
      },
      error: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
        return false;
      },
      loading: () {
        return false;
      },
    );
  }

  void storeToken() {
    state.when(
      data: (tokens) => _secureStorage.write(
        key: tokenName,
        value: tokens[refreshTokenKey],
      ),
      error: (e, s) {
        throw e;
      },
      loading: () {
        throw Exception("Token is not loaded");
      },
    );
  }

  void deleteToken() {
    try {
      _secureStorage.delete(key: tokenName);
      state = AsyncValue.data({tokenKey: "", refreshTokenKey: ""});
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.empty);
    }
  }
}
