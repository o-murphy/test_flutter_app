import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/models/rifle.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/info_tile.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';
import 'package:eballistica/shared/widgets/unit_constrained_input_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RifleWizardScreen extends ConsumerStatefulWidget {
  const RifleWizardScreen({this.initial, this.caliberEditable, super.key});

  /// Pre-fill the form with an existing rifle (edit / copy-from-collection).
  /// null = new empty rifle.
  final Rifle? initial;

  /// Whether the caliber diameter field is editable.
  /// Defaults to true when [initial] is null (manual create), false otherwise.
  final bool? caliberEditable;

  @override
  ConsumerState<RifleWizardScreen> createState() => _RifleWizardScreenState();
}

class _RifleWizardScreenState extends ConsumerState<RifleWizardScreen> {
  late final TextEditingController _nameCtrl;

  // ── Draft state (all raw values in FC rawUnits) ───────────────────────────
  // caliberDiameter: Unit.millimeter (FC.bulletDiameter)
  late double _caliberRaw;
  // sightHeight: Unit.millimeter (FC.sightHeight)
  late double _sightHeightRaw;
  // twist magnitude: Unit.inch (FC.twist) — always positive, direction via _rightHand
  late double _twistRaw;
  late bool _rightHand;
  // barrelLength: Unit.inch (FC.barrelLength) — null when not set
  bool _hasBarrelLength = false;
  late double? _barrelLengthRaw;

  String? _nameError;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _caliberRaw =
        r?.caliberDiameter?.in_(FC.bulletDiameter.rawUnit) ??
        FC.bulletDiameter.minRaw;
    _sightHeightRaw =
        r?.sightHeight.in_(FC.sightHeight.rawUnit) ?? FC.sightHeight.minRaw;
    _twistRaw = r != null
        ? r.twist.in_(FC.twist.rawUnit).abs()
        : FC.twist.minRaw;
    _rightHand = r?.isRightHandTwist ?? true;
    final bl = r?.barrelLength;
    _hasBarrelLength = bl != null;
    _barrelLengthRaw =
        bl?.in_(FC.barrelLength.rawUnit) ?? FC.barrelLength.minRaw;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool get _isValid => _nameCtrl.text.trim().isNotEmpty;

  void _validateName() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Name is required' : null;
    });
  }

  // ── Build result ──────────────────────────────────────────────────────────

  Rifle _buildRifle() {
    final signedTwist = _rightHand ? _twistRaw : -_twistRaw;
    return Rifle(
      id: widget.initial?.id,
      name: _nameCtrl.text.trim(),
      description: widget.initial?.description,
      sightHeight: Distance(_sightHeightRaw, FC.sightHeight.rawUnit),
      twist: Distance(signedTwist, FC.twist.rawUnit),
      caliberDiameter: Distance(_caliberRaw, FC.bulletDiameter.rawUnit),
      barrelLength: (_hasBarrelLength && _barrelLengthRaw != null)
          ? Distance(_barrelLengthRaw!, FC.barrelLength.rawUnit)
          : null,
      createdAt: widget.initial?.createdAt,
    );
  }

  void _onSave() {
    _validateName();
    if (!_isValid) return;
    context.pop(_buildRifle());
  }

  void _onDiscard() => context.pop(null);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitSettingsProvider);
    final fmt = ref.watch(unitFormatterProvider);
    final title = _nameCtrl.text.trim().isEmpty
        ? 'New Rifle'
        : _nameCtrl.text.trim();
    final caliberEditable = widget.caliberEditable ?? widget.initial == null;

    return BaseScreen(
      title: title,
      isSubscreen: true,
      showBack: false,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _RiflePlaceholder(),
                // ── Name ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Rifle name',
                      errorText: _nameError,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {
                      _nameError = null;
                    }),
                    onEditingComplete: _validateName,
                  ),
                ),
                // ── Ballistics ───────────────────────────────────────────────
                const ListSectionTile('Ballistics'),
                if (caliberEditable)
                  UnitValueFieldTile(
                    label: 'Caliber diameter',
                    rawValue: _caliberRaw,
                    constraints: FC.bulletDiameter,
                    displayUnit: units.diameter,
                    icon: Icons.circle_outlined,
                    onChanged: (v) => setState(() => _caliberRaw = v),
                  )
                else
                  InfoListTile(
                    label: 'Caliber diameter',
                    value: widget.initial?.caliberDiameter != null
                        ? fmt.diameter(widget.initial!.caliberDiameter!)
                        : '—',
                    icon: Icons.circle_outlined,
                  ),
                // ── Hardware ─────────────────────────────────────────────────
                const ListSectionTile('Hardware'),
                UnitValueFieldTile(
                  label: 'Sight height',
                  rawValue: _sightHeightRaw,
                  constraints: FC.sightHeight,
                  displayUnit: units.sightHeight,
                  icon: Icons.vertical_align_center_outlined,
                  onChanged: (v) => setState(() => _sightHeightRaw = v),
                ),
                UnitValueFieldTile(
                  label: 'Twist rate',
                  rawValue: _twistRaw,
                  constraints: FC.twist,
                  displayUnit: units.twist,
                  symbol: '1:${units.twist.symbol}',
                  icon: Icons.rotate_right_outlined,
                  onChanged: (v) => setState(() => _twistRaw = v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.swap_horiz_outlined, size: 20),
                  title: const Text('Twist direction'),
                  subtitle: Text(_rightHand ? 'Right hand' : 'Left hand'),
                  value: _rightHand,
                  onChanged: (v) => setState(() => _rightHand = v),
                  dense: true,
                ),
                // ── Barrel length (optional) ──────────────────────────────
                SwitchListTile(
                  secondary: const Icon(Icons.straighten_outlined, size: 20),
                  title: const Text('Barrel length'),
                  subtitle: Text(
                    _hasBarrelLength ? 'Specified' : 'Not specified',
                  ),
                  value: _hasBarrelLength,
                  onChanged: (v) => setState(() => _hasBarrelLength = v),
                  dense: true,
                ),
                if (_hasBarrelLength)
                  NullableUnitValueFieldTile(
                    label: 'Barrel length',
                    rawValue: _barrelLengthRaw,
                    constraints: FC.barrelLength,
                    displayUnit: units.barrelLength,
                    icon: Icons.straighten_outlined,
                    onChanged: (v) => setState(() => _barrelLengthRaw = v),
                  ),
              ],
            ),
          ),
          // ── Action bar ───────────────────────────────────────────────────
          _ActionBar(onDiscard: _onDiscard, onSave: _isValid ? _onSave : null),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _RiflePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 160,
        child: Card(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Rifle image',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onDiscard, required this.onSave});

  final VoidCallback onDiscard;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          OutlinedButton(onPressed: onDiscard, child: const Text('Discard')),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(onPressed: onSave, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}
