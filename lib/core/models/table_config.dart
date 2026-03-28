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

  // ── Details spoiler — Rifle section ───────────────────────────────────────
  final bool spoilerShowRifle;
  final bool spoilerShowCaliber;
  final bool spoilerShowTwist;
  final bool spoilerShowTwistDir;

  // ── Details spoiler — Projectile section ──────────────────────────────────
  final bool spoilerShowProjectile;
  final bool spoilerShowDragModel;
  final bool spoilerShowBc;
  final bool spoilerShowZeroMv;
  final bool spoilerShowCurrMv;
  final bool spoilerShowZeroDist;
  final bool spoilerShowBulletLen;
  final bool spoilerShowBulletDiam;
  final bool spoilerShowBulletWeight;

  /// Form-factor (FF = SD / BC)
  final bool spoilerShowFormFactor;

  /// Sectional density (SD = weight / diameter²)
  final bool spoilerShowSectionalDensity;

  /// Gyroscopic stability factor (Sg, Miller formula)
  final bool spoilerShowGyroStability;

  // ── Details spoiler — Atmosphere section ──────────────────────────────────
  final bool spoilerShowAtmo;
  final bool spoilerShowTemp;
  final bool spoilerShowHumidity;
  final bool spoilerShowPressure;
  final bool spoilerShowWindSpeed;
  final bool spoilerShowWindDir;

  // ── Columns ────────────────────────────────────────────────────────────────
  /// IDs of columns that are hidden. 'range' is always visible.
  /// Column IDs: time, velocity, height, drop, adjDrop, wind, adjWind,
  ///             mach, drag, energy
  final Set<String> hiddenCols;

  /// false = show adjustment in [adjUnit] only
  /// true  = show one column per adjustment unit enabled in Adjustment Display
  final bool adjAllUnits;

  /// Override drop/windage unit for this table; null = use global unit.
  final Unit? dropUnit;

  /// Override adjustment unit for this table; null = use global unit.
  final Unit? adjUnit;

  const TableConfig({
    this.startM = 0,
    this.endM = 2000,
    this.stepM = 100,
    this.showZeros = true,
    this.showSubsonicTransition = false,
    this.spoilerShowRifle = true,
    this.spoilerShowCaliber = true,
    this.spoilerShowTwist = true,
    this.spoilerShowTwistDir = true,
    this.spoilerShowProjectile = true,
    this.spoilerShowDragModel = true,
    this.spoilerShowBc = true,
    this.spoilerShowZeroMv = true,
    this.spoilerShowCurrMv = true,
    this.spoilerShowZeroDist = true,
    this.spoilerShowBulletLen = true,
    this.spoilerShowBulletDiam = true,
    this.spoilerShowBulletWeight = true,
    this.spoilerShowFormFactor = false,
    this.spoilerShowSectionalDensity = false,
    this.spoilerShowGyroStability = false,
    this.spoilerShowAtmo = true,
    this.spoilerShowTemp = true,
    this.spoilerShowHumidity = true,
    this.spoilerShowPressure = true,
    this.spoilerShowWindSpeed = true,
    this.spoilerShowWindDir = true,
    this.hiddenCols = const {},
    this.adjAllUnits = false,
    this.dropUnit,
    this.adjUnit,
  });

  TableConfig copyWith({
    double? startM,
    double? endM,
    double? stepM,
    bool? showZeros,
    bool? showSubsonicTransition,
    bool? spoilerShowRifle,
    bool? spoilerShowCaliber,
    bool? spoilerShowTwist,
    bool? spoilerShowTwistDir,
    bool? spoilerShowProjectile,
    bool? spoilerShowDragModel,
    bool? spoilerShowBc,
    bool? spoilerShowZeroMv,
    bool? spoilerShowCurrMv,
    bool? spoilerShowZeroDist,
    bool? spoilerShowBulletLen,
    bool? spoilerShowBulletDiam,
    bool? spoilerShowBulletWeight,
    bool? spoilerShowFormFactor,
    bool? spoilerShowSectionalDensity,
    bool? spoilerShowGyroStability,
    bool? spoilerShowAtmo,
    bool? spoilerShowTemp,
    bool? spoilerShowHumidity,
    bool? spoilerShowPressure,
    bool? spoilerShowWindSpeed,
    bool? spoilerShowWindDir,
    Set<String>? hiddenCols,
    bool? adjAllUnits,
    Unit? dropUnit,
    Unit? adjUnit,
  }) {
    return TableConfig(
      startM: startM ?? this.startM,
      endM: endM ?? this.endM,
      stepM: stepM ?? this.stepM,
      showZeros: showZeros ?? this.showZeros,
      showSubsonicTransition:
          showSubsonicTransition ?? this.showSubsonicTransition,
      spoilerShowRifle: spoilerShowRifle ?? this.spoilerShowRifle,
      spoilerShowCaliber: spoilerShowCaliber ?? this.spoilerShowCaliber,
      spoilerShowTwist: spoilerShowTwist ?? this.spoilerShowTwist,
      spoilerShowTwistDir: spoilerShowTwistDir ?? this.spoilerShowTwistDir,
      spoilerShowProjectile:
          spoilerShowProjectile ?? this.spoilerShowProjectile,
      spoilerShowDragModel: spoilerShowDragModel ?? this.spoilerShowDragModel,
      spoilerShowBc: spoilerShowBc ?? this.spoilerShowBc,
      spoilerShowZeroMv: spoilerShowZeroMv ?? this.spoilerShowZeroMv,
      spoilerShowCurrMv: spoilerShowCurrMv ?? this.spoilerShowCurrMv,
      spoilerShowZeroDist: spoilerShowZeroDist ?? this.spoilerShowZeroDist,
      spoilerShowBulletLen: spoilerShowBulletLen ?? this.spoilerShowBulletLen,
      spoilerShowBulletDiam:
          spoilerShowBulletDiam ?? this.spoilerShowBulletDiam,
      spoilerShowBulletWeight:
          spoilerShowBulletWeight ?? this.spoilerShowBulletWeight,
      spoilerShowFormFactor:
          spoilerShowFormFactor ?? this.spoilerShowFormFactor,
      spoilerShowSectionalDensity:
          spoilerShowSectionalDensity ?? this.spoilerShowSectionalDensity,
      spoilerShowGyroStability:
          spoilerShowGyroStability ?? this.spoilerShowGyroStability,
      spoilerShowAtmo: spoilerShowAtmo ?? this.spoilerShowAtmo,
      spoilerShowTemp: spoilerShowTemp ?? this.spoilerShowTemp,
      spoilerShowHumidity: spoilerShowHumidity ?? this.spoilerShowHumidity,
      spoilerShowPressure: spoilerShowPressure ?? this.spoilerShowPressure,
      spoilerShowWindSpeed: spoilerShowWindSpeed ?? this.spoilerShowWindSpeed,
      spoilerShowWindDir: spoilerShowWindDir ?? this.spoilerShowWindDir,
      hiddenCols: hiddenCols ?? this.hiddenCols,
      adjAllUnits: adjAllUnits ?? this.adjAllUnits,
      dropUnit: dropUnit ?? this.dropUnit,
      adjUnit: adjUnit ?? this.adjUnit,
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'startM': startM,
    'endM': endM,
    'stepM': stepM,
    'showZeros': showZeros,
    'showSubsonicTransition': showSubsonicTransition,
    'spoilerShowRifle': spoilerShowRifle,
    'spoilerShowCaliber': spoilerShowCaliber,
    'spoilerShowTwist': spoilerShowTwist,
    'spoilerShowTwistDir': spoilerShowTwistDir,
    'spoilerShowProjectile': spoilerShowProjectile,
    'spoilerShowDragModel': spoilerShowDragModel,
    'spoilerShowBc': spoilerShowBc,
    'spoilerShowZeroMv': spoilerShowZeroMv,
    'spoilerShowCurrMv': spoilerShowCurrMv,
    'spoilerShowZeroDist': spoilerShowZeroDist,
    'spoilerShowBulletLen': spoilerShowBulletLen,
    'spoilerShowBulletDiam': spoilerShowBulletDiam,
    'spoilerShowBulletWeight': spoilerShowBulletWeight,
    'spoilerShowFormFactor': spoilerShowFormFactor,
    'spoilerShowSectionalDensity': spoilerShowSectionalDensity,
    'spoilerShowGyroStability': spoilerShowGyroStability,
    'spoilerShowAtmo': spoilerShowAtmo,
    'spoilerShowTemp': spoilerShowTemp,
    'spoilerShowHumidity': spoilerShowHumidity,
    'spoilerShowPressure': spoilerShowPressure,
    'spoilerShowWindSpeed': spoilerShowWindSpeed,
    'spoilerShowWindDir': spoilerShowWindDir,
    'hiddenCols': hiddenCols.toList(),
    'adjAllUnits': adjAllUnits,
    'dropUnit': dropUnit?.name,
    'adjUnit': adjUnit?.name,
  };

  factory TableConfig.fromJson(Map<String, dynamic> json) {
    bool b(String key, bool def) => json[key] as bool? ?? def;
    double d(String key, double default_) {
      return (json[key] as num?)?.toDouble() ?? default_;
    }

    Unit? u(String key) {
      final name = json[key] as String?;
      if (name == null) return null;
      return .fromName(name) ?? Unit.mil;
    }

    return TableConfig(
      startM: d('startM', 0),
      endM: d('endM', 2000),
      stepM: d('stepM', 100),
      showZeros: b('showZeros', true),
      showSubsonicTransition: b('showSubsonicTransition', false),
      spoilerShowRifle: b('spoilerShowRifle', true),
      spoilerShowCaliber: b('spoilerShowCaliber', true),
      spoilerShowTwist: b('spoilerShowTwist', true),
      spoilerShowTwistDir: b('spoilerShowTwistDir', true),
      spoilerShowProjectile: b('spoilerShowProjectile', true),
      spoilerShowDragModel: b('spoilerShowDragModel', true),
      spoilerShowBc: b('spoilerShowBc', true),
      spoilerShowZeroMv: b('spoilerShowZeroMv', true),
      spoilerShowCurrMv: b('spoilerShowCurrMv', true),
      spoilerShowZeroDist: b('spoilerShowZeroDist', true),
      spoilerShowBulletLen: b('spoilerShowBulletLen', true),
      spoilerShowBulletDiam: b('spoilerShowBulletDiam', true),
      spoilerShowBulletWeight: b('spoilerShowBulletWeight', true),
      spoilerShowFormFactor: b('spoilerShowFormFactor', false),
      spoilerShowSectionalDensity: b('spoilerShowSectionalDensity', false),
      spoilerShowGyroStability: b('spoilerShowGyroStability', false),
      spoilerShowAtmo: b('spoilerShowAtmo', true),
      spoilerShowTemp: b('spoilerShowTemp', true),
      spoilerShowHumidity: b('spoilerShowHumidity', true),
      spoilerShowPressure: b('spoilerShowPressure', true),
      spoilerShowWindSpeed: b('spoilerShowWindSpeed', true),
      spoilerShowWindDir: b('spoilerShowWindDir', true),
      hiddenCols: Set<String>.from(json['hiddenCols'] as List? ?? []),
      adjAllUnits: b('adjAllUnits', false),
      dropUnit: u('dropUnit'),
      adjUnit: u('adjUnit'),
    );
  }
}
