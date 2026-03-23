// Default seed data derived from real .a7p profiles (a7p-lib/gallery/338LM/).
// All scaled integer values are converted to physical units as per the a7p spec:
//   bc_cd  / 10000 → G7 BC
//   mv     / 10    → m/s
//   b_weight  / 10    → grain
//   b_diameter / 1000 → inch
//   b_length   / 1000 → inch
//   sc_height  / 10   → mm
//   r_twist    / 100  → inch

import '../solver/conditions.dart';
import '../solver/drag_model.dart';
import '../solver/drag_tables.dart';
import '../solver/munition.dart';
import '../solver/unit.dart';
import 'cartridge.dart';
import 'projectile.dart';
import 'rifle.dart';
import 'shot_profile.dart';
import 'sight.dart';

// ── Rifle ─────────────────────────────────────────────────────────────────────
// Based on .338LM UKROP profile (sc_height=8.5mm, r_twist=10")

final seedRifle = Rifle(
  id: 'seed-rifle-338lm',
  name: '.338 Lapua Magnum',
  description: 'Generic .338LM platform',
  weapon: Weapon(
    sightHeight:   Distance(8.5,  Unit.millimeter),
    twist:         Distance(10.0, Unit.inch),
    zeroElevation: Angular(0.0,   Unit.radian),
  ),
);

// ── Sight ─────────────────────────────────────────────────────────────────────

final seedSight = Sight(
  id: 'seed-sight-generic',
  name: 'Generic Long-Range Scope',
  sightHeight:   Distance(0.0, Unit.millimeter),
  zeroElevation: Angular(0.0,  Unit.radian),
);

// ── Projectiles ───────────────────────────────────────────────────────────────
// 338LM_UKROP_250GR_SMK_G7 — single BC G7 0.314 @ 888 m/s

final _projUkrop250 = Projectile(
  id: 'seed-proj-ukrop-250-smk',
  name: 'UKROP 250GR SMK',
  manufacturer: 'Ukrop / Zbroyar',
  dragType: DragModelType.g7,
  dm: createDragModelMultiBC(
    bcPoints: [BCPoint(bc: 0.314, v: Velocity(888.0, Unit.mps))],
    dragTable: tableG7,
    weight:   Weight(250.0, Unit.grain),
    diameter: Distance(0.338, Unit.inch),
    length:   Distance(1.555, Unit.inch),
  ),
);

// 338LM_HORNADY_250GR_BTHP_G7 — single BC G7 0.322 @ 885 m/s

final _projHornady250 = Projectile(
  id: 'seed-proj-hornady-250-bthp',
  name: 'Hornady 250GR BTHP',
  manufacturer: 'Hornady',
  dragType: DragModelType.g7,
  dm: createDragModelMultiBC(
    bcPoints: [BCPoint(bc: 0.322, v: Velocity(885.0, Unit.mps))],
    dragTable: tableG7,
    weight:   Weight(250.0, Unit.grain),
    diameter: Distance(0.338, Unit.inch),
    length:   Distance(1.567, Unit.inch),
  ),
);

// 338LM_LAPUA_300GR_SMK_G7 — single BC G7 0.381 @ 825 m/s

final _projLapua300 = Projectile(
  id: 'seed-proj-lapua-300-smk',
  name: 'Lapua 300GR SMK',
  manufacturer: 'Lapua',
  dragType: DragModelType.g7,
  dm: createDragModelMultiBC(
    bcPoints: [BCPoint(bc: 0.381, v: Velocity(825.0, Unit.mps))],
    dragTable: tableG7,
    weight:   Weight(300.0, Unit.grain),
    diameter: Distance(0.338, Unit.inch),
    length:   Distance(1.700, Unit.inch),
  ),
);

// 338LM_STS_285GR_ELD_M_G7MBC — multi-BC G7

final _projSts285EldM = Projectile(
  id: 'seed-proj-sts-285-eld-m',
  name: 'Hornady 285GR ELD-M',
  manufacturer: 'Hornady / STS',
  dragType: DragModelType.g7,
  dm: createDragModelMultiBC(
    bcPoints: [
      BCPoint(bc: 0.417, v: Velocity(765.0, Unit.mps)),
      BCPoint(bc: 0.409, v: Velocity(680.0, Unit.mps)),
      BCPoint(bc: 0.400, v: Velocity(595.0, Unit.mps)),
    ],
    dragTable: tableG7,
    weight:   Weight(285.0, Unit.grain),
    diameter: Distance(0.338, Unit.inch),
    length:   Distance(1.746, Unit.inch),
  ),
);

// ── Cartridges ────────────────────────────────────────────────────────────────

final seedCartridgeUkrop250 = Cartridge(
  id: 'seed-cart-ukrop-250-smk',
  name: '.338LM UKROP 250GR SMK',
  projectile: _projUkrop250,
  mv:         Velocity(888.0, Unit.mps),
  powderTemp: Temperature(29.0, Unit.celsius),
);

final seedCartridgeHornady250 = Cartridge(
  id: 'seed-cart-hornady-250-bthp',
  name: '.338LM Hornady 250GR BTHP',
  projectile: _projHornady250,
  mv:         Velocity(885.0, Unit.mps),
  powderTemp: Temperature(15.0, Unit.celsius),
);

final seedCartridgeLapua300 = Cartridge(
  id: 'seed-cart-lapua-300-smk',
  name: '.338LM Lapua 300GR SMK',
  projectile: _projLapua300,
  mv:         Velocity(825.0, Unit.mps),
  powderTemp: Temperature(15.0, Unit.celsius),
);

final seedCartridgeSts285EldM = Cartridge(
  id: 'seed-cart-sts-285-eld-m',
  name: '.338LM Hornady 285GR ELD-M',
  projectile: _projSts285EldM,
  mv:         Velocity(810.0, Unit.mps),
  powderTemp: Temperature(15.0, Unit.celsius),
);

final seedCartridges = [
  seedCartridgeUkrop250,
  seedCartridgeHornady250,
  seedCartridgeLapua300,
  seedCartridgeSts285EldM,
];

// ── Default Shot Profile ──────────────────────────────────────────────────────

// Conditions extracted from the .a7p profile — these are the ZERO conditions
// (altitude, temperature, pressure, humidity at time of zeroing).
final _seedZeroConditions = Atmo(
  altitude:    Distance(0.0,    Unit.meter),
  temperature: Temperature(15.0, Unit.celsius),
  pressure:    Pressure(1000.0,  Unit.hPa),
  humidity:    0.50,
);

final seedShotProfile = ShotProfile(
  id: 'seed-profile-default',
  name: '.338LM UKROP 250GR SMK',
  rifle:          seedRifle,
  sight:          seedSight,
  cartridge:      seedCartridgeUkrop250,
  zeroConditions: _seedZeroConditions,  // from a7p — conditions at time of zeroing
  conditions:     _seedZeroConditions,  // current conditions start equal; user adjusts via Conditions screen
  winds: [],
  lookAngle: Angular(0.0, Unit.degree),
);
