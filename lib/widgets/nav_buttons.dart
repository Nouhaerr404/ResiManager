import 'package:flutter/material.dart';
import '../screens/syndic_general/residence_selection_screen.dart';
import '../screens/syndic_general/dashboard_screen.dart';

class NavButtons extends StatelessWidget {
  final int residenceId;

  const NavButtons({Key? key, required this.residenceId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. BOUTON RETOUR (Blanc) -> Vers la liste des résidences
        _buildButton(
          icon: Icons.chevron_left,
          bgColor: Colors.white,
          iconColor: Colors.black,
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResidenceSelectionScreen(syndicGeneralId: 1)),
          ),
        ),
        const SizedBox(width: 12),

        // 2. BOUTON DASHBOARD (Orange) -> Vers le dashboard de cette résidence
        _buildButton(
          icon: Icons.grid_view_rounded,
          bgColor: const Color(0xFFFF6F4A), // Ton Orange Corail
          iconColor: Colors.white,
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen(residenceId: residenceId)),
          ),
        ),
      ],
    );
  }

  // Petit outil pour dessiner les boutons carrés arrondis
  Widget _buildButton({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}