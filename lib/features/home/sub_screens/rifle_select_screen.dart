import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/solver/unit.dart' show Unit;
import 'package:eballistica/features/home/sub_screens/rifle_select/rifle_select_vm.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/pages_dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RifleSelectScreen extends ConsumerStatefulWidget {
  const RifleSelectScreen({super.key});

  @override
  ConsumerState<RifleSelectScreen> createState() => _RifleSelectScreenState();
}

class _RifleSelectScreenState extends ConsumerState<RifleSelectScreen> {
  final _fabKey = GlobalKey<_ExpandableFabState>();
  late final _dimAnimation = _DeferredAnimation(_fabKey);
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  String _titleFor(RifleSelectUiState state) {
    if (state is! RifleSelectReady || state.profiles.isEmpty) {
      return 'Select Profile';
    }
    final idx = _currentPage.clamp(0, state.profiles.length - 1);
    return state.profiles[idx].name;
  }

  ShotProfile? _currentProfile(RifleSelectUiState state) {
    if (state is! RifleSelectReady || state.profiles.isEmpty) return null;
    final idx = _currentPage.clamp(0, state.profiles.length - 1);
    return state.profiles[idx];
  }

  Future<void> _onAdd() async {
    // TODO: navigate to profile wizard (Phase 5)
  }

  Future<void> _onEdit(ShotProfile? profile) async {
    if (profile == null) return;
    // TODO: navigate to profile wizard with existing profile (Phase 5)
  }

  Future<void> _onDelete(ShotProfile? profile) async {
    if (profile == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile'),
        content: Text('Delete "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(rifleSelectVmProvider.notifier).deleteProfile(profile.id);
      if (_currentPage > 0) {
        setState(() => _currentPage = _currentPage - 1);
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _onImport() async {
    // TODO: add file_picker to pubspec.yaml to enable .a7p import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import not yet available')),
    );
  }


  Future<void> _onExport(ShotProfile? profile) async {
    if (profile == null) return;
    // TODO: serialize profile and share (Phase 5+)
  }

  Future<void> _onSelect(ShotProfile profile) async {
    await ref.read(rifleSelectVmProvider.notifier).selectProfile(profile.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(rifleSelectVmProvider);

    return vmState.when(
      loading: () => BaseScreen(
        title: 'Select Profile',
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => BaseScreen(
        title: 'Select Profile',
        body: Center(child: Text('Error: $err')),
      ),
      data: (state) {
        final profile = _currentProfile(state);
        return BaseScreen(
          title: _titleFor(state),
          floatingActionButton: _ExpandableFab(
            key: _fabKey,
            onAdd: _onAdd,
            onEdit: () => _onEdit(profile),
            onDelete: () => _onDelete(profile),
            onImport: _onImport,
            onExport: () => _onExport(profile),
          ),
          body: state is RifleSelectReady && state.profiles.isNotEmpty
              ? Stack(
                  children: [
                    _ProfilePageView(
                      profiles: state.profiles,
                      activeProfileId: state.activeProfileId,
                      pageController: _pageController,
                      currentPage: _currentPage,
                      onPageChanged: _onPageChanged,
                      onSelect: _onSelect,
                    ),
                    AnimatedBuilder(
                      animation: _dimAnimation,
                      builder: (context, child) {
                        final value = _dimAnimation.value;
                        if (value == 0.0) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => _fabKey.currentState?.close(),
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: value * 0.4),
                            child: const SizedBox.expand(),
                          ),
                        );
                      },
                    ),
                  ],
                )
              : const Center(child: Text('No profiles. Tap + to add one.')),
        );
      },
    );
  }
}

// ── Profile Page View ─────────────────────────────────────────────────────────

class _ProfilePageView extends StatelessWidget {
  const _ProfilePageView({
    required this.profiles,
    required this.activeProfileId,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onSelect,
  });

  final List<ShotProfile> profiles;
  final String? activeProfileId;
  final PageController pageController;
  final int currentPage;
  final void Function(int) onPageChanged;
  final void Function(ShotProfile) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: pageController,
            onPageChanged: onPageChanged,
            children: profiles
                .map(
                  (p) => _ProfileCard(
                    profile: p,
                    isActive: p.id == activeProfileId,
                    onSelect: () => onSelect(p),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        PageDotsIndicator(
          current: currentPage,
          count: profiles.length,
          onPageChanged: (page) {
            pageController.animateToPage(
              page,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onSelect,
  });

  final ShotProfile profile;
  final bool isActive;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        color: isActive ? colorScheme.primaryContainer : null,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (isActive)
                      Icon(Icons.check_circle, color: colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.military_tech_outlined,
                  label: profile.rifle.name,
                ),
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.grain_outlined,
                  label: profile.cartridge.name,
                ),
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.my_location_outlined,
                  label:
                      '${profile.zeroDistance.in_(Unit.meter).toStringAsFixed(0)} m zero',
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onSelect,
                    child: const Text('Select'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

/// Проксі-анімація що делегує до FAB state після першого frame.
class _DeferredAnimation extends Animation<double>
    with AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {
  @override
  void didRegisterListener() {}
  @override
  void didUnregisterListener() {}

  _DeferredAnimation(this._key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _key.currentState?.animation.addListener(notifyListeners);
      _key.currentState?.animation.addStatusListener(notifyStatusListeners);
    });
  }

  final GlobalKey<_ExpandableFabState> _key;

  @override
  double get value => _key.currentState?.animation.value ?? 0.0;

  @override
  AnimationStatus get status =>
      _key.currentState?.animation.status ?? AnimationStatus.dismissed;
}

class _ExpandableFab extends StatefulWidget {
  const _ExpandableFab({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onImport,
    required this.onExport,
  });

  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onImport;
  final VoidCallback onExport;

  @override
  State<_ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<_ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  Animation<double> get animation => _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isDismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _collapse() => _controller.reverse();

  void close() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FadeTransition(
          opacity: _expandAnimation,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: Theme.of(context).colorScheme.errorContainer,
                  onPressed: () {
                    _collapse();
                    widget.onDelete();
                  },
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.file_upload_outlined,
                  label: 'Export',
                  onPressed: () {
                    _collapse();
                    widget.onExport();
                  },
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.file_open_outlined,
                  label: 'Import',
                  onPressed: () {
                    _collapse();
                    widget.onImport();
                  },
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onPressed: () {
                    _collapse();
                    widget.onEdit();
                  },
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add',
                  onPressed: () {
                    _collapse();
                    widget.onAdd();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => FloatingActionButton(
            onPressed: _toggle,
            child: Transform.rotate(
              angle: _expandAnimation.value * 3.14159 / 2,
              child: const Icon(Icons.edit),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon),
        ),
      ],
    );
  }
}
