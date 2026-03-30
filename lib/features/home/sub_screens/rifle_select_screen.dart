import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/pages_dots_indicator.dart';
import 'package:flutter/material.dart';

class RifleSelectScreen extends StatefulWidget {
  const RifleSelectScreen({super.key});

  @override
  State<RifleSelectScreen> createState() => _RifleSelectScreenState();
}

class CardRifleView extends StatelessWidget {
  const CardRifleView({required this.body, super.key});

  final Widget body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Card(
      child: body,
      // child: ListView(children: [ListTile(title: Text("Text"))]),
    ),
  );
}

class _RifleSelectScreenState extends State<RifleSelectScreen> {
  String _title = "Select Rifle";
  final List<String> _titles = ["Rifle 1", "Rifle 2", "Rifle 3"];
  int _currentPage = 0;
  final _fabKey = GlobalKey<_ExpandableFabState>();
  late final _dimAnimation = _DeferredAnimation(_fabKey);

  void _onPageChanged(int page) {
    setState(() {
      _title = _titles[page];
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) => BaseScreen(
    title: _title,
    floatingActionButton: _ExpandableFab(
      key: _fabKey,
      onAdd: () {},
      onEdit: () {},
      onDelete: () {},
      onImport: () {},
      onExport: () {},
    ),
    body: Stack(
      children: [
        PageViewWithDots(
          onPageChanged: _onPageChanged,
          children: _titles
              .map((item) => CardRifleView(body: Center(child: Text(item))))
              .toList(),
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
    ),
  );
}

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

// Оновлений PageViewWithDots з callback
class PageViewWithDots extends StatefulWidget {
  const PageViewWithDots({
    super.key,
    required this.children,
    this.onPageChanged,
  });

  final List<Widget> children;
  final void Function(int page)? onPageChanged;

  @override
  State<PageViewWithDots> createState() => _PageViewWithDotsState();
}

class _PageViewWithDotsState extends State<PageViewWithDots> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int page) {
    setState(() => _currentPage = page);
    widget.onPageChanged?.call(page);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            children: widget.children,
          ),
        ),
        const SizedBox(height: 12),
        PageDotsIndicator(
          current: _currentPage,
          count: widget.children.length,
          onPageChanged: (page) {
            _pageController.animateToPage(
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
