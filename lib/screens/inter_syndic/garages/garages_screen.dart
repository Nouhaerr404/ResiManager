import 'package:flutter/material.dart';
import '../../../models/garage_model.dart';
import '../../../services/garage_service.dart';

class GaragesScreen extends StatefulWidget {
  final int trancheId;
  const GaragesScreen({super.key, required this.trancheId});

  @override
  State<GaragesScreen> createState() => _GaragesScreenState();
}

class _GaragesScreenState extends State<GaragesScreen> {
  final _service = GarageService();
  List<GarageModel> _garages = [];
  List<GarageModel> _filtered = [];
  bool _loading = true;
  String _filterStatut = 'tous';
  final _searchCtrl = TextEditingController();

  static const _purple = Color(0xFF8B5CF6);
  static const _bg = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service
          .getGaragesByTranche(widget.trancheId)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _garages = data;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      debugPrint('>>> ERREUR load garages: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _garages.where((g) {
        final matchSearch = g.numero.toLowerCase().contains(q) ||
            (g.beneficiaireNom?.toLowerCase().contains(q) ?? false);
        final matchStatut = _filterStatut == 'tous' ||
            g.statut == _filterStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _filterStatut = f);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final total = _garages.length;
    final disponibles = _garages.where((g) => g.statut == 'disponible').length;
    final revenus = _garages
        .where((g) => g.statut == 'occupe')
        .fold(0.0, (sum, g) => sum + g.prixAnnuel);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(color: _purple))
                  : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats
                  Row(children: [
                    _statCard(Icons.garage_outlined, '$total',
                        'Total', Colors.purple),
                    const SizedBox(width: 10),
                    _statCard(Icons.check_circle_outline,
                        '$disponibles', 'Disponibles', Colors.green),
                    const SizedBox(width: 10),
                    _statCard(Icons.attach_money,
                        '${revenus.toInt()}', 'DH/an', Colors.orange),
                  ]),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterTabs(),
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Text('Aucun garage',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._filtered.map(_buildGarageCard),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Garages',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Gestion des garages',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddGarageDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label,
              style:
              const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: _searchCtrl,
        decoration: const InputDecoration(
          hintText: 'Rechercher un garage...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      ('tous', 'Tous'),
      ('disponible', 'Disponibles'),
      ('occupe', 'Occupés'),
    ];
    return Row(
      children: filters.map((f) {
        final isSelected = _filterStatut == f.$1;
        return GestureDetector(
          onTap: () => _setFilter(f.$1),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _purple : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(f.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGarageCard(GarageModel g) {
    final isOccupe = g.statut == 'occupe';
    final statusColor = isOccupe ? Colors.orange : Colors.green;
    final statusLabel = isOccupe ? 'occupé' : 'disponible';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.garage_outlined,
              color: Colors.orange.shade400),
        ),
        title: Row(children: [
          Text(g.numero,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${g.prixAnnuel.toInt()} DH/an',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            if (g.beneficiaireNom != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(g.beneficiaireNom!,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: g.beneficiaireType == 'resident'
                        ? Colors.blue.shade50
                        : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    g.beneficiaireType == 'resident'
                        ? 'Résident'
                        : 'Externe',
                    style: TextStyle(
                      color: g.beneficiaireType == 'resident'
                          ? Colors.blue
                          : Colors.purple,
                      fontSize: 10,
                    ),
                  ),
                ),
              ]),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (val) {
            if (val == 'modifier') _showEditGarageDialog(g);
            if (val == 'assigner') _showAssignerDialog(g);
            if (val == 'liberer') _showLiberDialog(g);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'modifier',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 16),
                SizedBox(width: 8),
                Text('Modifier'),
              ]),
            ),
            if (!isOccupe)
              const PopupMenuItem(
                value: 'assigner',
                child: Row(children: [
                  Icon(Icons.person_add_outlined,
                      size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Assigner',
                      style: TextStyle(color: Colors.blue)),
                ]),
              ),
            if (isOccupe)
              const PopupMenuItem(
                value: 'liberer',
                child: Row(children: [
                  Icon(Icons.person_remove_outlined,
                      size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Libérer',
                      style: TextStyle(color: Colors.red)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // DIALOG : Ajouter garage
  // ══════════════════════════════════════
  void _showAddGarageDialog() {
    final numeroCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: '600');
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ajouter Garage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),

                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(errorMsg!,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                _label('Numéro *'),
                _field(numeroCtrl, 'ex: G-A06'),
                const SizedBox(height: 12),

                _label('Prix annuel (DH) *'),
                _field(prixCtrl, 'ex: 600',
                    inputType: TextInputType.number),
                const SizedBox(height: 24),

                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving
                          ? null
                          : () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                        if (numeroCtrl.text.trim().isEmpty) {
                          setDialog(() => errorMsg =
                          'Numéro obligatoire');
                          return;
                        }
                        setDialog(() {
                          saving = true;
                          errorMsg = null;
                        });
                        final err = await _service.addGarage(
                          numero: numeroCtrl.text.trim(),
                          trancheId: widget.trancheId,
                          residenceId: 1,
                          prixAnnuel: double.tryParse(
                              prixCtrl.text) ??
                              600,
                        );
                        if (!ctx.mounted) return;
                        if (err != null) {
                          setDialog(() {
                            errorMsg = err;
                            saving = false;
                          });
                        } else {
                          Navigator.pop(ctx);
                          _load();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                      ),
                      child: saving
                          ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2))
                          : const Text('Ajouter'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // DIALOG : Modifier garage
  // ══════════════════════════════════════
  void _showEditGarageDialog(GarageModel g) {
    final numeroCtrl = TextEditingController(text: g.numero);
    final prixCtrl =
    TextEditingController(text: g.prixAnnuel.toInt().toString());
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Modifier Garage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Numéro'),
                _field(numeroCtrl, ''),
                const SizedBox(height: 12),
                _label('Prix annuel (DH)'),
                _field(prixCtrl, '',
                    inputType: TextInputType.number),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                        setDialog(() => saving = true);
                        await _service.updateGarage(
                          garageId: g.id,
                          numero: numeroCtrl.text.trim(),
                          prixAnnuel: double.tryParse(
                              prixCtrl.text) ??
                              g.prixAnnuel,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _load();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                      ),
                      child: saving
                          ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2))
                          : const Text('Enregistrer'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // DIALOG : Assigner garage
  // ══════════════════════════════════════
  void _showAssignerDialog(GarageModel g) {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    String typebenef = 'resident';
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Assigner ${g.numero}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),

                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(errorMsg!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                ],

                // Type bénéficiaire
                _label('Type de bénéficiaire'),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => typebenef = 'resident'),
                      child: _typeBtn(
                          'Résident', typebenef == 'resident'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => typebenef = 'externe'),
                      child: _typeBtn(
                          'Externe', typebenef == 'externe'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                _label('Prénom *'),
                _field(prenomCtrl, 'ex: Ahmed'),
                const SizedBox(height: 12),
                _label('Nom *'),
                _field(nomCtrl, 'ex: Bennani'),
                const SizedBox(height: 12),
                _label('Téléphone'),
                _field(telCtrl, 'ex: 0612345678',
                    inputType: TextInputType.phone),
                const SizedBox(height: 24),

                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                        if (nomCtrl.text.trim().isEmpty ||
                            prenomCtrl.text
                                .trim()
                                .isEmpty) {
                          setDialog(() => errorMsg =
                          'Nom et Prénom obligatoires');
                          return;
                        }
                        setDialog(() {
                          saving = true;
                          errorMsg = null;
                        });
                        final err =
                        await _service.assignerGarage(
                          garageId: g.id,
                          nom: nomCtrl.text.trim(),
                          prenom: prenomCtrl.text.trim(),
                          telephone: telCtrl.text.isEmpty
                              ? null
                              : telCtrl.text.trim(),
                          type: typebenef,
                          trancheId: widget.trancheId,
                        );
                        if (!ctx.mounted) return;
                        if (err != null) {
                          setDialog(() {
                            errorMsg = err;
                            saving = false;
                          });
                        } else {
                          Navigator.pop(ctx);
                          _load();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                      ),
                      child: saving
                          ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2))
                          : const Text('Assigner'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // DIALOG : Libérer garage
  // ══════════════════════════════════════
  void _showLiberDialog(GarageModel g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Libérer le garage'),
        content: Text(
            'Libérer ${g.numero} actuellement assigné à ${g.beneficiaireNom ?? "?"} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.libererGarage(g.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Libérer'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _purple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: 3,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Résidents'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              label: 'Personnel'),
          BottomNavigationBarItem(
              icon: Icon(Icons.wallet_outlined), label: 'Finances'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_parking), label: 'Parkings'),
        ],
        onTap: (i) {},
      ),
    );
  }

  // ══════════════════════════════════════
  // HELPERS UI
  // ══════════════════════════════════════
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 13)),
  );

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType inputType = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: inputType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
            BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
        ),
      );

  Widget _typeBtn(String label, bool selected) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(
        color: selected ? _purple : Colors.grey.shade300,
        width: selected ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? _purple : Colors.black87,
          fontWeight: selected
              ? FontWeight.bold
              : FontWeight.normal,
        )),
  );
}