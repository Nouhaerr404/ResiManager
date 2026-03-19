import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart'; // ← AJOUTEZ CET IMPORT

class ResetPasswordScreen extends StatefulWidget {
  final String? accessToken;
  const ResetPasswordScreen({super.key, this.accessToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _authService = AuthService(); // ← Ajoutez le type AuthService
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;
  bool _success = false;

  static const _coral = Color(0xFFFF6F4A);

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _error = "Veuillez remplir tous les champs");
      return;
    }

    if (newPass.length < 6) {
      setState(() => _error = "Le mot de passe doit contenir au moins 6 caractères");
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _error = "Les mots de passe ne correspondent pas");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _authService.resetPassword(
      newPass,
      accessToken: widget.accessToken,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      setState(() => _success = true);
    } else {
      setState(() => _error = result['error'] ?? "Erreur lors de la réinitialisation");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _coral),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Nouveau mot de passe",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _success ? _buildSuccessView() : _buildResetForm(),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _coral.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.password, color: _coral, size: 50),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Nouveau mot de passe",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Choisissez un nouveau mot de passe sécurisé",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 30),
          const Text("Nouveau mot de passe",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _newPassCtrl,
            hint: "••••••••",
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 20),
          const Text("Confirmer le mot de passe",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildPasswordField(
            controller: _confirmPassCtrl,
            hint: "••••••••",
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: _coral,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
                "Réinitialiser",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text(
            "Mot de passe modifié !",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Votre mot de passe a été réinitialisé avec succès.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _coral,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Se connecter",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}