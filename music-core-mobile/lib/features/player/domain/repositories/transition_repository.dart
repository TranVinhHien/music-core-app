import '../../../../core/result.dart';
import '../entities/transition_plan.dart';

/// Contract for requesting intelligent seamless crossfade transition plans.
abstract interface class TransitionRepository {
  Future<Result<AutoDjTransitionResponse>> getNextTransition({
    required String currentTrackId,
    List<String>? excludeTrackIds,
    double temperature = 0.7,
  });
}
