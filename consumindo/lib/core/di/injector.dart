import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/book/data/datasources/book_local_datasource.dart';
import '../../features/book/data/datasources/book_local_datasource_impl.dart';
import '../../features/book/data/datasources/book_remote_datasource.dart';
import '../../features/book/data/datasources/book_remote_datasource_impl.dart';
import '../../features/book/data/repositories/book_repository_impl.dart';
import '../../features/book/data/repositories/favorite_repository_impl.dart';
import '../../features/book/domain/repositories/book_repository.dart';
import '../../features/book/domain/usecases/get_book_detail.dart';
import '../../features/book/domain/usecases/get_favorites.dart';
import '../../features/book/domain/usecases/is_favorite.dart';
import '../../features/book/domain/usecases/search_books.dart';
import '../../features/book/domain/usecases/toggle_favorite.dart';
import '../config/app_config.dart';
import '../network/http_client.dart';
import '../network/http_client_impl.dart';

/// Service locator da aplicação.
final GetIt sl = GetIt.instance;

/// Registra as dependências de fora para dentro: infra → data → domain.
///
/// Todo registro é feito **pela interface**, nunca pela implementação: as
/// camadas de cima dependem de abstrações (DIP).
Future<void> setupInjector(AppConfig config) async {
  // --- Externo ---------------------------------------------------------------
  sl.registerSingleton<AppConfig>(config);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerLazySingleton<IHttpClient>(() => HttpClientImpl(config: sl<AppConfig>()));

  // --- Data ------------------------------------------------------------------
  sl.registerLazySingleton<IBookRemoteDataSource>(
    () => BookRemoteDataSourceImpl(sl<IHttpClient>()),
  );
  sl.registerLazySingleton<IBookLocalDataSource>(
    () => BookLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<IBookRepository>(
    () => BookRepositoryImpl(sl<IBookRemoteDataSource>()),
  );
  sl.registerLazySingleton<IFavoriteRepository>(
    () => FavoriteRepositoryImpl(sl<IBookLocalDataSource>()),
  );

  // --- Domain (casos de uso) -------------------------------------------------
  sl.registerLazySingleton<SearchBooks>(() => SearchBooks(sl<IBookRepository>()));
  sl.registerLazySingleton<GetBookDetail>(() => GetBookDetail(sl<IBookRepository>()));
  sl.registerLazySingleton<GetFavorites>(() => GetFavorites(sl<IFavoriteRepository>()));
  sl.registerLazySingleton<ToggleFavorite>(() => ToggleFavorite(sl<IFavoriteRepository>()));
  sl.registerLazySingleton<IsFavorite>(() => IsFavorite(sl<IFavoriteRepository>()));
}

/// Útil em testes: derruba tudo que foi registrado.
Future<void> resetInjector() async {
  if (sl.isRegistered<IHttpClient>()) sl<IHttpClient>().dispose();
  await sl.reset();
}
