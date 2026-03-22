import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'resident_dashboard_screen.dart';
import 'resident_charges_screen.dart';
import 'resident_annonces_screen.dart';
import 'resident_reunions_screen.dart';
import 'historique_paiements_screen.dart';
import 'resident_reclamations_screen.dart';
import 'paiement_status_screen.dart';

class ResidentLayout extends StatefulWidget {
  final int userId;
  final int initialIndex;
  const ResidentLayout({
    super.key,
    required this.userId,
    this.initialIndex = 0,
  });

  @override
  State<ResidentLayout> createState() => _ResidentLayoutState();
}

class _ResidentLayoutState extends State<ResidentLayout> {
  late int _currentIndex;
  final AuthService _authService = AuthService();
  static const _coral = Color(0xFFFF6B4A);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _goTo(int index) => setState(() => _currentIndex = index);

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── Page affichée selon l'index ──
  Widget _buildPage() {
    switch (_currentIndex) {
      case 0: return ResidentDashboardScreen(
          userId: widget.userId, onNavigate: _goTo);
      case 1: return ResidentChargesScreen(
          userId: widget.userId, onNavigate: _goTo);
      case 2: return PaiementStatusScreen(
          userId: widget.userId, onNavigate: _goTo);

      case 3: return ResidentAnnoncesScreen(
          userId: widget.userId, onNavigate: _goTo);
      case 4: return ResidentReunionsScreen(
          userId: widget.userId, onNavigate: _goTo);
      case 5: return ResidentReclamationsScreen(
          userId: widget.userId, onNavigate: _goTo);

      default: return ResidentDashboardScreen(
          userId: widget.userId, onNavigate: _goTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      // AppBar pour mobile uniquement
      appBar: isMobile ? AppBar(
        title: const Text('ResiManager',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: _coral),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ) : null,
      // Drawer pour mobile
      drawer: isMobile ? _buildMobileDrawer() : null,
      // Corps principal avec sidebar TOUJOURS présente sur desktop
      body: Row(
        children: [
          // Sidebar visible seulement sur desktop
          if (!isMobile) _buildSideNav(),
          // Contenu principal (prend toute la largeur sur mobile)
          Expanded(child: _buildPage()),
        ],
      ),
    );
  }

  // ── Navbar fixe gauche (desktop/web) ──
  Widget _buildSideNav() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _coral,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_work,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                const Text('ResiManager',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Espace Résident',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: 12),

          // Items de navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _navItem(0, Icons.home_outlined, 'Accueil'),
                _navItem(1, Icons.receipt_long_outlined, 'Dépenses'),
                _navItem(2, Icons.payment_outlined, 'Paiements'),
                _navItem(3, Icons.article_outlined, 'Annonces'),
                _navItem(4, Icons.calendar_today_outlined, 'Réunions'),
                _navItem(5, Icons.report_problem_outlined, 'Réclamations'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Déconnexion
          ListTile(
            leading: const Icon(Icons.logout,
                color: Colors.redAccent, size: 22),
            title: const Text('Déconnexion',
                style: TextStyle(
                    color: Colors.redAccent, fontSize: 14)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool sel = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: sel ? _coral.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: sel ? _coral : Colors.grey.shade600, size: 22),
        title: Text(label,
            style: TextStyle(
                color: sel ? _coral : Colors.black87,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                fontSize: 14)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        onTap: () => _goTo(index),
      ),
    );
  }

  // ── Drawer mobile ──
  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
            color: _coral,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home_work, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text('ResiManager',
                    style: TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Espace Résident',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(0, Icons.home, 'Accueil'),
                _drawerItem(1, Icons.receipt_long, 'Dépenses'),
                _drawerItem(2, Icons.payment, 'Paiements'),
                _drawerItem(3, Icons.article, 'Annonces'),
                _drawerItem(4, Icons.calendar_today, 'Réunions'),
                _drawerItem(5, Icons.report_problem, 'Réclamations'),

              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Déconnexion',
                style: TextStyle(color: Colors.redAccent)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String label) {
    final bool sel = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: sel ? _coral : Colors.grey, size: 24),
      title: Text(label,
          style: TextStyle(
              color: sel ? _coral : Colors.black87,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      selected: sel,
      selectedTileColor: _coral.withValues(alpha: 0.1),
      onTap: () {
        Navigator.pop(context);
        _goTo(index);
      },
    );
  }
}
