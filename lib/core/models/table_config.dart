import 'package:eballistica/core/solver/unit.dart';

// ─── Table Configuration Model ────────────────────────────────────────────────
//
// Serialised inside AppSettings as 'tableConfig'.
// Controls the trajectory table's range, visible columns and details spoiler.

class TableConfig {
  // ── Range ──────────────────────────────────────────────────────────────────
  final double startM; // start distance, metres
  final double endM; // end distance,   metres
  final double stepM; // distance step,  metres

  // ── Extra tables ───────────────────────────────────────────────────────────
  final bool showZeros; // small zero-crossing table above main table
  final bool showSubsonicTransition; // highlight first subsonic row

  // ── Columns ────────────────────────────────────────────────────────────────
  /// IDs of columns that are hidden. 'range' is always visible.
  /// Column IDs: time, velocity, height, drop, wind, mach, drag, energy
  final Set<String> hiddenCols;

  // ── Adjustment unit columns ────────────────────────────────────────────────
  // Each flag enables one pair of adjustment columns (Drop° + Wind° for that unit).
  // Drop/Windage distance unit always comes from AppSettings.units.drop.
  final bool tableShowMrad;
  final bool tableShowMoa;
  final bool tableShowMil;
  final bool tableShowCmPer100m;
  final bool tableShowInPer100yd;

  const TableConfig({
    this.startM = 0,
    this.endM = 2000,
    this.stepM = 100,
    this.showZeros = true,
    this.showSubsonicTransition = false,
    this.hiddenCols = const {},
    this.tableShowMrad = true,
    this.tableShowMoa = false,
    this.tableShowMil = false,
    this.tableShowCmPer100m = false,
    this.tableShowInPer100yd = false,
  });

  /// Adjustment units enabled for this table.
  List<Unit> get enabledAdjUnits => [
    if (tableShowMrad) Unit.mRad,
    if (tableShowMoa) Unit.moa,
    if (tableShowMil) Unit.mil,
    if (tableShowCmPer100m) Unit.cmPer100m,
    if (tableShowInPer100yd) Unit.inPer100Yd,
  ];

  TableConfig copyWith({
    double? startM,
    double? endM,
    double? stepM,
    bool? showZeros,
    bool? showSubsonicTransition,
    Set<String>? hiddenCols,
    bool? tableShowMrad,
    bool? tableShowMoa,
    bool? tableShowMil,
    bool? tableShowCmPer100m,
    bool? tableShowInPer100yd,
  }) {
    return TableConfig(
      startM: startM ?? this.startM,
      endM: endM ?? this.endM,
      stepM: stepM ?? this.stepM,
      showZeros: showZeros ?? this.showZeros,
      showSubsonicTransition:
          showSubsonicTransition ?? this.showSubsonicTransition,
      hiddenCols: hiddenCols ?? this.hiddenCols,
      tableShowMrad: tableShowMrad ?? this.tableShowMrad,
      tableShowMoa: tableShowMoa ?? this.tableShowMoa,
      tableShowMil: tableShowMil ?? this.tableShowMil,
      tableShowCmPer100m: tableShowCmPer100m ?? this.tableShowCmPer100m,
      tableShowInPer100yd: tableShowInPer100yd ?? this.tableShowInPer100yd,
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'startM': startM,
    'endM': endM,
    'stepM': stepM,
    'showZeros': showZeros,
    'showSubsonicTransition': showSubsonicTransition,
    'hiddenCols': hiddenCols.toList(),
    'tableShowMrad': tableShowMrad,
    'tableShowMoa': tableShowMoa,
    'tableShowMil': tableShowMil,
    'tableShowCmPer100m': tableShowCmPer100m,
    'tableShowInPer100yd': tableShowInPer100yd,
  };

  factory TableConfig.fromJson(Map<String, dynamic> json) {
    bool b(String key, bool def) => json[key] as bool? ?? def;
    double d(String key, double default_) {
      return (json[key] as num?)?.toDouble() ?? default_;
    }

    return TableConfig(
      startM: d('startM', 0),
      endM: d('endM', 2000),
      stepM: d('stepM', 100),
      showZeros: b('showZeros', true),
      showSubsonicTransition: b('showSubsonicTransition', false),
      hiddenCols: Set<String>.from(json['hiddenCols'] as List? ?? []),
      tableShowMrad: b('tableShowMrad', true),
      tableShowMoa: b('tableShowMoa', false),
      tableShowMil: b('tableShowMil', false),
      tableShowCmPer100m: b('tableShowCmPer100m', false),
      tableShowInPer100yd: b('tableShowInPer100yd', false),
    );
  }
}
