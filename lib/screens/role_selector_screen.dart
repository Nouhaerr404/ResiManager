import 'package:flutter/material.dart';
import 'super_admin/super_admin_dashboard_screen.dart';
import 'resident/resident_dashboard_screen.dart';
import 'syndic_general/dashboard_screen.dart';
import 'inter_syndic/intersyndic_selection_screen.dart';
import 'inter_syndic/tranches_list_screen.dart';
import 'inter_syndic/apartments/apartments_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';


const _coral = Color(0xFFFF6F4A);
const _white = Colors.white;

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── 1. IMAGE DE FOND
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/residence_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ── 2. OVERLAY gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.92),
                  ],
                  stops: const [0.0, 0.38, 1.0],
                ),
              ),
            ),
          ),

          // ── 3. CONTENU
          SafeArea(
            child: Column(
              children: [
                // ── TOP BAR
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _coral,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.domain,
                                color: _white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'ResiManager',
                            style: TextStyle(
                              color: _white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _OutlineBtn(label: 'Se connecter', onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()))),

                          const SizedBox(width: 8),
                          _FilledBtn(label: "S'inscrire", onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()))),

                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── HERO TEXT CENTRÉ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      // Badge pill centré
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: _coral.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: _coral.withOpacity(0.55), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: _coral, size: 13),
                            SizedBox(width: 6),
                            Text(
                              'Gestion résidentielle intelligente',
                              style: TextStyle(
                                color: _coral,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Titre principal centré
                      const Text(
                        'Gérez vos résidences\nen toute simplicité.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1.10,
                          letterSpacing: -1.2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sous-titre centré avec ligne décorative
                      Column(
                        children: [
                          Text(
                            'Choisissez votre espace pour commencer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _white.withOpacity(0.60),
                              fontSize: 15,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Ligne décorative centrée
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: _white.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 48,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: _coral,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: _white.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ── CARTES RÔLES
                SizedBox(
                  height: 112,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _RoleCard(
                        icon: Icons.dashboard_customize_outlined,
                        label: 'Inter-Syndic',
                        color: const Color(0xFF4CAF82),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const InterSyndicSelectionScreen())),
                      ),
                      _RoleCard(
                        icon: Icons.business_center_outlined,
                        label: 'Syndic Général',
                        color: _coral,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => DashboardScreen(residenceId: 1))),
                      ),
                      _RoleCard(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Super Admin',
                        color: const Color(0xFF4A90D9),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => SuperAdminDashboardScreen())),
                      ),
                      _RoleCard(
                        icon: Icons.home_outlined,
                        label: 'Résident',
                        color: const Color(0xFF9B59B6),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => ResidentDashboardScreen())),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── MODULES RAPIDES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModuleTile(
                          icon: Icons.apartment_outlined,
                          label: 'Appartements',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const ApartmentsListScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModuleTile(
                          icon: Icons.layers_outlined,
                          label: 'Tranches',
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(
                                  builder: (_) => const InterSyndicSelectionScreen())),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Footer
                Text(
                  'Version 1.0.0 · Mode Debug',
                  style: TextStyle(
                      color: _white.withOpacity(0.28), fontSize: 11),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// WIDGETS
// ══════════════════════════════════════════════

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border:
          Border.all(color: Colors.white.withOpacity(0.55), width: 1),
        ),
        child: const Text(
          'Se connecter',
          style: TextStyle(
              color: _white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilledBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _coral,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: _white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.white.withOpacity(0.18), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.18), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white38, size: 12),
          ],
        ),
      ),
    );
  }
}