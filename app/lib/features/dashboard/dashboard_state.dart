import 'package:equatable/equatable.dart';

import 'models/portfolio_summary.dart';

/// State for loading the dashboard's portfolio balance.
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => <Object?>[];
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.summary);

  final PortfolioSummary summary;

  @override
  List<Object?> get props => <Object?>[summary];
}

class DashboardError extends DashboardState {
  const DashboardError();
}
