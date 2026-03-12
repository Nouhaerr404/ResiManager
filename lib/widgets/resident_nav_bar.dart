import 'package:flutter/material.dart';
import '../screens/resident/resident_dashboard_screen.dart';
import '../screens/resident/resident_charges_screen.dart';
import '../screens/resident/resident_annonces_screen.dart';
import '../screens/resident/resident_reunions_screen.dart';

class ResidentNavBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;

  const ResidentNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFFFF6B4A); // Orange de la maquette

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      toolbarHeight: 80,
      automaticallyImplyLeading: false, // Supprime la flèche retour
      title: Row(
        children: [
          // --- LOGO ET TITRE ---
          const Icon(Icons.home_work, color: brandColor, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "ResiManager",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "Espace Résident",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(width: 60), // Espace avant les onglets

          // --- ONGLETS DE NAVIGATION ---
          _buildNavItem(context, "Accueil", Icons.home_outlined, 0, ResidentDashboardScreen()),
          _buildNavItem(context, "Dépenses", Icons.receipt_long_outlined, 1, ResidentChargesScreen()),
          _buildNavItem(context, "Annonces", Icons.article_outlined, 2, ResidentAnnoncesScreen()),
          _buildNavItem(context, "Réunions", Icons.calendar_today_outlined, 3, ResidentReunionsScreen()),

          const Spacer(),

          // --- BOUTON RETOUR ADMIN ---
          TextButton.icon(
            onPressed: () {
              // Retourne à la première page (Sélecteur de rôle)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout, color: Colors.black54, size: 18),
            label: const Text(
              "Retour Admin",
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // Widget interne pour construire chaque bouton du menu
  Widget _buildNavItem(BuildContext context, String label, IconData icon, int index, Widget destination) {
    bool isActive = currentIndex == index;
    const Color brandColor = Color(0xFFFF6B4A);

    return InkWell(
      onTap: () {
        if (!isActive) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim1, anim2) => destination,
              transitionDuration: Duration.zero, // Transition instantanée style Web
            ),
          );
        }
      },
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? brandColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? brandColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? brandColor : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}