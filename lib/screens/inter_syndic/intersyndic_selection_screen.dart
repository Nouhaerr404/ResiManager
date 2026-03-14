// lib/screens/inter_syndic/intersyndic_selection_screen.dart
import 'package:flutter/material.dart';
import '../../services/tranche_service.dart';
import '../../utils/temp_session.dart';
import 'tranches_list_screen.dart';

class _C {
  static const coral = Color(0xFFE8603C);
  static const coralLight = Color(0xFFFFF0EB);
  static const bg = Color(0xFFF2F3F5);
  static const white = Color(0xFFFFFFFF);
  static const dark = Color(0xFF1A1A1A);
  static const textMid = Color(0xFF5A5A6A);
  static const textLight = Color(0xFF9A9AAF);
  static const divider = Color(0xFFE8E8F0);
}

class InterSyndicSelectionScreen extends StatefulWidget {
  const InterSyndicSelectionScreen({super.key});

  @override
  State<InterSyndicSelectionScreen> createState() => _InterSyndicSelectionScreenState();
}

class _InterSyndicSelectionScreenState extends State<InterSyndicSelectionScreen>
    with SingleTickerProviderStateMixin {
  final _service = TrancheService();
  List<Map<String, dynamic>> _syndics = [];
  bool _loading = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadSyndics();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSyndics() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAvailableInterSyndics();
      setState(() {
        _syndics = data;
        _loading = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? _buildLoader()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      children: [
                        _buildPageTitle(),
                        const SizedBox(height: 32),
                        ..._syndics.map((s) => _buildSyndicCard(s)),
                        if (_syndics.isEmpty)
                          _buildEmptyState(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _C.white,
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
                color: _C.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.divider, width: 1.5),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: _C.dark, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sélection Inter-Syndic',
            style: TextStyle(
              color: _C.dark,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Espace Inter-Syndic',
            style: TextStyle(
                color: _C.dark,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text("Choisissez un compte pour verifier la logique",
            style: TextStyle(
                color: _C.textMid, fontSize: 13, fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildSyndicCard(Map<String, dynamic> s) {
    final String nom = s['nom'] ?? '';
    final String prenom = s['prenom'] ?? '';
    final String initiales = (prenom.isNotEmpty ? prenom[0] : '') + (nom.isNotEmpty ? nom[0] : '');

    return GestureDetector(
      onTap: () {
        TempSession.interSyndicId = s['id'];
        TempSession.interSyndicNom = '$prenom $nom';
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TranchesListScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _C.coralLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initiales.toUpperCase(),
                  style: const TextStyle(
                    color: _C.coral,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$prenom $nom',
                    style: const TextStyle(
                      color: _C.dark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'Compte Inter-Syndic',
                    style: TextStyle(
                      color: _C.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _C.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() => const Center(
        child: CircularProgressIndicator(color: _C.coral, strokeWidth: 2.5),
      );

  Widget _buildEmptyState() => const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100),
          child: Text(
            'Aucun inter-syndic trouvé.',
            style: TextStyle(color: _C.textLight),
          ),
        ),
      );
}
