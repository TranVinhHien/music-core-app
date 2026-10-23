import '../../../../core/result.dart';
import '../../domain/entities/transition_plan.dart';
import '../../domain/repositories/transition_repository.dart';
import '../datasources/transition_api_service.dart';

class TransitionRepositoryImpl implements TransitionRepository {
  const TransitionRepositoryImpl(this._remoteDataSource);

  final TransitionRemoteDataSource _remoteDataSource;

  @override
  Future<Result<AutoDjTransitionResponse>> getNextTransition({
    required String currentTrackId,
    List<String>? excludeTrackIds,
    double temperature = 0.7,
  }) {
    return _remoteDataSource.getNextTransition(
      currentTrackId: currentTrackId,
      excludeTrackIds: excludeTrackIds,
      temperature: temperature,
    );
  }
}
