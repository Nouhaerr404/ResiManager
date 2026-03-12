import 'package:flutter/material.dart';
import '../screens/super_admin/super_admin_dashboard_screen.dart';
import '../screens/super_admin/residences/residences_screen.dart';
import '../screens/super_admin/syndics/syndics_screen.dart';

class AppSidebar extends StatelessWidget {
  final String currentPage;
  const AppSidebar({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text("Super Admin", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("ResiManager", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          _buildNavItem(context, "Dashboard", Icons.show_chart, "dash", SuperAdminDashboardScreen()),
          const SizedBox(height: 8),
          _buildNavItem(context, "Résidences", Icons.business, "res", ResidencesScreen()),
          const SizedBox(height: 8),
          _buildNavItem(context, "Syndics Généraux", Icons.people_outline, "syn", SyndicsScreen()),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon, String code, Widget screen) {
    bool isSelected = currentPage == code;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF222222) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children:[
            Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 22),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}