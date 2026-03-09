import 'package:flutter/material.dart';
import 'syndic_sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final String title;

  const MainLayout({Key? key, required this.body, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      // Le Drawer s'affiche automatiquement sur mobile, et la Sidebar sur Web
      drawer: MediaQuery.of(context).size.width < 900 ? const SyndicSidebar() : null,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 900) const SyndicSidebar(),
          Expanded(child: body),
        ],
      ),
    );
  }
}