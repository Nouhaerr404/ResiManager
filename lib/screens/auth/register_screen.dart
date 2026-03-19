// lib/screens/auth/register_screen.dart
//
// L'inscription crée une demande dans demandes_inscription
// Le super admin doit accepter avant que le compte soit créé.

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _nomCtrl     = TextEditingController();
  final _prenomCtrl  = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _telCtrl     = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading  = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;
  bool _submitted = false; // affiche l'écran de succès

  static const _coral = Color(0xFFFF6F4A);

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });

    // Validations
    if (_prenomCtrl.text.trim().isEmpty ||
        _nomCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() {
        _error = 'Veuillez remplir tous les champs obligatoires.';
        _loading = false;
      });
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() {
        _error = 'Les mots de passe ne correspondent pas.';
        _loading = false;
      });
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() {
        _error = 'Mot de passe trop court (6 caractères min).';
        _loading = false;
      });
      return;
    }

    // Soumettre la demande
    final error = await _authService.soumettreDemandeInscription(
      nom:       _nomCtrl.text.trim(),
      prenom:    _prenomCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      password:  _passCtrl.text,
    );

    if (error != null) {
      setState(() { _error = error; _loading = false; });
      return;
    }

    setState(() { _submitted = true; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _coral.withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            child: _submitted ? _buildSuccess() : _buildForm(),
          ),
        ],
      ),
    );
  }

  // ── Formulaire ─────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Demande d\'inscription',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'Votre demande sera examinée par le super admin.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

          // Badge info
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _coral.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _coral.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: _coral, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ce formulaire est réservé aux syndics généraux. '
                      'Après validation, vous recevrez vos accès.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          Row(children: [
            Expanded(child: _field('Prénom *', _prenomCtrl, Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _field('Nom *', _nomCtrl, Icons.person_outline)),
          ]),
          const SizedBox(height: 16),
          _field('Email *', _emailCtrl, Icons.email_outlined,
              type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _field('Téléphone', _telCtrl, Icons.phone_outlined,
              type: TextInputType.phone),
          const SizedBox(height: 16),
          _passField('Mot de passe *', _passCtrl, _obscure1,
                  () => setState(() => _obscure1 = !_obscure1)),
          const SizedBox(height: 16),
          _passField('Confirmer le mot de passe *', _confirmCtrl, _obscure2,
                  () => setState(() => _obscure2 = !_obscure2)),
          const SizedBox(height: 16),

          if (_error != null) _msgBox(_error!, isError: true),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _coral,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Envoyer ma demande',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Déjà un compte ? ',
                style: TextStyle(color: Colors.grey.shade600)),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Se connecter',
                  style: TextStyle(
                      color: _coral, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Écran succès ───────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade500, size: 64),
            ),
            const SizedBox(height: 28),
            const Text(
              'Demande envoyée !',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre demande a été transmise au super administrateur. '
                  'Vous serez contacté une fois votre demande traitée.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _coral,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Retour à la connexion',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────
  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? type}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passField(String label, TextEditingController ctrl,
      bool obscure, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline,
                  color: Colors.grey.shade400, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey, size: 20),
                onPressed: toggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _msgBox(String msg, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isError ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Row(children: [
        Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red.shade400 : Colors.green.shade400,
            size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: isError
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    fontSize: 13))),
      ]),
    );
  }
}