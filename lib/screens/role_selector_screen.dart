import 'package:flutter/material.dart';
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
                      // Logo
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
                      // Boutons
                      Row(
                        children: [
                          _OutlineBtn(
                            label: 'Se connecter',
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen())),
                          ),
                          const SizedBox(width: 8),
                          _FilledBtn(
                            label: "S'inscrire",
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen())),
                          ),
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
                            Icon(Icons.auto_awesome, color: _coral, size: 13),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28, height: 2,
                                decoration: BoxDecoration(
                                  color: _white.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 48, height: 2,
                                decoration: BoxDecoration(
                                  color: _coral,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28, height: 2,
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

                const Spacer(),

                // Footer
                Text(
                  'Version 1.0.0 · ResiManager',
                  style: TextStyle(
                      color: _white.withOpacity(0.28), fontSize: 11),
                ),
                const SizedBox(height: 24),
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
          border: Border.all(color: Colors.white.withOpacity(0.55), width: 1),
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