import 'package:eballistica/core/models/conditions_data.dart';
import 'package:eballistica/core/providers/storage_provider.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShotConditionsNotifier extends AsyncNotifier<Conditions> {
  @override
  Future<Conditions> build() async {
    final storage = ref.read(appStorageProvider);
    final conditions = await storage.loadConditions();

    Conditions loaded = conditions ?? Conditions.withDefaults();
    final laDeg = loaded.lookAngle.in_(Unit.degree);
    if (laDeg.abs() > 45) {
      loaded = loaded.copyWith(lookAngle: Angular(0.0, Unit.degree));
    }

    return loaded;
  }

  Future<void> updateAtmo(AtmoData atmo) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(atmo: atmo));
  }

  Future<void> updateWinds(List<WindData> winds) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(winds: winds));
  }

  Future<void> updateLookAngle(double degrees) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(lookAngle: Angular(degrees, Unit.degree)));
  }

  Future<void> updateTargetDistance(double meters) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(distance: Distance(meters, Unit.meter)));
  }

  Future<void> updateUsePowderSensitivity(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(usePowderSensitivity: value));
  }

  Future<void> updateUseDiffPowderTemp(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(useDiffPowderTemp: value));
  }

  Future<void> updateUseCoriolis(bool value) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(useCoriolis: value));
  }

  Future<void> updateLatitude(double? degrees) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(latitudeDeg: degrees));
  }

  Future<void> updateAzimuth(double? degrees) async {
    final current = state.value;
    if (current == null) return;
    await _save(current.copyWith(azimuthDeg: degrees));
  }

  Future<void> updateWindSpeed(double mps) async {
    final current = state.value;
    if (current == null) return;

    final existing = current.winds;
    final dir = existing.isNotEmpty
        ? existing.first.directionFrom
        : Angular(0.0, Unit.degree);
    final until = existing.isNotEmpty
        ? existing.first.untilDistance
        : Distance(9999.0, Unit.meter);

    await _save(
      current.copyWith(
        winds: [
          WindData(
            velocity: Velocity(mps, Unit.mps),
            directionFrom: dir,
            untilDistance: until,
          ),
        ],
      ),
    );
  }

  Future<void> _save(Conditions c) async {
    state = AsyncData(c);
    await ref.read(appStorageProvider).saveConditions(c);
  }
}

final shotConditionsProvider =
    AsyncNotifierProvider<ShotConditionsNotifier, Conditions>(
      ShotConditionsNotifier.new,
    );
