import 'package:flutter/material.dart';
import '../../../services/super_admin_service.dart';
import '../../../widgets/app_sidebar.dart';
import '../../../models/residence_model.dart';
import 'residences/residences_screen.dart';
import 'syndics/syndics_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  final SuperAdminService _service = SuperAdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const AppSidebar(currentPage: "dash"),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  const Text("Dashboard Super Admin", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                  const SizedBox(height: 4),
                  const Text("Vue d'ensemble de toutes les résidences", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 30),

                  // --- 1. CARTES DE STATISTIQUES (100% Dynamiques) ---
                  FutureBuilder<Map<String, dynamic>>(
                      future: _service.getGlobalStats(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final stats = snapshot.data!;

                        // Variables dynamiques
                        int sansSyndic = stats['residences_sans_syndic'];

                        return Column(
                          children: [
                            Row(
                              children:[
                                _buildStatCard("Résidences Totales", "${stats['residences_totales']}", "Total enregistré", Icons.business, Colors.black87),
                                const SizedBox(width: 16),
                                _buildStatCard("Syndics Généraux", "${stats['syndics_totaux']}", "${stats['syndics_actifs']} actifs", Icons.people_outline, const Color(0xFFFF6B4A)),
                                const SizedBox(width: 16),
                                _buildStatCard("Immeubles", "${stats['immeubles_totaux']}", "Sur ${stats['residences_totales']} résidences", Icons.home_work_outlined, Colors.black87),
                                const SizedBox(width: 16),
                                _buildStatCard("Appartements", "${stats['appartements_totaux']}", "Total dans le système", Icons.check_circle_outline, const Color(0xFFFF6B4A)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // --- 2. ALERTE (S'affiche uniquement s'il y a un problème) ---
                            if (sansSyndic > 0)
                              _buildAlertBox(sansSyndic),
                            if (sansSyndic > 0)
                              const SizedBox(height: 32),
                          ],
                        );
                      }
                  ),

                  // --- 3. ACCÈS RAPIDE ---
                  const Text("Accès Rapide", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children:[
                      _buildQuickAccessCard(context, "Voir Résidences", Icons.business, ResidencesScreen()),
                      const SizedBox(width: 16),
                      _buildQuickAccessCard(context, "Voir Syndics Généraux", Icons.people_outline, SyndicsScreen()),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- 4. RÉSIDENCES RÉCENTES (Depuis la DB) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:[
                      const Text("Résidences Récentes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidencesScreen())),
                        child: const Text("Voir tout →", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<ResidenceModel>>(
                      future: _service.getAllResidences(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        if (snapshot.data!.isEmpty) return const Text("Aucune résidence enregistrée dans la base de données.");

                        final recentResidences = snapshot.data!.take(3).toList();
                        return Column(
                          children: recentResidences.map((res) => _buildRecentResidenceCard(res)).toList(),
                        );
                      }
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, String subtitle, IconData icon, Color borderColor) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: 1.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Icon(icon, size: 28, color: Colors.black87),
                Text(count, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              ],
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBox(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFFFF6F4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFD8D0))),
      child: Row(
        children:[
          const Icon(Icons.error_outline, color: Color(0xFFFF6B4A)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              const Text("Résidences sans syndic général", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF222222))),
              const SizedBox(height: 4),
              Text("$count résidence(s) n'ont pas de syndic général affecté", style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(BuildContext context, String title, IconData icon, Widget targetScreen) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => targetScreen)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Icon(icon, size: 32, color: Colors.black87),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentResidenceCard(ResidenceModel res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(res.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                child: const Text("Active", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(res.adresse, style: const TextStyle(color: Colors.grey)),
              Text(res.syndicNom ?? "Aucun syndic", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children:[
              Text("${res.nombreTranches} tranches", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(width: 16),
              Text("${res.totalImmeubles} immeubles", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(width: 16),
              Text("${res.totalAppartements} appts", style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}