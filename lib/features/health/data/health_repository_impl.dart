import 'dart:async';

import 'package:lifeos/features/health/domain/entities/health_day.dart';
import 'package:lifeos/features/health/domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl(HealthDay seed, {this.onChanged}) : _today = seed;

  HealthDay _today;
  final void Function(HealthDay day)? onChanged;
  final StreamController<HealthDay> _controller =
      StreamController<HealthDay>.broadcast();

  @override
  HealthDay today() => _today;

  @override
  void update(HealthDay day) {
    _today = day;
    if (!_controller.isClosed) _controller.add(_today);
    onChanged?.call(_today);
  }

  @override
  Stream<HealthDay> watchToday() async* {
    yield _today;
    yield* _controller.stream;
  }

  Future<void> dispose() => _controller.close();
}
