import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../syndic_general/residence_selection_screen.dart';
import '../inter_syndic/tranches_list_screen.dart';
import '../super_admin/super_admin_dashboard_screen.dart';
import '../resident/resident_layout.dart';
import '../../utils/temp_session.dart';

// ignore_for_file: invalid_language_identifier

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  static const _coral = Color(0xFFFF6F4A);

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      setState(() {
        _error = 'Veuillez remplir tous les champs.';
        _loading = false;
      });
      return;
    }

    final result = await _authService.login(_emailCtrl.text, _passCtrl.text);

    if (result == null || result['error'] != null) {
      setState(() {
        _error = result?['error'] ?? 'Erreur inconnue.';
        _loading = false;
      });
      return;
    }

    if (!mounted) return;

    final role   = result['role'] as String;
    final userId = result['id'] as int;

    // ── Stocker l'ID dans TempSession avant la navigation
    TempSession.interSyndicId = userId;

    switch (role) {
      case 'resident':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResidentLayout(userId: userId)),
        );
        break;

      case 'syndic_general':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResidenceSelectionScreen(syndicGeneralId: userId),
          ),
        );
        break;

      case 'inter_syndic':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TranchesListScreen()),
        );
        break;

      case 'super_admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SuperAdminDashboardScreen()),
        );
        break;

      default:
        setState(() {
          _error = 'Rôle non reconnu : $role';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _coral.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _coral.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _coral,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.domain,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'ResiManager',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Bienvenue 👋',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connectez-vous à votre espace',
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 36),
                  _buildLabel('Email'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailCtrl,
                    hint: 'votre@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Mot de passe'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passCtrl,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen()),
                        );
                      },
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: _coral,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade400, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _coral,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Pas encore de compte ? ",
                        style:
                        TextStyle(color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RegisterScreen()),
                        ),
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            color: _coral,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon:
          Icon(icon, color: Colors.grey.shade400, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}