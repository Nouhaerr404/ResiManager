import 'package:flutter/material.dart';
import 'syndic_sidebar.dart';
import '../screens/syndic_general/dashboard_screen.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final String activePage;
  final int residenceId;
  final int syndicId;
  final String title;

  const MainLayout({
    Key? key,
    required this.body,
    required this.activePage,
    required this.residenceId,
    required this.syndicId,
    this.title = ""
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width >= 900;

    return WillPopScope(
      onWillPop: () async {
        if (activePage != 'Dashboard') {
          // Sur Mobile, le bouton retour physique ramène au Dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen(residenceId: residenceId, syndicId: syndicId)),
            (route) => false,
          );
          return false;
        }
        // Si on est sur le Dashboard, on laisse le WillPopScope du Dashboard gérer le retour vers la sélection
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9F6),
        // On laisse Flutter gérer le leading (burger menu) automatiquement
        appBar: !isWeb ? AppBar(
          title: Text(title, style: const TextStyle(fontSize: 22)), 
          elevation: 0,
        ) : null,

        drawer: !isWeb ? SyndicSidebar(activePage: activePage, residenceId: residenceId, syndicId: syndicId) : null,

        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWeb) SizedBox(width: 260, child: SyndicSidebar(activePage: activePage, residenceId: residenceId, syndicId: syndicId)),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}