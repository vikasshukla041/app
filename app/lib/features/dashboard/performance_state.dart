import 'package:equatable/equatable.dart';

import 'domain/performance_range.dart';
import 'models/performance_history.dart';

export 'domain/performance_range.dart';

/// State of the performance chart; every state knows its range so the buttons stay in sync.
sealed class PerformanceState extends Equatable {
  const PerformanceState(this.range);

  final PerformanceRange range;

  @override
  List<Object?> get props => <Object?>[range];
}

final class PerformanceLoading extends PerformanceState {
  const PerformanceLoading(super.range);
}

final class PerformanceLoaded extends PerformanceState {
  PerformanceLoaded(this.history) : super(history.range);

  final PerformanceHistory history;

  @override
  List<Object?> get props => <Object?>[range, history];
}

final class PerformanceError extends PerformanceState {
  const PerformanceError(super.range);
}
