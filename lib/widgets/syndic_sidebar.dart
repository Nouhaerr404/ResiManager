import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/syndic_general/dashboard_screen.dart';
import '../screens/syndic_general/residence_audit_screen.dart';
import '../screens/syndic_general/syndics_management_screen.dart';
import '../screens/syndic_general/tranches_management_screen.dart';
import '../screens/syndic_general/residence_finances_screen.dart';
import '../screens/syndic_general/residence_selection_screen.dart';
import '../screens/role_selector_screen.dart';
import '../services/tranche_service.dart';
import '../models/tranche_model.dart';

class SyndicSidebar extends StatelessWidget {

  final String activePage;
  final int residenceId;
  final int syndicId;
  
  final TrancheService _trancheService = TrancheService();

  SyndicSidebar({Key? key, required this.activePage, required this.residenceId, required this.syndicId, }) : super(key: key);

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);


  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1),
            const SizedBox(height: 10),

            _buildMenuItem(context, Icons.dashboard_outlined, 'Tableau de bord', activePage == 'Dashboard', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(residenceId: residenceId, syndicId: syndicId)));
            }),

            _buildMenuItem(context, Icons.people_outline, 'Inter-Syndics', activePage == 'Syndics', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SyndicsManagementScreen(residenceId: residenceId, syndicId: syndicId)));
            }),

            // ✅ MENU TRANCHES AVEC ALERTE SI NON AFFECTÉ
            FutureBuilder<List<TrancheModel>>(
              future: _trancheService.getTranchesByResidence(residenceId),
              builder: (context, snapshot) {
                bool hasUnassigned = false;
                if (snapshot.hasData) {
                  hasUnassigned = snapshot.data!.any((t) => t.interSyndicId == null);
                }
                
                return _buildMenuItem(
                  context, 
                  Icons.domain, 
                  'Tranches', 
                  activePage == 'Tranches', 
                  () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TranchesManagementScreen(residenceId: residenceId, syndicId: syndicId)));
                  },
                  trailing: hasUnassigned 
                    ? const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22)
                    : null
                );
              }
            ),

            _buildMenuItem(context, Icons.account_balance_wallet_outlined, 'Dépenses', activePage == 'Dépenses', () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidenceFinancesScreen(residenceId: residenceId, syndicId: syndicId)));
            }),

            _buildMenuItem(
                context,
                Icons.analytics_outlined,
                'Audit & Bilans',
                activePage == 'Audit',
                    () {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (context) => ResidenceAuditScreen(residenceId: residenceId, syndicId: syndicId)
                  ));
                }
            ),

            const Spacer(),

            _buildMenuItem(context, Icons.location_city_outlined, 'Mes Résidences', false, () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResidenceSelectionScreen(syndicGeneralId: syndicId)));
            }),

            const Divider(indent: 20, endIndent: 20),

            _buildMenuItem(
                context,
                Icons.logout_rounded,
                'Se déconnecter',
                false,
                    () async {
                  await Supabase.instance.client.auth.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
                        (route) => false,
                  );
                }
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.business, color: Colors.white)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ResiManager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Admin Général', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ])
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, bool isSelected, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryOrange : Colors.grey.shade600),
      title: Text(title, style: TextStyle(color: isSelected ? primaryOrange : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}