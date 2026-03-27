import 'package:flutter/material.dart';
import 'package:resimanager/widgets/main_layout.dart';
import '../../services/syndic_collaborator_service.dart';

class SyndicsManagementScreen extends StatefulWidget {
  final int residenceId;
  final int syndicId;
  const SyndicsManagementScreen({Key? key, required this.residenceId, required this.syndicId}) : super(key: key);

  @override
  _SyndicsManagementScreenState createState() => _SyndicsManagementScreenState();
}

class _SyndicsManagementScreenState extends State<SyndicsManagementScreen> {
  final SyndicCollaboratorService _service = SyndicCollaboratorService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _syndicsFuture;

  final Color primaryOrange = const Color(0xFFFF6F4A);
  final Color darkGrey = const Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    print(">>> JE DEMANDE LES SYNDICS DE LA RESIDENCE : ${widget.residenceId}");
    setState(() {
      _syndicsFuture = _service.getMyInterSyndics(widget.syndicId, widget.residenceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth >= 900;

    return MainLayout(
      title: 'Gestion des Inter-Syndics',
      activePage: 'Syndics',
      residenceId: widget.residenceId,
      syndicId: widget.syndicId,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            left: !isWeb ? 15 : 30,
            right: !isWeb ? 15 : 30,
            bottom: 30,
            top: !isWeb ? 10 : 25
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionHeader(isWeb),
            const SizedBox(height: 25),

            _buildSearchBar(),
            const SizedBox(height: 25),

            _buildTopKPIs(!isWeb),
            const SizedBox(height: 35),

            _buildSyndicsTable(!isWeb, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeader(bool isWeb) {
    if (!isWeb) {
      // Sur Mobile, on ne garde que le bouton d'ajout car le titre est déjà dans l'AppBar
      return _addButton(true);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Gestion des Inter-Syndics", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkGrey)),
          const Text("Gérez les inter-syndics et leurs affectations", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
        _addButton(false),
      ],
    );
  }

  Widget _addButton(bool isFullWidth) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ajouter un Inter-Syndic", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B65EC),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => _loadData(),
      decoration: InputDecoration(
        hintText: "Rechercher un syndic...",
        prefixIcon: const Icon(Icons.search),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTopKPIs(bool isMobile) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _syndicsFuture,
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        int actifs = list.where((s) => s['statut'] == 'actif').length;

        return Wrap(
          spacing: 15, runSpacing: 15,
          children: [
            _kpiCard("Total Syndics", list.length.toString(), darkGrey),
            _kpiCard("Syndics Actifs", actifs.toString(), Colors.green),
            _kpiCard("Syndics Inactifs", (list.length - actifs).toString(), Colors.red),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String t, String v, Color c) {
    return Container(
      width: 180, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(v, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c)),
      ]),
    );
  }

  Widget _buildSyndicsTable(bool isMobile, double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _syndicsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()));
          final list = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 60, dataRowHeight: 90,
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
              columns: const [
                DataColumn(label: Text('SYNDIC')),
                DataColumn(label: Text('CONTACT')),
                DataColumn(label: Text('TRANCHES AFFECTÉES')),
                DataColumn(label: Text('STATUT')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: list.map((s) => DataRow(cells: [
                DataCell(_buildSyndicCell(s)),
                DataCell(_buildContactCell(s)),
                DataCell(_buildTranchesCell(s['tranches'])),
                DataCell(_buildStatusBadge(s['statut'])),
                DataCell(_buildActions(s)),
              ])).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyndicCell(Map<String, dynamic> s) {
    return Row(children: [
      CircleAvatar(
          backgroundColor: Colors.blue.shade700,
          child: Text(s['nom'][0], style: const TextStyle(color: Colors.white))
      ),
      const SizedBox(width: 12),
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("${s['prenom']} ${s['nom']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text("Depuis ${s['created_at'].toString().substring(0, 10)}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ])
    ]);
  }

  Widget _buildContactCell(Map<String, dynamic> s) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.email_outlined, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(s['email'], style: const TextStyle(fontSize: 12))]),
      Row(children: [const Icon(Icons.phone_outlined, size: 14, color: Colors.grey), const SizedBox(width: 5), Text(s['telephone'] ?? "--", style: const TextStyle(fontSize: 12))]),
    ]);
  }

  Widget _buildTranchesCell(dynamic tranchesData) {
    if (tranchesData == null || tranchesData is! List || tranchesData.isEmpty) {
      return const Text("Aucune affectation", style: TextStyle(color: Colors.grey, fontSize: 12));
    }
    final List filteredTranches = tranchesData.where((t) => t['residence_id'] == widget.residenceId).toList();
    if (filteredTranches.isEmpty) {
      return const Text("Non affecté ici", style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filteredTranches.map((t) => Text("• ${t['nom']}", style: const TextStyle(fontSize: 11))).toList(),
    );
  }
  Widget _buildStatusBadge(String status) {
    bool isActive = status == 'actif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(isActive ? "Actif" : "Inactif", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildActions(Map<String, dynamic> s) {
    return Row(children: [
      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20), onPressed: () => _showForm(syndic: s)),
      IconButton(
        icon: Icon(s['statut'] == 'actif' ? Icons.block : Icons.check_circle_outline, color: primaryOrange, size: 20),
        onPressed: () async {
          await _service.toggleStatus(s['id'], s['statut']);
          _loadData();
        },
      ),
    ]);
  }

  void _showForm({Map<String, dynamic>? syndic}) {
    final bool isEdit = syndic != null;
    bool isLoading = false;

    final nomController = TextEditingController(text: isEdit ? syndic['nom'] : '');
    final prenomController = TextEditingController(text: isEdit ? syndic['prenom'] : '');
    final emailController = TextEditingController(text: isEdit ? syndic['email'] : '');
    final phoneController = TextEditingController(text: isEdit ? syndic['telephone'] : '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            isEdit ? "Modifier le profil" : "Nouveau Syndic",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: darkGrey),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("Prénom"),
                TextField(
                  controller: prenomController,
                  decoration: _buildInputDecoration("Prénom de l'inter-syndic"),
                ),
                const SizedBox(height: 15),

                _buildFieldLabel("Nom"),
                TextField(
                  controller: nomController,
                  decoration: _buildInputDecoration("Nom de famille"),
                ),
                const SizedBox(height: 15),

                _buildFieldLabel("Email professionnel"),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration("exemple@syndic.ma"),
                ),
                const SizedBox(height: 15),

                _buildFieldLabel("Téléphone"),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration("+212 6..."),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (nomController.text.trim().isEmpty || prenomController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir le Prénom, le Nom et l'Email"), backgroundColor: Colors.orange));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        if (isEdit) {
                          await _service.updateInterSyndic(
                            syndic['id'], 
                            nomController.text.trim(), 
                            prenomController.text.trim(), 
                            emailController.text.trim(),
                            phoneController.text.trim()
                          );
                        } else {
                          await _service.createAndInviteSyndic(
                            email: emailController.text.trim(), 
                            nom: nomController.text.trim(), 
                            prenom: prenomController.text.trim(), 
                            telephone: phoneController.text.trim(), 
                            mySyndicGeneralId: widget.syndicId, 
                            residenceId: widget.residenceId,
                          );
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Modifié avec succès" : "Syndic ajouté avec succès"), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}"), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(vertical: 15), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(isEdit ? "Enregistrer" : "Ajouter", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A4E69))));
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8F9FA), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryOrange, width: 1.5)));
  }
}