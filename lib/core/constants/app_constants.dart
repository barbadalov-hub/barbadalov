/// System-wide constants and tunable business rules. Anything a product manager
/// might want to change lives here, never hard-coded deep in the logic.
library;

class AppConstants {
  const AppConstants._();

  static const String appName = 'Lumo';
  static const String defaultCurrency = 'USD';

  /// When false, every account starts with **zero activity** — no sample
  /// transactions, goals, health logs, pantry, habits, tasks or books. Each
  /// person enters their own data. Kept as a (non-const) field so flipping it
  /// to true restores the demo content for screenshots/testing without any
  /// dead-code warnings.
  static bool seedDemoData = false;

  // --- MoneyOS business rules --------------------------------------------
  /// Minimum share of income automatically set aside as reserve (10%).
  static const double minReserveRate = 0.10;

  /// Maximum share of income automatically set aside as reserve (20%).
  static const double maxReserveRate = 0.20;

  /// Default reserve rate applied until the user tunes it. Sits in the middle
  /// of the sanctioned 10–20% band.
  static const double defaultReserveRate = 0.15;

  // --- Life Score --------------------------------------------------------
  /// Weights of each pillar in the 0–100 Life Score. Must sum to 1.0.
  static const double financeWeight = 0.30;
  static const double healthWeight = 0.30;
  static const double disciplineWeight = 0.20;
  static const double productivityWeight = 0.20;
}
