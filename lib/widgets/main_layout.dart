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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen(residenceId: residenceId, syndicId: syndicId)),
            (route) => false,
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        // ✅ ON ASSOMBRIT LÉGÈREMENT LE FOND POUR FAIRE RESSORTIR L'APPBAR BLANCHE
        backgroundColor: const Color(0xFFF5F5F5), 
        
        appBar: !isWeb ? AppBar(
          title: Text(title, 
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w900, 
              color: Color(0xFF2C2C2C),
              letterSpacing: -0.5
            )
          ), 
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white, // Empêche la coloration Material 3
          centerTitle: false,
          elevation: 0, // ✅ PETITE OMBRE POUR L'EFFET DE BLOC
          shadowColor: Colors.black.withOpacity(0.1),
          toolbarHeight: 65,
          iconTheme: const IconThemeData(color: Color(0xFF2C2C2C), size: 28),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(0),
            ),
          ),
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