// lib/screens/inter_syndic/tranches_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import '../../utils/temp_session.dart';
import 'tranche_dashboard_screen.dart';

class TranchesListScreen extends StatefulWidget {
  const TranchesListScreen({super.key});
  @override
  State<TranchesListScreen> createState() => _TranchesListScreenState();
}

class _TranchesListScreenState extends State<TranchesListScreen> {
  final _service = TrancheService();
  List<TrancheModel> _tranches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTranches();
  }

  Future<void> _loadTranches() async {
    setState(() => _loading = true);
    try {
      final data = await _service
          .getTranchesOfInterSyndic(TempSession.interSyndicId)
          .timeout(const Duration(seconds: 10));

      print('>>> Tranches reçues: ${data.length}');
      setState(() {
        _tranches = data;
        _loading = false;
      });
    } catch (e) {
      print('>>> ERREUR _loadTranches: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Header
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Banner violet
                _buildBanner(),
                const SizedBox(height: 16),
                // ── Liste des tranches
                ..._tranches.map(_buildTrancheCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ResiManager',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Espace Syndic',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.apartment, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          Text('${_tranches.length}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
          const Text('Tranches affectées',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTrancheCard(TrancheModel t) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrancheDashboardScreen(tranche: t),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.apartment, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.nom,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (t.description != null)
                    Text(t.description!,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  // ── Badges
                  Wrap(
                    spacing: 6,
                    children: [
                      _badge('${t.nombreImmeubles} immeubles',
                          const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
                      _badge('${t.nombreAppartements} appts',
                          const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                      _badge('${t.nombreParkings} parkings',
                          const Color(0xFFFED7AA), const Color(0xFFEA580C)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}