import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import '../../widgets/resident_nav_bar.dart';

class ResidentPaymentScreen extends StatelessWidget {
  final ResidentService _service = ResidentService();
  final int userId = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text("État de mes Paiements", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFFF6B4A)),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 1),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _service.getYearlyPaymentStatus(userId, 2026),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final List historique = data['historique'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- LA GRANDE CARTE NOIRE (MAQUETTE) ---
                _buildMainPaymentCard(data),
                const SizedBox(height: 30),

                // --- HISTORIQUE DES PAIEMENTS ---
                const Text("Historique des règlements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ...historique.map((h) => _buildHistoryItem(h)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainPaymentCard(Map data) {
    double prog = data['progression'] ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              SizedBox(width: 15),
              Text("Cotisation Annuelle 2026", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25),

          // Grille de chiffres
          Row(
            children: [
              _miniCard("Total annuel", "${data['total_annuel']} DH", Colors.white10),
              const SizedBox(width: 10),
              _miniCard("Déjà payé", "${data['deja_paye']} DH", Colors.green.withOpacity(0.2), textColor: Colors.greenAccent),
              const SizedBox(width: 10),
              _miniCard("Reste", "${data['reste_a_payer']} DH", Colors.red.withOpacity(0.2), textColor: Colors.redAccent),
            ],
          ),

          const SizedBox(height: 30),

          // Barre de progression
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progression annuelle", style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text("${(prog * 100).toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: prog,
            backgroundColor: Colors.white12,
            color: Colors.greenAccent,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),

          const SizedBox(height: 25),

          // Alerte Paiement Partiel
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Text("Paiement partiel : Il reste ${data['reste_a_payer']} DH à régler", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _miniCard(String label, String val, Color bg, {Color textColor = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            const SizedBox(height: 5),
            Text(val, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(h['description'] ?? "Règlement charges", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Date : ${h['date']}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          Text("+ ${h['montant']} DH", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}