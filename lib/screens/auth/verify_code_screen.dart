import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final AuthService _authService = AuthService();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _codeVerified = false;
  String? _error;
  int _secondsRemaining = 900; // 15 minutes en secondes
  bool _showResend = false;

  static const _coral = Color(0xFFFF6F4A);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
            _startTimer();
          } else {
            _showResend = true;
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();

    if (code.isEmpty) {
      setState(() => _error = "Veuillez saisir le code à 6 chiffres");
      return;
    }

    if (code.length != 6) {
      setState(() => _error = "Le code doit contenir exactement 6 chiffres");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _authService.verifyCode(widget.email, code);

    setState(() => _loading = false);

    if (result['success'] == true) {
      setState(() => _codeVerified = true);
    } else {
      setState(() => _error = result['error'] ?? "Code invalide");
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;
    final code = _codeCtrl.text.trim();

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

    final result = await _authService.resetPasswordWithCode(
      email: widget.email,
      code: code,
      newPassword: newPass,
    );

    setState(() => _loading = false);

    if (result['success'] == true) {
      // Succès - montrer un message et retourner au login
      _showSuccessDialog();
    } else {
      setState(() => _error = result['error'] ?? "Erreur lors de la réinitialisation");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "Mot de passe modifié !",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Votre mot de passe a été réinitialisé avec succès.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer le dialogue
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: _coral,
              ),
              child: const Text("Se connecter"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resendCode() async {
    setState(() {
      _loading = true;
      _error = null;
      _showResend = false;
      _secondsRemaining = 900;
    });

    final success = await _authService.sendResetCode(widget.email);

    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Un nouveau code a été envoyé"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _startTimer();
    } else {
      setState(() {
        _error = "Erreur lors de l'envoi du code";
        _showResend = true;
      });
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
          "Vérification",
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

              // Icône
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _coral.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _codeVerified ? Icons.password : Icons.sms,
                    color: _coral,
                    size: 50,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Titre
              Center(
                child: Text(
                  _codeVerified ? "Nouveau mot de passe" : "Vérification du code",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Email
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  widget.email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              if (!_codeVerified) ...[
                // CODE NON VÉRIFIÉ
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Timer
                      if (!_showResend)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Code valide pendant : ${_formatTime(_secondsRemaining)}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Champ code
                      TextField(
                        controller: _codeCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: "••••••",
                          hintStyle: TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                            color: Colors.grey.shade300,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterText: "",
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Message d'erreur
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

                      const SizedBox(height: 16),

                      // Bouton vérifier
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _verifyCode,
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
                            "Vérifier le code",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Lien renvoyer
                      if (_showResend)
                        TextButton(
                          onPressed: _loading ? null : _resendCode,
                          child: const Text(
                            "Renvoyer le code",
                            style: TextStyle(color: _coral),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                // CODE VÉRIFIÉ - SAISIE NOUVEAU MOT DE PASSE
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Champ nouveau mot de passe
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _newPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: "Nouveau mot de passe",
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Champ confirmation
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _confirmPassCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: "Confirmer le mot de passe",
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Message d'erreur
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

                      const SizedBox(height: 16),

                      // Bouton réinitialiser
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}