import 'package:flutter/material.dart';
import 'syndic_sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final String activePage;
  final String title;

  const MainLayout({
    Key? key,
    required this.body,
    required this.activePage,
    this.title = ""
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      // AppBar affichée seulement sur mobile pour le menu burger
      appBar: !isWeb ? AppBar(title: Text(title), elevation: 0) : null,

      // Le menu caché (Mobile)
      drawer: !isWeb ? SyndicSidebar(activePage: activePage) : null,

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le menu fixe (Web)
          if (isWeb) SizedBox(width: 260, child: SyndicSidebar(activePage: activePage)),

          // Le contenu de la page
          Expanded(child: body),
        ],
      ),
    );
  }
}