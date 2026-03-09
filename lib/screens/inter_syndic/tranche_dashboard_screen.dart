// lib/screens/inter_syndic/tranche_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../models/tranche_model.dart';
import '../../services/tranche_service.dart';
import 'garages/garages_screen.dart';
// import autres screens...
import 'residents/residents_screen.dart';


class TrancheDashboardScreen extends StatefulWidget {
  final TrancheModel tranche;
  const TrancheDashboardScreen({super.key, required this.tranche});

  @override
  State<TrancheDashboardScreen> createState() =>
      _TrancheDashboardScreenState();
}

class _TrancheDashboardScreenState extends State<TrancheDashboardScreen> {
  final _service = TrancheService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await _service.getTrancheStats(widget.tranche.id);
    setState(() {
      _stats = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Grille de cards 2x2
                _buildCardsGrid(),
                const SizedBox(height: 16),
                // ── Résumé bas de page
                _buildResume(),
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
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.tranche.nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('Mohammed Benali • Syndic',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardsGrid() {
    final cards = [
      _CardData('Résidents', '${_stats!['nbResidents']}', 'résidents',
          Icons.people_outline, Colors.blue, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResidentsScreen(trancheId: widget.tranche.id),
              ),
            );
          }),
      _CardData('Appartements', '${widget.tranche.nombreAppartements}',
          'appartements', Icons.home_outlined, Colors.teal, null),
      _CardData('Personnel', '${_stats!['nbPersonnel']}', 'employees',
          Icons.people_alt_outlined, Colors.purple, null),
      _CardData('Finances', '${_stats!['solde']} DH', 'DH',
          Icons.wallet_outlined, Colors.orange, null),
      _CardData('Parkings', '${_stats!['nbParkings']}', 'places',
          Icons.local_parking, Colors.indigo, () {
            // Navigator.push vers ParkingsScreen
          }),
      _CardData('Garages', '${_stats!['nbGarages']}', 'places',
          Icons.garage_outlined, Colors.brown, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GaragesScreen(trancheId: widget.tranche.id),
              ),
            );
          }),
      _CardData('Box', '${_stats!['nbBoxes']}', 'box',
          Icons.inventory_2_outlined, Colors.amber, null),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildCard(cards[i]),
    );
  }

  Widget _buildCard(_CardData c) {
    return GestureDetector(
      onTap: c.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: c.onTap != null
              ? Border.all(color: const Color(0xFF8B5CF6), width: 1.5)
              : Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(c.icon, color: c.color, size: 22),
            const SizedBox(height: 4),
            Text(c.label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            Text(c.value,
                style: TextStyle(
                    color: c.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(c.subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildResume() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Résumé de la Tranche',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _resumeItem('Immeubles',
                  '${widget.tranche.nombreImmeubles}', Colors.black)),
              Expanded(child: _resumeItem('Appartements',
                  '${widget.tranche.nombreAppartements}', Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _resumeItem('Revenus',
                  '+${_stats!['revenus']} DH', Colors.green)),
              Expanded(child: _resumeItem('Dépenses',
                  '-${_stats!['depenses']} DH', Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumeItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _CardData {
  final String label, value, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  _CardData(this.label, this.value, this.subtitle,
      this.icon, this.color, this.onTap);
}