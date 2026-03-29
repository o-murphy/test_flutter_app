import 'package:eballistica/shared/widgets/screen_top_bar.dart';
import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  const BaseScreen({
    required this.title,
    required this.body,
    this.actions,
    this.isSubscreen = false,
    this.floatingActionButton,
    this.withTabs,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool isSubscreen;
  final Widget? floatingActionButton;
  final List<Tab>? withTabs; // нове поле

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScreenTopBar(
        title: title,
        actions: actions,
        isSubscreen: isSubscreen,
        withTabs: withTabs, // прокидаємо таби
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
