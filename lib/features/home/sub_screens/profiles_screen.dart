import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/features/home/sub_screens/profiles/profiles_vm.dart';
import 'package:eballistica/features/home/sub_screens/profiles/widgets/profile_card.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/pages_dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  final _fabAnimValue = ValueNotifier<double>(0.0);
  VoidCallback _closeFab = () {};
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _fabAnimValue.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  String _titleFor(ProfilesUiState state) {
    if (state is! ProfilesReady || state.profiles.isEmpty) {
      return 'Select Profile';
    }
    final idx = _currentPage.clamp(0, state.profiles.length - 1);
    return state.profiles[idx].name;
  }

  ShotProfile? _currentProfile(ProfilesUiState state) {
    if (state is! ProfilesReady || state.profiles.isEmpty) return null;
    final idx = _currentPage.clamp(0, state.profiles.length - 1);
    return state.profiles[idx];
  }

  Future<void> _onAdd() async {
    // TODO: navigate to profile wizard (Phase 5)
  }

  Future<void> _onRemove(ShotProfile? profile) async {
    if (profile == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove profile'),
        content: Text('Remove "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(rifleSelectVmProvider.notifier).removeProfile(profile.id);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Import not yet available')));
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
            animationNotifier: _fabAnimValue,
            onRegisterClose: (fn) => _closeFab = fn,
            onAdd: _onAdd,
            onRemove: () => _onRemove(profile),
            onImport: _onImport,
            onExport: () => _onExport(profile),
          ),
          body: state is ProfilesReady && state.profiles.isNotEmpty
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
                    ValueListenableBuilder<double>(
                      valueListenable: _fabAnimValue,
                      builder: (context, value, child) {
                        if (value == 0.0) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => _closeFab(),
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
                  (p) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ProfileCard(
                      profile: p,
                      isActive: p.id == activeProfileId,
                      onSelect: () => onSelect(p),
                    ),
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

// ── FAB ───────────────────────────────────────────────────────────────────────

class _ExpandableFab extends StatefulWidget {
  const _ExpandableFab({
    required this.animationNotifier,
    required this.onRegisterClose,
    required this.onAdd,
    required this.onRemove,
    required this.onImport,
    required this.onExport,
  });

  final ValueNotifier<double> animationNotifier;
  final void Function(VoidCallback) onRegisterClose;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
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
    _expandAnimation.addListener(_onAnimationTick);
    widget.onRegisterClose(close);
  }

  @override
  void didUpdateWidget(_ExpandableFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.onRegisterClose(close);
  }

  void _onAnimationTick() {
    widget.animationNotifier.value = _expandAnimation.value;
  }

  @override
  void dispose() {
    _expandAnimation.removeListener(_onAnimationTick);
    widget.animationNotifier.value = 0.0;
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
                  label: 'Remove',
                  color: Theme.of(context).colorScheme.errorContainer,
                  onPressed: () {
                    _collapse();
                    widget.onRemove();
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
            heroTag: null,
            onPressed: _toggle,
            child: Transform.rotate(
              angle: _expandAnimation.value * 3.14159 / 2,
              child: const Icon(Icons.edit_outlined),
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
          heroTag: null,
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon),
        ),
      ],
    );
  }
}
