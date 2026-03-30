import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../services/finance_service.dart';
import '../../../widgets/kpi_card.dart';
import 'add_tranche_expense_screen.dart';
import '../../../services/expense_report_pdf_service.dart';
import '../../../models/tranche_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceDashboardScreen extends StatefulWidget {
  final int residenceId;
  final int interSyndicId;
  final int? trancheId;
  const FinanceDashboardScreen({
    Key? key,
    required this.residenceId,
    required this.interSyndicId,
    this.trancheId,
  }) : super(key: key);

  @override
  _FinanceDashboardScreenState createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  final FinanceService _service = FinanceService();
  late Future<Map<String, dynamic>> _financesFuture;
  List<Map<String, dynamic>> _mandats = [];
  Map<String, dynamic>? _selectedMandat;
  bool _loadingMandats = true;
  String _residenceNom = "Chargement...";
  String _trancheNom = "";
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    // Initialisation immédiate pour éviter LateInitializationError lors du premier build
    _financesFuture = _service.getInterSyndicFinances(
      widget.interSyndicId, 
      widget.residenceId, 
      trancheId: widget.trancheId,
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final mandats = await _service.getInterSyndicMandates(widget.interSyndicId, widget.residenceId);
      
      // Fetch residence and tranche names
      final db = Supabase.instance.client;
      final resData = await db.from('residences').select('nom').eq('id', widget.residenceId).single();
      String tNom = "";
      if (widget.trancheId != null) {
        final tData = await db.from('tranches').select('nom').eq('id', widget.trancheId!).single();
        tNom = tData['nom'];
      }

      if (mounted) {
        setState(() {
          _mandats = mandats;
          _residenceNom = resData['nom'];
          _trancheNom = tNom;
          if (_mandats.isNotEmpty) {
            _selectedMandat = _mandats.first;
          }
          _loadingMandats = false;
          _isDataLoaded = true;
          _refresh();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMandats = false;
          _isDataLoaded = true;
        });
      }
    }
  }

  void _refresh() {
    setState(() {
      _financesFuture = _service.getInterSyndicFinances(
          widget.interSyndicId, 
          widget.residenceId, 
          startDate: _selectedMandat?['date_debut'],
          endDate: _selectedMandat?['date_fin'],
          trancheId: widget.trancheId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/tranche_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.20),
                    Color.fromRGBO(0, 0, 0, 0.90),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _financesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !_isDataLoaded) {
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      }
                      final data = snapshot.data ?? {};
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                        children: [
                          _buildPageTitle(),
                          const SizedBox(height: 24),
                          _buildStatsSection(data),
                          const SizedBox(height: 30),
                          _buildExpensesTable(data),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'IS';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Widget _buildPageTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Finance',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 34,
              letterSpacing: -1.0),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _trancheNom.isNotEmpty ? "$_residenceNom - $_trancheNom" : _residenceNom,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_selectedMandat != null)
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                "Mandat actuel : ${_selectedMandat!['date_debut'].toString().split('-')[0]}/${_selectedMandat!['date_fin']?.toString().split('-')[0] ?? '...'}",
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> data) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 500;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Résumé Financier", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            IconButton(
              onPressed: () => _refresh(),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildKpiGrid(data),
        const SizedBox(height: 20),
        isSmallScreen 
          ? Column(
              children: [
                _buildMandatPicker(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _buildAddButton(),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildMandatPicker()),
                const SizedBox(width: 10),
                _buildAddButton(),
              ],
            ),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6F4A),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTrancheExpenseScreen(residenceId: widget.residenceId, interSyndicId: widget.interSyndicId))).then((_) => _refresh()),
      icon: const Icon(Icons.add, color: Colors.white, size: 20),
      label: const Text("Nouvelle Dépense", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Gestion Finance",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2),
              ),
              Text('Rapports & Dépenses',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _generatePDF(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24)),
              child: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6F4A))),
    );

    try {
      final res = await _service.getInterSyndicFinances(
        widget.interSyndicId,
        widget.residenceId,
        startDate: _selectedMandat?['date_debut'],
        endDate: _selectedMandat?['date_fin'],
        trancheId: widget.trancheId,
      );

      // Fetch residence and tranche names
      final db = Supabase.instance.client;
      final resData = await db.from('residences').select('nom').eq('id', widget.residenceId).single();
      String trancheNom = "Toutes les tranches";
      if (widget.trancheId != null) {
        final tData = await db.from('tranches').select('nom').eq('id', widget.trancheId!).single();
        trancheNom = tData['nom'];
      }

      final start = _selectedMandat?['date_debut'].toString().split('-').reversed.join('/');
      final end = _selectedMandat?['date_fin']?.toString().split('-').reversed.join('/') ?? 'En cours';
      final mandatLabel = _selectedMandat != null ? "$start au $end" : DateTime.now().year.toString();

      final bytes = await ExpenseReportPdfService.generate(
        residenceNom: resData['nom'],
        trancheNom: trancheNom,
        mandatLabel: mandatLabel,
        financeData: res,
      );

      if (mounted) {
        Navigator.pop(context);
        await ExpenseReportPdfService.preview(bytes);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur PDF: $e")));
      }
    }
  }

  Widget _buildMandatPicker() {
    if (_loadingMandats) return const SizedBox();
    if (_mandats.isEmpty) {
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
         decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.1), 
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.white12)
         ),
         child: const Text("Aucun mandat", style: TextStyle(color: Colors.white70, fontSize: 12)),
       );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButton<Map<String, dynamic>>(
        value: _selectedMandat,
        dropdownColor: const Color(0xFF1A1A1A),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 20),
        isExpanded: true,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        items: _mandats.map((m) {
          final start = m['date_debut'].toString().split('-').reversed.join('/');
          final end = m['date_fin']?.toString().split('-').reversed.join('/') ?? 'En cours';
          final trancheNom = m['tranches']?['nom'] ?? 'Tranche';
          return DropdownMenuItem<Map<String, dynamic>>(
            value: m,
            child: Text("$trancheNom : $start → $end", style: const TextStyle(fontSize: 12)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedMandat = val;
              _refresh();
            });
          }
        },
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(
              title: 'Solde Tranche',
              value: '${data['solde']?.toStringAsFixed(0) ?? 0}',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.blue,
              width: width,
            ),
            _statCard(
              title: 'Revenus',
              value: '${data['total_revenus']?.toStringAsFixed(0) ?? 0}',
              icon: Icons.trending_up_rounded,
              color: Colors.green,
              width: width,
            ),
            _statCard(
              title: 'Dépenses Tranche',
              value: '${data['total_depenses']?.toStringAsFixed(0) ?? 0}',
              icon: Icons.trending_down_rounded,
              color: Colors.red,
              width: width,
            ),
            _statCard(
              title: 'Dépenses Globales',
              value: '${data['total_depenses_globales']?.toStringAsFixed(0) ?? 0}',
              icon: Icons.public_rounded,
              color: Colors.orange,
              width: width,
            ),
          ],
        );
      }
    );
  }

  Widget _statCard({required String title, required String value, required IconData icon, required Color color, required double width}) {
    return GlassCard(
      width: width,
      padding: const EdgeInsets.all(16),
      color: Colors.white.withOpacity(0.9),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.black26),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(width: 4),
              const Text("DH", style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTable(Map<String, dynamic> data) {
    final List<dynamic> expenses = data['recent_expenses'] ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dépenses de la Tranche",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))),
              Text(_selectedMandat != null 
                ? "${_selectedMandat!['date_debut'].toString().split('-')[0]}/${_selectedMandat!['date_fin']?.toString().split('-')[0] ?? '?'}" 
                : "Toutes", 
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          if (expenses.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Aucune dépense enregistrée"),
            ))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                horizontalMargin: 0,
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Justificatif', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: expenses.map((e) {
                  final bool hasFacture = e['facture_path'] != null && e['facture_path'].toString().isNotEmpty;
                  return DataRow(cells: [
                    DataCell(Text(e['date'].toString())),
                    DataCell(Text(e['categorie_nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(e['description'], style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text(e['tranche'], style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    )),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: e['type'] == 'Globale' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(e['type'], style: TextStyle(
                        fontSize: 11,
                        color: e['type'] == 'Globale' ? Colors.blue : Colors.orange.shade800,
                        fontWeight: FontWeight.bold
                      )),
                    )),
                    DataCell(Text('${e['montant'].toStringAsFixed(0)} DH', style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      hasFacture
                        ? InkWell(
                            onTap: () => _showInvoicePopup(e['facture_path']),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text("Oui", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                                const Icon(Icons.receipt_long, color: Color(0xFFFF6F4A), size: 14),
                              ],
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.cancel, color: Colors.grey, size: 16),
                              SizedBox(width: 4),
                              Text("Non", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (e['type'] == 'Spécifique') ...[
                            IconButton(
                              tooltip: "Modifier",
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddTrancheExpenseScreen(
                                    residenceId: widget.residenceId,
                                    interSyndicId: widget.interSyndicId,
                                    expenseData: e,
                                  ),
                                ),
                              ).then((_) => _refresh()),
                            ),
                            IconButton(
                              tooltip: "Supprimer",
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              onPressed: () => _showDeleteConfirmation(e),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(left: 12.0),
                              child: Icon(Icons.lock, size: 16, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la dépense ?"),
        content: Text("Voulez-vous vraiment supprimer cette dépense de ${expense['montant']} DH ? Les charges des résidents seront ajustées automatiquement."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteInterSyndicExpense(expense['id'], expense['montant']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dépense supprimée avec succès')),
                  );
                }
                _refresh();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la suppression : $e')),
                  );
                }
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showInvoicePopup(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: url.startsWith('http')
                      ? Image.network(
                          url,
                          loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                          errorBuilder: (context, error, stack) => const Center(child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text("Erreur de chargement de l'image (Réseau)"),
                          )),
                        )
                      : Image.asset(
                          'assets/images/$url',
                          errorBuilder: (context, error, stack) => Center(child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text("Image introuvable dans assets/images/\nFichier: $url", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                          )),
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Fermer")),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final Color color;
  final BoxBorder? border;
  final double? width;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.color = const Color.fromRGBO(255, 255, 255, 0.08),
    this.border,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

