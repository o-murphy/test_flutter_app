// Default seed data derived from real .a7p profiles (a7p-lib/gallery/338LM/).
// All scaled integer values are converted to physical units as per the a7p spec:
//   bc_cd  / 10000 → G7 BC
//   mv     / 10    → m/s
//   b_weight  / 10    → grain
//   b_diameter / 1000 → inch
//   b_length   / 1000 → inch
//   sc_height  / 10   → mm
//   r_twist    / 100  → inch

import 'package:eballistica/core/solver/unit.dart';
import 'cartridge.dart';
import 'conditions_data.dart';
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
  sightHeight: Distance(8.5, Unit.millimeter),
  twist: Distance(10.0, Unit.inch),
);

// ── Sight ─────────────────────────────────────────────────────────────────────

final seedSight = Sight(
  id: 'seed-sight-generic',
  name: 'Generic Long-Range Scope',
  sightHeight: Distance(0.0, Unit.millimeter),
  zeroElevation: Angular(0.0, Unit.radian),
);

// ── Projectiles ───────────────────────────────────────────────────────────────
// 338LM_UKROP_250GR_SMK_G7 — single BC G7 0.314 @ 888 m/s

final _projUkrop250 = Projectile(
  id: 'seed-proj-ukrop-250-smk',
  name: 'UKROP 250GR SMK',
  manufacturer: 'Ukrop / Zbroyar',
  dragType: DragModelType.g7,
  weight: Weight(250.0, Unit.grain),
  diameter: Distance(0.338, Unit.inch),
  length: Distance(1.555, Unit.inch),
  coefRows: [CoeficientRow(bcCd: 0.314, mv: 888.0)],
);

// 338LM_HORNADY_250GR_BTHP_G7 — single BC G7 0.322 @ 885 m/s

final _projHornady250 = Projectile(
  id: 'seed-proj-hornady-250-bthp',
  name: 'Hornady 250GR BTHP',
  manufacturer: 'Hornady',
  dragType: DragModelType.g7,
  weight: Weight(250.0, Unit.grain),
  diameter: Distance(0.338, Unit.inch),
  length: Distance(1.567, Unit.inch),
  coefRows: [CoeficientRow(bcCd: 0.322, mv: 885.0)],
);

// 338LM_LAPUA_300GR_SMK_G7 — single BC G7 0.381 @ 825 m/s

final _projLapua300 = Projectile(
  id: 'seed-proj-lapua-300-smk',
  name: 'Lapua 300GR SMK',
  manufacturer: 'Lapua',
  dragType: DragModelType.g7,
  weight: Weight(300.0, Unit.grain),
  diameter: Distance(0.338, Unit.inch),
  length: Distance(1.700, Unit.inch),
  coefRows: [CoeficientRow(bcCd: 0.381, mv: 825.0)],
);

// 338LM_STS_285GR_ELD_M_G7MBC — multi-BC G7

final _projSts285EldM = Projectile(
  id: 'seed-proj-sts-285-eld-m',
  name: 'Hornady 285GR ELD-M',
  manufacturer: 'Hornady / STS',
  dragType: DragModelType.g7,
  weight: Weight(285.0, Unit.grain),
  diameter: Distance(0.338, Unit.inch),
  length: Distance(1.746, Unit.inch),
  coefRows: [
    CoeficientRow(bcCd: 0.417, mv: 765.0),
    CoeficientRow(bcCd: 0.409, mv: 680.0),
    CoeficientRow(bcCd: 0.400, mv: 595.0),
  ],
);

// ── Cartridges ────────────────────────────────────────────────────────────────

final seedCartridgeUkrop250 = Cartridge(
  id: 'seed-cart-ukrop-250-smk',
  name: '.338LM UKROP 250GR SMK',
  projectile: _projUkrop250,
  mv: Velocity(888.0, Unit.mps),
  powderTemp: Temperature(29.0, Unit.celsius),
  powderSensitivity: Ratio(0.02, Unit.fraction),
  usePowderSensitivity: true,
);

final seedCartridgeHornady250 = Cartridge(
  id: 'seed-cart-hornady-250-bthp',
  name: '.338LM Hornady 250GR BTHP',
  projectile: _projHornady250,
  mv: Velocity(885.0, Unit.mps),
  powderTemp: Temperature(15.0, Unit.celsius),
  powderSensitivity: Ratio(0.02, Unit.fraction),
  usePowderSensitivity: true,
);

final seedCartridgeLapua300 = Cartridge(
  id: 'seed-cart-lapua-300-smk',
  name: '.338LM Lapua 300GR SMK',
  projectile: _projLapua300,
  mv: Velocity(825.0, Unit.mps),
  powderTemp: Temperature(15.0, Unit.celsius),
  powderSensitivity: Ratio(0.123, Unit.fraction),
  usePowderSensitivity: true,
);

final seedCartridgeSts285EldM = Cartridge(
  id: 'seed-cart-sts-285-eld-m',
  name: '.338LM Hornady 285GR ELD-M',
  projectile: _projSts285EldM,
  mv: Velocity(810.0, Unit.mps),
  powderTemp: Temperature(15.0, Unit.celsius),
  powderSensitivity: Ratio(0.02, Unit.fraction),
  usePowderSensitivity: true,
);

final seedCartridges = [
  seedCartridgeUkrop250,
  seedCartridgeHornady250,
  seedCartridgeLapua300,
  seedCartridgeSts285EldM,
];

// ── Default Shot Profiles ─────────────────────────────────────────────────────

final _seedZeroConditions = AtmoData(
  altitude: Distance(0.0, Unit.meter),
  temperature: Temperature(15.0, Unit.celsius),
  pressure: Pressure(1000.0, Unit.hPa),
  humidity: 0.02,
  powderTemp: Temperature(15.0, Unit.celsius),
);

final seedShotProfile = ShotProfile(
  id: 'seed-profile-default',
  name: '.338LM UKROP 250GR SMK',
  rifle: seedRifle,
  sight: seedSight,
  cartridge: seedCartridgeUkrop250,
  zeroConditions: _seedZeroConditions,
  conditions: _seedZeroConditions,
  winds: [],
  lookAngle: Angular(0.0, Unit.degree),
  usePowderSensitivity: true,
  useDiffPowderTemp: false,
  zeroUseDiffPowderTemp: false,
);

final seedShotProfileHornady = ShotProfile(
  id: 'seed-profile-hornady-250',
  name: '.338LM Hornady 250GR BTHP',
  rifle: seedRifle,
  sight: seedSight,
  cartridge: seedCartridgeHornady250,
  zeroConditions: _seedZeroConditions,
  conditions: _seedZeroConditions,
  winds: [],
  lookAngle: Angular(0.0, Unit.degree),
  usePowderSensitivity: true,
  useDiffPowderTemp: false,
  zeroUseDiffPowderTemp: false,
);

final seedShotProfileLapua300 = ShotProfile(
  id: 'seed-profile-lapua-300',
  name: '.338LM Lapua 300GR SMK',
  rifle: seedRifle,
  sight: seedSight,
  cartridge: seedCartridgeLapua300,
  zeroConditions: _seedZeroConditions,
  conditions: _seedZeroConditions,
  winds: [],
  lookAngle: Angular(0.0, Unit.degree),
  usePowderSensitivity: true,
  useDiffPowderTemp: false,
  zeroUseDiffPowderTemp: false,
);

final seedShotProfiles = [
  seedShotProfile,
  seedShotProfileHornady,
  seedShotProfileLapua300,
];
