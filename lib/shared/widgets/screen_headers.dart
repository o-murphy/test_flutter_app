import 'package:go_router/go_router.dart';
import 'package:eballistica/router.dart';
import 'package:flutter/material.dart';

class ScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScreenAppBar({
    required this.title,
    this.actions,
    this.isSubscreen = false,
    super.key,
  });
  final String title;
  final List<Widget>? actions;
  final bool isSubscreen;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => isSubscreen ? context.pop() : context.go(Routes.home),
        tooltip: 'Back',
      ),
      actions: actions,
    );
  }
}
