import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'verify_code_screen.dart'; // ← NOUVEL IMPORT

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;
  String? _error;

  static const _coral = Color(0xFFFF6F4A);

  // ✅ MODIFIÉ : Utilise sendResetCode au lieu de sendPasswordResetEmail
  Future<void> _sendResetEmail() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() => _error = "Veuillez saisir votre email");
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _error = "Email invalide");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // ✅ Appel à la nouvelle méthode sendResetCode
    final success = await _authService.sendResetCode(email);

    setState(() => _loading = false);

    if (success) {
      // ✅ Rediriger vers l'écran de vérification du code
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyCodeScreen(email: email),
        ),
      );
    } else {
      setState(() => _error = "Erreur lors de l'envoi du code");
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
          "Mot de passe oublié",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                  child: const Icon(
                    Icons.lock_reset,
                    color: _coral,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  "Réinitialisation du mot de passe",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Saisissez votre email pour recevoir un code de vérification",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),
              // ✅ On garde le formulaire visible (pas de _emailSent ici)
              _buildEmailForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "votre@email.com",
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
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
            onPressed: _loading ? null : _sendResetEmail,
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
              "Envoyer le code",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Retour à la connexion",
              style: TextStyle(color: _coral),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ On garde _buildSuccessView même si on ne l'utilise plus (au cas où)
  Widget _buildSuccessView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          const Text(
            "Email envoyé !",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Un email a été envoyé à ${_emailCtrl.text}. Vérifiez votre boîte de réception et suivez les instructions.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.green.shade700),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: _coral,
                side: const BorderSide(color: _coral),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Retour à la connexion"),
            ),
          ),
        ],
      ),
    );
  }
}