import 'package:flutter/material.dart';
import '../screens/resident/resident_dashboard_screen.dart';
import '../screens/resident/resident_charges_screen.dart';
// Importe les autres écrans quand ils seront créés
// import '../screens/resident/resident_notifications_screen.dart';

class ResidentNavBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;

  const ResidentNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    // Couleur orange de ta maquette
    const Color brandColor = Color(0xFFFF6B4A);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      toolbarHeight: 80, // Hauteur personnalisée pour correspondre au design
      automaticallyImplyLeading: false, // Supprime le bouton retour auto
      title: Row(
        children: [
          // LOGO ET TITRE
          const Icon(Icons.home_work, color: brandColor, size: 32),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "ResiManager",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                "Espace Résident",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(width: 60), // Espace avant les onglets

          // ONGLETS DE NAVIGATION
          _buildNavItem(context, "Accueil", Icons.home_outlined, 0, ResidentDashboardScreen()),
          _buildNavItem(context, "Mes Charges", Icons.receipt_long_outlined, 1, ResidentChargesScreen()),
          _buildNavItem(context, "Notifications", Icons.notifications_none_outlined, 2, null, badge: "2"),
          _buildNavItem(context, "Annonces", Icons.article_outlined, 3, null),
          _buildNavItem(context, "Réunions", Icons.calendar_today_outlined, 4, null),

          const Spacer(),

          // BOUTON RETOUR ADMIN
          TextButton.icon(
            onPressed: () {
              // Ici tu peux rediriger vers le dashboard Super Admin si besoin
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout, color: Colors.black54, size: 20),
            label: const Text(
              "Retour Admin",
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // Widget interne pour construire chaque élément du menu
  Widget _buildNavItem(BuildContext context, String label, IconData icon, int index, Widget? destination, {String? badge}) {
    bool isActive = currentIndex == index;
    const Color brandColor = Color(0xFFFF6B4A);

    return InkWell(
      onTap: () {
        if (!isActive && destination != null) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => destination,
              transitionDuration: Duration.zero, // Transition instantanée comme un vrai site web
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
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? brandColor : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
            // AFFICHAGE DU BADGE (POINT ROUGE)
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: brandColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}