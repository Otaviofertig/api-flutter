import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/disabled_auth_datasource.dart';
import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/session/auth_session_scope.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/send_password_reset.dart';
import '../../features/auth/domain/usecases/sign_in_with_email.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up_with_email.dart';
import '../../features/auth/domain/usecases/watch_auth_state.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/book/data/datasources/author_remote_datasource.dart';
import '../../features/book/data/datasources/author_remote_datasource_impl.dart';
import '../../features/book/data/datasources/book_local_datasource.dart';
import '../../features/book/data/datasources/book_local_datasource_impl.dart';
import '../../features/book/data/datasources/book_remote_datasource.dart';
import '../../features/book/data/datasources/book_remote_datasource_impl.dart';
import '../../features/book/data/repositories/author_repository_impl.dart';
import '../../features/book/data/repositories/book_repository_impl.dart';
import '../../features/book/data/repositories/favorite_repository_impl.dart';
import '../../features/book/domain/repositories/author_repository.dart';
import '../../features/book/domain/repositories/book_repository.dart';
import '../../features/book/domain/usecases/get_author.dart';
import '../../features/book/domain/usecases/get_author_works.dart';
import '../../features/book/domain/usecases/get_book_detail.dart';
import '../../features/book/domain/usecases/get_favorites.dart';
import '../../features/book/domain/usecases/get_reading_status.dart';
import '../../features/book/domain/usecases/get_trending_books.dart';
import '../../features/book/domain/usecases/search_books.dart';
import '../../features/book/domain/usecases/set_reading_status.dart';
import '../../features/book/domain/usecases/toggle_favorite.dart';
import '../config/app_config.dart';
import '../network/http_client.dart';
import '../network/http_client_impl.dart';
import '../session/session_scope.dart';
import '../theme/theme_controller.dart';
import '../theme/theme_preference.dart';

/// Service locator da aplicação.
final GetIt sl = GetIt.instance;

/// Registra as dependências de fora para dentro: infra → data → domain.
///
/// Todo registro é feito **pela interface**, nunca pela implementação: as
/// camadas de cima dependem de abstrações (DIP).
/// [isAuthEnabled] indica se o Firebase subiu; quando `false`, a autenticação
/// é registrada com um Null Object e o app funciona apenas com o acervo.
Future<void> setupInjector(AppConfig config, {bool isAuthEnabled = false}) async {
  // --- Externo ---------------------------------------------------------------
  sl.registerSingleton<AppConfig>(config);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerLazySingleton<IHttpClient>(() => HttpClientImpl(config: sl<AppConfig>()));

  // --- Tema ------------------------------------------------------------------
  // Preferência de app, não de feature: quem escuta é a raiz, acima das telas.
  sl.registerLazySingleton<IThemePreference>(
    () => SharedPreferencesThemePreference(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<ThemeController>(
    () => ThemeController(sl<IThemePreference>()),
    dispose: (ThemeController controller) => controller.dispose(),
  );

  // --- Data ------------------------------------------------------------------
  sl.registerLazySingleton<IBookRemoteDataSource>(
    () => BookRemoteDataSourceImpl(sl<IHttpClient>()),
  );
  // A estante é resolvida por conta: o escopo vem de `_registerAuth`.
  sl.registerLazySingleton<IBookLocalDataSource>(
    () => BookLocalDataSourceImpl(sl<SharedPreferences>(), sl<ISessionScope>()),
  );

  sl.registerLazySingleton<IAuthorRemoteDataSource>(
    () => AuthorRemoteDataSourceImpl(sl<IHttpClient>()),
  );

  sl.registerLazySingleton<IBookRepository>(
    () => BookRepositoryImpl(sl<IBookRemoteDataSource>()),
  );
  sl.registerLazySingleton<IAuthorRepository>(
    () => AuthorRepositoryImpl(sl<IAuthorRemoteDataSource>()),
  );
  sl.registerLazySingleton<IFavoriteRepository>(
    () => FavoriteRepositoryImpl(sl<IBookLocalDataSource>()),
  );

  // --- Domain (casos de uso) -------------------------------------------------
  sl.registerLazySingleton<SearchBooks>(() => SearchBooks(sl<IBookRepository>()));
  sl.registerLazySingleton<GetBookDetail>(() => GetBookDetail(sl<IBookRepository>()));
  sl.registerLazySingleton<GetTrendingBooks>(
    () => GetTrendingBooks(sl<IBookRepository>()),
  );
  sl.registerLazySingleton<GetAuthor>(() => GetAuthor(sl<IAuthorRepository>()));
  sl.registerLazySingleton<GetAuthorWorks>(
    () => GetAuthorWorks(sl<IAuthorRepository>()),
  );
  sl.registerLazySingleton<GetFavorites>(() => GetFavorites(sl<IFavoriteRepository>()));
  sl.registerLazySingleton<ToggleFavorite>(() => ToggleFavorite(sl<IFavoriteRepository>()));
  sl.registerLazySingleton<GetReadingStatus>(
    () => GetReadingStatus(sl<IFavoriteRepository>()),
  );
  sl.registerLazySingleton<SetReadingStatus>(
    () => SetReadingStatus(sl<IFavoriteRepository>()),
  );

  _registerAuth(isAuthEnabled: isAuthEnabled);
}

/// Módulo de autenticação. A única diferença entre "com" e "sem" Firebase
/// está na fonte de dados — todo o resto do grafo é idêntico.
void _registerAuth({required bool isAuthEnabled}) {
  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => isAuthEnabled
        ? FirebaseAuthDataSource(fb.FirebaseAuth.instance)
        : const DisabledAuthDataSource(),
  );

  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(sl<IAuthRemoteDataSource>()),
  );

  // Quem é o dono dos dados locais. Sem autenticação os dados pertencem ao
  // aparelho; com sessão, a cada conta a sua estante.
  sl.registerLazySingleton<ISessionScope>(
    () => isAuthEnabled
        ? AuthSessionScope(sl<IAuthRepository>())
        : const AnonymousSessionScope(),
  );

  sl.registerLazySingleton<SignInWithEmail>(() => SignInWithEmail(sl<IAuthRepository>()));
  sl.registerLazySingleton<SignUpWithEmail>(() => SignUpWithEmail(sl<IAuthRepository>()));
  sl.registerLazySingleton<SignInWithGoogle>(() => SignInWithGoogle(sl<IAuthRepository>()));
  sl.registerLazySingleton<SendPasswordReset>(
    () => SendPasswordReset(sl<IAuthRepository>()),
  );
  sl.registerLazySingleton<SignOut>(() => SignOut(sl<IAuthRepository>()));
  sl.registerLazySingleton<WatchAuthState>(() => WatchAuthState(sl<IAuthRepository>()));

  // A sessão é única no app inteiro e vive enquanto o processo existir.
  sl.registerLazySingleton<AuthController>(
    () => AuthController(sl<WatchAuthState>(), sl<SignOut>()),
    dispose: (AuthController controller) => controller.dispose(),
  );
}

/// Útil em testes: derruba tudo que foi registrado.
Future<void> resetInjector() async {
  if (sl.isRegistered<IHttpClient>()) sl<IHttpClient>().dispose();
  await sl.reset();
}
