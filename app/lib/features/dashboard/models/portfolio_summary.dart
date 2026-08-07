import 'package:equatable/equatable.dart';

/// immutable snapshot of the balance data returned by api
class PortfolioSummary extends Equatable {
  const PortfolioSummary({
    required this.currency,
    required this.netPortfolioValue,
    required this.dailyReturnAmount,
    required this.dailyReturnPercentage,
  });

  final String currency;
  final double netPortfolioValue;
  final double dailyReturnAmount;
  final double dailyReturnPercentage;

  /// network response untrusted input; narrow with pattern matching to ensure correct types
  static PortfolioSummary? fromJson(Object? json) {
    if (json case {
      'currency': final String currency,
      'netPortfolioValue': final num netPortfolioValue,
      'dailyReturnAmount': final num dailyReturnAmount,
      'dailyReturnPercentage': final num dailyReturnPercentage,
    }) {
      return PortfolioSummary(
        currency: currency,
        netPortfolioValue: netPortfolioValue.toDouble(),
        dailyReturnAmount: dailyReturnAmount.toDouble(),
        dailyReturnPercentage: dailyReturnPercentage.toDouble(),
      );
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    currency,
    netPortfolioValue,
    dailyReturnAmount,
    dailyReturnPercentage,
  ];
}
