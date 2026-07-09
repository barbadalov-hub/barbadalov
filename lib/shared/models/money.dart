import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:lifeos/core/constants/app_constants.dart';

/// Money is stored as an integer number of **minor units** (e.g. cents) to make
/// arithmetic exact. Never represent money with `double` in domain logic.
class Money extends Equatable {
  final int minorUnits;
  final String currency;

  const Money(this.minorUnits, {this.currency = AppConstants.defaultCurrency});

  const Money.zero({this.currency = AppConstants.defaultCurrency})
      : minorUnits = 0;

  /// Build from a major amount like `12.34` dollars.
  factory Money.fromMajor(
    num amount, {
    String currency = AppConstants.defaultCurrency,
  }) =>
      Money((amount * 100).round(), currency: currency);

  double get major => minorUnits / 100.0;
  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency: currency);
  }

  Money operator *(num factor) =>
      Money((minorUnits * factor).round(), currency: currency);

  bool operator >(Money other) => minorUnits > other.minorUnits;
  bool operator <(Money other) => minorUnits < other.minorUnits;
  bool operator >=(Money other) => minorUnits >= other.minorUnits;
  bool operator <=(Money other) => minorUnits <= other.minorUnits;

  /// Never below zero — handy for "safe to spend" style numbers.
  Money clampToZero() => isNegative ? Money.zero(currency: currency) : this;

  String format({String? locale}) => NumberFormat.simpleCurrency(
        locale: locale,
        name: currency,
      ).format(major);

  void _assertSameCurrency(Money other) {
    assert(
      currency == other.currency,
      'Cannot combine $currency with ${other.currency}. '
      'Multi-currency conversion is a later-phase feature.',
    );
  }

  @override
  List<Object?> get props => [minorUnits, currency];

  @override
  String toString() => format();
}
