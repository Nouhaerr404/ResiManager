import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/resident_service.dart';

class _C {
  static const coral      = Color(0xFFFF6B4A);
  static const coralLight = Color(0xFFFFF0EB);
  static const bg         = Color(0xFFF9F8F6);
  static const white      = Color(0xFFFFFFFF);
  static const dark       = Color(0xFF222222);
  static const textMid    = Color(0xFF5A5A6A);
  static const textLight  = Color(0xFF9A9AAF);
  static const divider    = Color(0xFFE8E8F0);
  static const green      = Color(0xFF34C98B);
}

class ResidentProfileScreen extends StatefulWidget {
  final int userId;
  const ResidentProfileScreen({super.key, required this.userId});

  @override
  State<ResidentProfileScreen> createState() => _ResidentProfileScreenState();
}

class _ResidentProfileScreenState extends State<ResidentProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _residentService = ResidentService();

  bool _editMode = false;
  bool _saving   = false;
  bool _loading  = true;

  final _nomCtrl       = TextEditingController();
  final _prenomCtrl    = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _telCtrl       = TextEditingController();
  final _formKey        = GlobalKey<FormState>();

  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _changingPassword = false;

  late String _origNom, _origPrenom, _origEmail, _origTel;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadProfile();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('users')
          .select('nom, prenom, email, telephone')
          .eq('id', widget.userId)
          .maybeSingle();

      if (res != null) {
        _nomCtrl.text    = res['nom']       ?? '';
        _prenomCtrl.text = res['prenom']    ?? '';
        _emailCtrl.text  = res['email']     ?? '';
        _telCtrl.text    = res['telephone'] ?? '';
      }
      _saveOriginals();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _loading = false);
      _fadeCtrl.forward(from: 0);
    }
  }

  void _saveOriginals() {
    _origNom    = _nomCtrl.text;
    _origPrenom = _prenomCtrl.text;
    _origEmail  = _emailCtrl.text;
    _origTel    = _telCtrl.text;
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      await _supabase.from('users').update({
        'nom':       _nomCtrl.text.trim(),
        'prenom':    _prenomCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'telephone': _telCtrl.text.trim(),
      }).eq('id', widget.userId);

      _saveOriginals();
      setState(() {
        _editMode = false;
        _saving   = false;
      });
      _showSnack('Profil mis à jour avec succès', success: true);
    } catch (e) {
      setState(() => _saving = false);
      _showSnack('Erreur lors de la mise à jour : $e');
    }
  }

  void _cancelEdit() {
    _nomCtrl.text    = _origNom;
    _prenomCtrl.text = _origPrenom;
    _emailCtrl.text  = _origEmail;
    _telCtrl.text    = _origTel;
    setState(() => _editMode = false);
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text.isEmpty || _confirmPasswordCtrl.text.isEmpty) {
      _showSnack('Veuillez remplir les champs de mot de passe');
      return;
    }
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      _showSnack('Les mots de passe ne correspondent pas');
      return;
    }
    if (_newPasswordCtrl.text.length < 6) {
      _showSnack('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() => _changingPassword = true);
    try {
      final error = await _residentService.updatePassword(
        widget.userId,
        _newPasswordCtrl.text.trim(),
      );

      if (error == null) {
        _showSnack('Mot de passe modifié avec succès', success: true);
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      } else {
        _showSnack(error);
      }
    } catch (e) {
      _showSnack('Erreur : $e');
    } finally {
      setState(() => _changingPassword = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: _C.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
              style: const TextStyle(color: _C.white, fontSize: 13))),
        ]),
        backgroundColor: success ? _C.green : _C.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getInitials() {
    final prenom = _prenomCtrl.text;
    final nom    = _nomCtrl.text;
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty    ? nom[0].toUpperCase()    : '';
    return '$p$n'.isNotEmpty ? '$p$n' : 'R';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Mon Profil',
            style: TextStyle(color: _C.dark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _C.coral),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.coral))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarBanner(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Informations personnelles'),
                      const SizedBox(height: 14),
                      _buildInfoCard(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Compte'),
                      const SizedBox(height: 14),
                      _buildAccountCard(),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Sécurité'),
                      const SizedBox(height: 14),
                      _buildPasswordCard(),
                      const SizedBox(height: 32),
                      if (!_editMode)
                        _buildEditButton()
                      else
                        _buildSaveCancel(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarBanner() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.coral,
              boxShadow: [
                BoxShadow(
                    color: _C.coral.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                    color: _C.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${_prenomCtrl.text} ${_nomCtrl.text}',
            style: const TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _C.coral.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Résident',
                style: TextStyle(
                    color: _C.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: _C.textMid,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0));
  }

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        children: [
          _fieldRow(
            icon: Icons.badge_outlined,
            label: 'Prénom',
            controller: _prenomCtrl,
            enabled: _editMode,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Prénom requis' : null,
          ),
          _divider(),
          _fieldRow(
            icon: Icons.badge_outlined,
            label: 'Nom',
            controller: _nomCtrl,
            enabled: _editMode,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
          ),
          _divider(),
          _fieldRow(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            controller: _telCtrl,
            enabled: _editMode,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return _card(
      child: Column(
        children: [
          _fieldRow(
            icon: Icons.email_outlined,
            label: 'Email',
            controller: _emailCtrl,
            enabled: _editMode,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: _C.coralLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shield_outlined,
                      color: _C.coral, size: 18),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rôle',
                          style: TextStyle(
                              color: _C.textLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: 2),
                      Text('Résident',
                          style: TextStyle(
                              color: _C.dark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return _card(
      child: Column(
        children: [
          _passwordFieldRow(
            icon: Icons.lock_outline,
            label: 'Nouveau mot de passe',
            controller: _newPasswordCtrl,
          ),
          _divider(),
          _passwordFieldRow(
            icon: Icons.lock_reset,
            label: 'Confirmer le mot de passe',
            controller: _confirmPasswordCtrl,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _changingPassword ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _changingPassword
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Mettre à jour le mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => setState(() => _editMode = true),
        child: _card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: _C.coralLight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded,
                    color: _C.coral, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Modifier mon profil',
                  style: TextStyle(
                      color: _C.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: _C.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveCancel() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelEdit,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _C.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Annuler', style: TextStyle(color: _C.textMid)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enregistrer les modifications', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _divider() => Container(height: 1, color: _C.divider);

  Widget _fieldRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: enabled ? _C.coralLight : _C.bg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon,
                color: enabled ? _C.coral : _C.textLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _C.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                enabled
                    ? TextFormField(
                        controller: controller,
                        keyboardType: keyboardType,
                        validator: validator,
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        controller.text.isNotEmpty ? controller.text : '—',
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordFieldRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: _C.coralLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _C.coral, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: _C.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                TextFormField(
                  controller: controller,
                  obscureText: true,
                  style: const TextStyle(
                      color: _C.dark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
