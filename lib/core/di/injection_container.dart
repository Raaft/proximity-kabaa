import 'package:get_it/get_it.dart';
import '../../features/mecca_proximity/data/datasources/location_service.dart';
import '../../features/mecca_proximity/data/repositories/location_repository_impl.dart';
import '../../features/mecca_proximity/domain/repositories/location_repository.dart';
import '../../features/mecca_proximity/domain/use_cases/compute_bearing_to_kaaba.dart';
import '../../features/mecca_proximity/domain/use_cases/compute_distance_to_kaaba.dart';
import '../../features/mecca_proximity/domain/use_cases/get_current_location.dart';
import '../../features/mecca_proximity/presentation/cubit/location_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<LocationService>(() => LocationService());

  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl<LocationService>()),
  );

  sl.registerLazySingleton(() => GetCurrentLocation(sl<LocationRepository>()));
  sl.registerLazySingleton(
    () => ComputeDistanceToKaaba(sl<LocationRepository>()),
  );
  sl.registerLazySingleton(
    () => ComputeBearingToKaaba(sl<LocationRepository>()),
  );

  sl.registerFactory(
    () => LocationCubit(
      getCurrentLocation: sl<GetCurrentLocation>(),
      computeDistanceToKaaba: sl<ComputeDistanceToKaaba>(),
      computeBearingToKaaba: sl<ComputeBearingToKaaba>(),
    ),
  );
}

