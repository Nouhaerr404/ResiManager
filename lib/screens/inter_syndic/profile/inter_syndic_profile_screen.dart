// lib/screens/inter_syndic/profile/inter_syndic_profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/temp_session.dart';

// ── Palette interne (cohérente avec le reste de l'espace Inter-Syndic)
class _C {
  static const coral      = Color(0xFFE8603C);
  static const coralLight = Color(0xFFFFF0EB);
  static const bg         = Color(0xFFF2F3F5);
  static const white      = Color(0xFFFFFFFF);
  static const dark       = Color(0xFF1A1A1A);
  static const textMid    = Color(0xFF5A5A6A);
  static const textLight  = Color(0xFF9A9AAF);
  static const divider    = Color(0xFFE8E8F0);
  static const green      = Color(0xFF34C98B);
  static const greenLight = Color(0xFFEBFAF4);
}

class InterSyndicProfileScreen extends StatefulWidget {
  const InterSyndicProfileScreen({super.key});

  @override
  State<InterSyndicProfileScreen> createState() =>
      _InterSyndicProfileScreenState();
}

class _InterSyndicProfileScreenState extends State<InterSyndicProfileScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  bool _editMode = false;
  bool _saving   = false;
  bool _loading  = true;

  // ── Form controllers
  final _nomCtrl       = TextEditingController();
  final _prenomCtrl    = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _telCtrl       = TextEditingController();
  final _formKey        = GlobalKey<FormState>();

  // ── Original values (for cancel)
  late String _origNom, _origPrenom, _origEmail, _origTel;

  // ── Animation
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
    super.dispose();
  }

  // ── Load profile from Supabase ──────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('users')
          .select('nom, prenom, email, telephone')
          .eq('id', TempSession.interSyndicId)
          .maybeSingle();

      if (res != null) {
        _nomCtrl.text    = res['nom']       ?? '';
        _prenomCtrl.text = res['prenom']    ?? '';
        _emailCtrl.text  = res['email']     ?? '';
        _telCtrl.text    = res['telephone'] ?? '';
      } else {
        // Fallback to TempSession values
        final parts = TempSession.interSyndicNom.split(' ');
        _prenomCtrl.text = parts.isNotEmpty ? parts.first : '';
        _nomCtrl.text    = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _emailCtrl.text  = TempSession.interSyndicEmail;
        _telCtrl.text    = TempSession.interSyndicTelephone;
      }

      _saveOriginals();
    } catch (_) {
      // Fallback silently
      final parts = TempSession.interSyndicNom.split(' ');
      _prenomCtrl.text = parts.isNotEmpty ? parts.first : '';
      _nomCtrl.text    = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _emailCtrl.text  = TempSession.interSyndicEmail;
      _telCtrl.text    = TempSession.interSyndicTelephone;
      _saveOriginals();
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

  // ── Save profile to Supabase ────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      await _supabase.from('users').update({
        'nom':       _nomCtrl.text.trim(),
        'prenom':    _prenomCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'telephone': _telCtrl.text.trim(),
      }).eq('id', TempSession.interSyndicId);

      // Update TempSession in memory
      TempSession.interSyndicNom       = '${_prenomCtrl.text.trim()} ${_nomCtrl.text.trim()}';
      TempSession.interSyndicEmail     = _emailCtrl.text.trim();
      TempSession.interSyndicTelephone = _telCtrl.text.trim();

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

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _getInitials() {
    final prenom = _prenomCtrl.text;
    final nom    = _nomCtrl.text;
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty    ? nom[0].toUpperCase()    : '';
    return '$p$n'.isNotEmpty ? '$p$n' : 'IS';
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/tranche_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.45),
                    Color.fromRGBO(0, 0, 0, 0.92),
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: _C.coral, strokeWidth: 2.5))
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 12, 20, 40),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Avatar & Name Banner
                                _buildAvatarBanner(),
                                const SizedBox(height: 28),

                                // ── Info Section
                                _buildSectionLabel('Informations personnelles'),
                                const SizedBox(height: 14),
                                _buildInfoCard(),
                                const SizedBox(height: 28),

                                // ── Account Section
                                _buildSectionLabel('Compte'),
                                const SizedBox(height: 14),
                                _buildAccountCard(),
                                const SizedBox(height: 32),

                                // ── CTA
                                if (!_editMode)
                                  _buildEditButton()
                                else
                                  _buildSaveCancel(),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
          top: top + 14, bottom: 14, left: 16, right: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: _C.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          const Text('Mon Profil',
              style: TextStyle(
                  color: _C.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.3)),
          const Spacer(),
          if (!_editMode && !_loading)
            GestureDetector(
              onTap: () => setState(() => _editMode = true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.coral,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 13, color: _C.white),
                    SizedBox(width: 6),
                    Text('Modifier',
                        style: TextStyle(
                            color: _C.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Avatar banner ─────────────────────────────────────────────────────────────
  Widget _buildAvatarBanner() {
    return Center(
      child: Column(
        children: [
          // Avatar circle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.coral,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                    color: _C.coral.withOpacity(0.4),
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
                color: _C.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text('Inter-Syndic',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0));
  }

  // ── Info Card (nom, prenom, telephone) ───────────────────────────────────────
  Widget _buildInfoCard() {
    return _glassCard(
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

  // ── Account Card (email) ──────────────────────────────────────────────────────
  Widget _buildAccountCard() {
    return _glassCard(
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
          // Role row (non-editable)
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rôle',
                          style: TextStyle(
                              color: _C.textLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _C.coralLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Inter-Syndic',
                            style: TextStyle(
                                color: _C.coral,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
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

  // ── Edit Button ───────────────────────────────────────────────────────────────
  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => setState(() => _editMode = true),
        child: _glassCard(
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

  // ── Save / Cancel ─────────────────────────────────────────────────────────────
  Widget _buildSaveCancel() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _cancelEdit,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: const Center(
                child: Text('Annuler',
                    style: TextStyle(
                        color: _C.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _saving ? null : _saveProfile,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8603C), Color(0xFFFF8C42)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: _C.coral.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: _C.white, strokeWidth: 2))
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              color: _C.white, size: 18),
                          SizedBox(width: 8),
                          Text('Enregistrer',
                              style: TextStyle(
                                  color: _C.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(height: 1, color: _C.divider);

  Widget _fieldRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(height: 2),
                enabled
                    ? TextFormField(
                        controller: controller,
                        keyboardType: keyboardType,
                        validator: validator,
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: _C.coral.withOpacity(0.5))),
                          focusedBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: _C.coral, width: 1.5)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: _C.divider, width: 1)),
                        ),
                      )
                    : Text(
                        controller.text.isNotEmpty
                            ? controller.text
                            : '—',
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
              ],
            ),
          ),
          if (enabled)
            const Icon(Icons.edit_rounded, size: 14, color: _C.coral),
        ],
      ),
    );
  }
}
