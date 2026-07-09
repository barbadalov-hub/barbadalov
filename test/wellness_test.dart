import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/wellness/domain/cycle.dart';
import 'package:lifeos/features/wellness/domain/vitality.dart';

void main() {
  group('CyclePredictor', () {
    const predictor = CyclePredictor();
    final data =
        CycleData(lastPeriodStart: DateTime(2026, 7, 1)); // 28 / 5 defaults

    test('day 1 is menstrual with a 28-day forecast', () {
      final p = predictor.predict(data, DateTime(2026, 7, 1));
      expect(p.cycleDay, 1);
      expect(p.phase, CyclePhase.menstrual);
      expect(p.nextPeriodStart, DateTime(2026, 7, 29));
      expect(p.daysUntilNextPeriod, 28);
      expect(p.ovulationDate, DateTime(2026, 7, 15));
      expect(p.isFertile, isFalse);
    });

    test('ovulation day is flagged fertile', () {
      final p = predictor.predict(data, DateTime(2026, 7, 15));
      expect(p.cycleDay, 15);
      expect(p.phase, CyclePhase.ovulation);
      expect(p.isFertile, isTrue);
    });

    test('late cycle is luteal', () {
      final p = predictor.predict(data, DateTime(2026, 7, 20));
      expect(p.phase, CyclePhase.luteal);
      expect(p.daysUntilNextPeriod, 9);
    });

    test('rolls over to the next cycle without re-logging', () {
      // 35 days later → second cycle, which started on Jul 29.
      final p = predictor.predict(data, DateTime(2026, 8, 5));
      expect(p.cycleDay, 8);
      expect(p.nextPeriodStart, DateTime(2026, 8, 26));
    });
  });

  group('VitalityAnalyzer', () {
    const analyzer = VitalityAnalyzer();

    test('empty log returns null', () {
      expect(analyzer.summarize(const [], DateTime(2026, 7, 4)), isNull);
    });

    test('score, phase and streak from consecutive good days', () {
      final log = [
        for (var d = 2; d <= 4; d++)
          VitalityCheckin(
            date: DateTime(2026, 7, d),
            energy: 4,
            mood: 4,
            sleep: 4,
            libido: 4,
            stress: 2,
          ),
      ];
      final s = analyzer.summarize(log, DateTime(2026, 7, 4))!;
      // positives = 4+4+4+4+(6-2)=20 -> (20-5)/20*100 = 75
      expect(s.latestScore, 75);
      expect(s.phaseKey, 'vitality.phase.peak');
      expect(s.streakDays, 3);
    });

    test('detects a rising trend', () {
      VitalityCheckin at(int day, int lvl) => VitalityCheckin(
            date: DateTime(2026, 7, day),
            energy: lvl,
            mood: lvl,
            sleep: lvl,
            libido: lvl,
            stress: 6 - lvl,
          );
      final log = [at(1, 1), at(2, 1), at(3, 1), at(4, 5), at(5, 5), at(6, 5)];
      final s = analyzer.summarize(log, DateTime(2026, 7, 6))!;
      expect(s.trend, VitalityTrend.rising);
    });
  });
}
