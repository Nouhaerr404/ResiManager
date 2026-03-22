import 'package:flutter/material.dart';
import '../../services/resident_service.dart';
import 'resident_dashboard_screen.dart'; // ← GARDE
import 'package:url_launcher/url_launcher.dart';
class ResidentChargesScreen extends StatefulWidget {
  final int userId;
  final Function(int)? onNavigate;
  const ResidentChargesScreen({
    super.key,
    this.userId = 3,
    this.onNavigate,
  });

  @override
  _ResidentChargesScreenState createState() => _ResidentChargesScreenState();
}

class _ResidentChargesScreenState extends State<ResidentChargesScreen> {
  final ResidentService _service = ResidentService();
  String _filter = "Toutes";
  String _searchQuery = "";
  int _selectedAnnee = DateTime.now().year;

  static const _coral = Color(0xFFFF6B4A);
  static const _dark = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final bool inLayout = widget.onNavigate != null;

    final body = FutureBuilder<Map<String, dynamic>>(
      future: _service.getTrancheExpensesDetailed(widget.userId, _selectedAnnee),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _coral));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.orange.shade400, size: 48),
                const SizedBox(height: 16),
                const Text("Aucune dépense disponible",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text("Sélectionnez une autre année",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 20),
                _buildAnneeSelector(),
              ],
            ),
          );
        }


        final data = snapshot.data!;
        final List allDeps = data['depenses'];

        final filteredDeps = allDeps.where((d) {
          bool matchesSearch = (d['description']?.toString() ?? d['categories']?['nom'] ?? "")
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
          bool isPaye = d['facture_path'] != null;
          bool matchesFilter = _filter == "Toutes" ||
              (_filter == "Payées" && isPaye) ||
              (_filter == "En attente" && !isPaye);
          return matchesSearch && matchesFilter;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Dépenses", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
                    Text(data['tranche_nom'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  ]),
                  _buildAnneeSelector(),
                ],
              ),
              const SizedBox(height: 20),
              _buildKpis(data),
              const SizedBox(height: 24),
              _buildSearchAndFilters(allDeps),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: 820,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    _buildTableHeader(),
                    ...filteredDeps.asMap().entries.map((e) => _buildTableRow(e.value, e.key)).toList(),
                    _buildTableFooter(((data['total'] as num?) ?? 0).toInt()),

                  ]),
                ),
              ),

            ],
          ),
        );
      },
    );

    if (inLayout) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        title: const Text("Dépenses de la Tranche",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: _coral),
      ),
      drawer: ResidentMobileDrawer(currentIndex: 1, userId: widget.userId),
      body: body,
    );
  }

  Widget _buildAnneeSelector() {
    final List<int> annees = List.generate(5, (i) => DateTime.now().year - i);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedAnnee,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          isDense: true,
          items: annees.map((y) => DropdownMenuItem(
            value: y,
            child: Text(y.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          )).toList(),
          onChanged: (v) => setState(() => _selectedAnnee = v!),
        ),
      ),
    );
  }

  Widget _buildKpis(Map data) {
    return Row(children: [
      Expanded(child: _kpiCard("Total Tranche",
          "${((data['total'] as num?) ?? 0).toInt()} DH",
          Icons.account_balance_wallet_outlined, _dark, const Color(0xFFEEF2FF))),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard("Payé",
          "${((data['payees'] as num?) ?? 0).toInt()} DH",
          Icons.check_circle_outline, Colors.green, const Color(0xFFECFDF5))),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard("En attente",
          "${((data['attente'] as num?) ?? 0).toInt()} DH",
          Icons.timer_outlined, _coral, const Color(0xFFFFF5F3))),
    ]);
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _buildSearchAndFilters(List all) {
    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: "Rechercher une dépense...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        _filterChip("Toutes", all.length),
        _filterChip("Payées", all.where((e) => e['facture_path'] != null).length),
        _filterChip("En attente", all.where((e) => e['facture_path'] == null).length),
      ]),
    ]);
  }

  Widget _filterChip(String label, int count) {
    bool isSel = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? _dark : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isSel ? _dark : Colors.grey.shade200),
            boxShadow: isSel ? [BoxShadow(color: _dark.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Text("$label ($count)",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_dark, Color(0xFF16213E)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(children: const [
        Expanded(flex: 1, child: Text("TYPE",style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 3, child: Text("DESCRIPTION", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 2, child: Text("PORTÉE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 2, child: Text("DATE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 2, child: Text("MONTANT", textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 2, child: Text("STATUT", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
        Expanded(flex: 1, child: Text("FACTURE", textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
      ]),
    );
  }

  Widget _buildTableRow(Map d, int index) {
    String catName = d['categories']?['nom'] ?? "Charge";
    String description = d['description']?.toString() ?? catName;
    bool isCommune = d['categories']?['type'] == 'globale';
    bool isPaye = d['facture_path'] != null;
    final bg = index.isEven ? Colors.white : const Color(0xFFFAFAFC);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        Expanded(flex: 1, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8)),
          child: Text(
            catName,
            style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        )),

        // ✅ CORRECT
        Expanded(flex: 3, child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        )),
        Expanded(flex: 2, child: _badge(isCommune ? "Commune" : "Individuelle",
            isCommune ? const Color(0xFF7C5CBF) : const Color(0xFFEA8C00))),
        Expanded(flex: 2, child: Text(d['date'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
        Expanded(flex: 2, child: Text("${d['montant']} DH",
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(flex: 2, child: _statusBadge(isPaye)),
        Expanded(flex: 1, child: IconButton(
          icon: Icon(
            d['facture_path'] != null
                ? Icons.receipt_long_rounded
                : Icons.visibility_outlined,
            size: 18,
            color: d['facture_path'] != null
                ? Colors.red.shade400
                : Colors.grey.shade300,
          ),
          onPressed: () => _showFacture(d),
          alignment: Alignment.centerRight,
        )),
      ]),
    );
  }

  Widget _buildTableFooter(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_coral, Color(0xFFFF8C42)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text("TOTAL TOUTES LES DÉPENSES",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
        Text("$total DH",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      ]),
    );
  }

  Widget _badge(String t, Color c) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Text(t, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    ),
  );

  Widget _statusBadge(bool paye) {
    Color c = paye ? Colors.green : Colors.orange;
    Color bg = paye ? Colors.green.shade50 : Colors.orange.shade50;
    return Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(paye ? Icons.check_circle : Icons.schedule, size: 11, color: c),
        const SizedBox(width: 4),
        Text(paye ? "Payé" : "En attente",
            style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    ));
  }

  IconData _getIcon(String label) {
    if (label.contains("Sécurité")) return Icons.security;
    if (label.contains("Jardin")) return Icons.park;
    if (label.contains("Eau")) return Icons.opacity;
    return Icons.receipt_long;
  }

  void _showFacture(Map d) async {
    final String? url = d['facture_path']?.toString();

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune facture disponible'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // ── Afficher dans un dialog ──
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),

                const SizedBox(width: 10),
                Expanded(child: Text(
                  d['description']?.toString() ?? 'Facture',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                )),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 20),
                ),
              ]),
            ),

            // ── IMAGE/PDF ──
            Container(
              constraints: const BoxConstraints(
                  maxHeight: 500, maxWidth: 600),
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: Color(0xFFFF6B4A)),
                    );
                  },
                  errorBuilder: (ctx, error, stack) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Icon(Icons.broken_image_outlined,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('Format non supporté',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      // ── Bouton ouvrir dans navigateur ──
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_browser, size: 16),
                        label: const Text('Ouvrir dans le navigateur'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B4A)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            // ── FOOTER ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Agrandir'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B4A),
                      foregroundColor: Colors.white),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
}
}
//karim.moussaoui99@gmail.com
//hashed_password