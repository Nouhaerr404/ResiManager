import 'package:flutter/material.dart';
import '../../../models/resident_model.dart';
import '../../../services/resident_service.dart';

class ResidentsScreen extends StatefulWidget {
  final int trancheId;
  const ResidentsScreen({super.key, required this.trancheId});

  @override
  State<ResidentsScreen> createState() => _ResidentsScreenState();
}

class _ResidentsScreenState extends State<ResidentsScreen> {
  final _service = ResidentService();
  List<ResidentModel> _residents = [];
  List<ResidentModel> _filtered = [];
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
          .getResidentsByTranche(widget.trancheId)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _residents = data;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      print('>>> ERREUR _load: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _residents.where((r) {
        final matchSearch =
            r.nomComplet.toLowerCase().contains(q) ||
                (r.appartementNumero?.toLowerCase().contains(q) ??
                    false);
        final matchStatut = _filterStatut == 'tous' ||
            r.statutPaiement == _filterStatut;
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
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: _purple))
                  : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterTabs(),
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Text('Aucun résident',
                            style: TextStyle(
                                color: Colors.grey)),
                      ),
                    )
                  else
                    ..._filtered.map(_buildResidentCard),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apartment,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ResiManager',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('Espace Syndic',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showAddResidentDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // SEARCH BAR
  // ══════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: const InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // FILTER TABS
  // ══════════════════════════════════════
  Widget _buildFilterTabs() {
    final filters = [
      ('tous', 'Tous'),
      ('complet', 'Complets'),
      ('partiel', 'Partiels'),
      ('impaye', 'Impayés'),
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
                  color:
                  isSelected ? Colors.white : Colors.black87,
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

  // ══════════════════════════════════════
  // RESIDENT CARD
  // ══════════════════════════════════════
  Widget _buildResidentCard(ResidentModel r) {
    final pct = r.pourcentagePaiement;
    final Color barColor = pct >= 1.0
        ? Colors.green
        : pct > 0
        ? Colors.orange
        : Colors.red;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nom + badges + actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.nomComplet,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(r.adresseAppart,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                _badgeType(r.type),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showEditDialog(r),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.grey, size: 18),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showDeleteConfirm(r),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Paiement label + %
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paiement ${r.anneePaiement}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                Row(children: [
                  Icon(
                    pct >= 1.0
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: barColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text('${(pct * 100).toInt()}%',
                      style: TextStyle(
                          color: barColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ]),
              ],
            ),
            const SizedBox(height: 6),

            // ── Barre progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),

            // ── Montants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payé: ${r.montantPaye.toInt()} DH',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                Text('Total: ${r.montantTotal.toInt()} DH',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),

            // ── Boutons Payer + Historique
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaiementDialog(r),
                    icon: const Icon(Icons.attach_money, size: 16),
                    label: const Text('Payer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showHistoriqueDialog(r),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                        Icons.remove_red_eye_outlined,
                        color: Colors.grey,
                        size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // BADGE TYPE
  // ══════════════════════════════════════
  Widget _badgeType(String type) {
    final isProprietaire = type == 'proprietaire';
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isProprietaire
            ? Colors.blue.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isProprietaire ? 'Propriétaire' : 'Locataire',
        style: TextStyle(
          color: isProprietaire ? Colors.blue : Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // BOTTOM NAV
  // ══════════════════════════════════════
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
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'Résidents'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              label: 'Personnel'),
          BottomNavigationBarItem(
              icon: Icon(Icons.wallet_outlined),
              label: 'Finances'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_parking),
              label: 'Parkings'),
        ],
        onTap: (i) {},
      ),
    );
  }

  // ══════════════════════════════════════════
  // DIALOG : Ajouter résident
  // ══════════════════════════════════════════
  void _showAddResidentDialog() {
    final prenomCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final montantCtrl = TextEditingController(text: '3000');
    String type = 'proprietaire';
    String? errorMsg;
    bool saving = false;
    List<Map<String, dynamic>> appartementsLibres = [];
    int? selectedAppartId;
    bool loadingApparts = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          if (loadingApparts) {
            loadingApparts = false;
            _service
                .getAppartementsLibres(widget.trancheId)
                .then((list) {
              if (ctx.mounted) {
                setDialog(() => appartementsLibres = list);
              }
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ajouter Résident',
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

                    _label('Prénom *'),
                    _field(prenomCtrl, 'ex: Ahmed'),
                    const SizedBox(height: 12),
                    _label('Nom *'),
                    _field(nomCtrl, 'ex: Bennani'),
                    const SizedBox(height: 12),
                    _label('Email *'),
                    _field(emailCtrl, 'ex: ahmed@example.com',
                        inputType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _label('Téléphone'),
                    _field(telCtrl, 'ex: 0612345678',
                        inputType: TextInputType.phone),
                    const SizedBox(height: 12),

                    _label('Appartement *'),
                    appartementsLibres.isEmpty
                        ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey.shade300),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Aucun appartement libre',
                        style:
                        TextStyle(color: Colors.grey),
                      ),
                    )
                        : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey.shade300),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text(
                              'Sélectionner un appartement'),
                          value: selectedAppartId,
                          items:
                          appartementsLibres.map((a) {
                            return DropdownMenuItem<int>(
                              value: a['id'] as int,
                              child: Text(
                                  a['label'].toString()),
                            );
                          }).toList(),
                          onChanged: (val) => setDialog(
                                  () => selectedAppartId = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _label('Montant annuel (DH) *'),
                    _field(montantCtrl, '3000',
                        inputType: TextInputType.number),
                    const SizedBox(height: 12),

                    _label('Type *'),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialog(
                                  () => type = 'proprietaire'),
                          child: _typeBtn(
                              'Propriétaire',
                              type == 'proprietaire'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialog(
                                  () => type = 'locataire'),
                          child: _typeBtn(
                              'Locataire', type == 'locataire'),
                        ),
                      ),
                    ]),
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
                            if (prenomCtrl.text
                                .trim()
                                .isEmpty ||
                                nomCtrl.text
                                    .trim()
                                    .isEmpty ||
                                emailCtrl.text
                                    .trim()
                                    .isEmpty) {
                              setDialog(() => errorMsg =
                              'Prénom, Nom et Email obligatoires');
                              return;
                            }
                            if (selectedAppartId == null) {
                              setDialog(() => errorMsg =
                              'Sélectionnez un appartement');
                              return;
                            }
                            setDialog(() {
                              saving = true;
                              errorMsg = null;
                            });
                            final montant =
                                double.tryParse(
                                    montantCtrl.text) ??
                                    3000.0;
                            final err =
                            await _service.addResident(
                              nom: nomCtrl.text,
                              prenom: prenomCtrl.text,
                              email: emailCtrl.text,
                              telephone:
                              telCtrl.text.isEmpty
                                  ? null
                                  : telCtrl.text,
                              type: type,
                              trancheId: widget.trancheId,
                              appartementId:
                              selectedAppartId!,
                              montantTotal: montant,
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
                              width: 18,
                              height: 18,
                              child:
                              CircularProgressIndicator(
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
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // DIALOG : Paiement
  // ══════════════════════════════════════════
  void _showPaiementDialog(ResidentModel r) {
    final montantCtrl = TextEditingController();
    String? errorMsg;
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
                const Text('Enregistrer Paiement',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Résident',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      Text(r.nomComplet,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _rowInfo('Total',
                    '${r.montantTotal.toInt()} DH', Colors.black87),
                const SizedBox(height: 6),
                _rowInfo(
                    'Payé', '${r.montantPaye.toInt()} DH', Colors.green),
                const SizedBox(height: 6),
                _rowInfo('Reste', '${r.resteAPayer.toInt()} DH',
                    Colors.red,
                    bold: true),
                const SizedBox(height: 16),

                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(errorMsg!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                ],

                _label('Montant à payer (DH)'),
                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'ex: 1500',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),

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
                        final montant = double.tryParse(
                            montantCtrl.text.trim()) ??
                            0;
                        if (montant <= 0) {
                          setDialog(() => errorMsg =
                          'Entrez un montant valide');
                          return;
                        }
                        if (r.paiementId == null) {
                          setDialog(() => errorMsg =
                          'Aucun paiement trouvé');
                          return;
                        }
                        setDialog(() {
                          saving = true;
                          errorMsg = null;
                        });
                        final err = await _service
                            .enregistrerPaiement(
                          paiementId: r.paiementId!,
                          residentUserId: r.userId,
                          montantAjoute: montant,
                          montantDejaPane: r.montantPaye,
                          montantTotal: r.montantTotal,
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
                          width: 18,
                          height: 18,
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

  // ══════════════════════════════════════════
  // DIALOG : Historique
  // ══════════════════════════════════════════
  void _showHistoriqueDialog(ResidentModel r) {
    List<Map<String, dynamic>> historique = [];
    bool loadingHist = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          if (loadingHist) {
            loadingHist = false;
            _service.getHistoriquePaiements(r.userId).then((data) {
              if (ctx.mounted) {
                setDialog(() => historique = data);
              }
            });
          }

          final pct = r.pourcentagePaiement;
          final Color barColor = pct >= 1.0
              ? Colors.green
              : pct > 0
              ? Colors.orange
              : Colors.red;

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Historique',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 12),

                  // Info résident
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Résident',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        Text(r.nomComplet,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(r.adresseAppart,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Résumé
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      _rowInfo('Total',
                          '${r.montantTotal.toInt()} DH',
                          Colors.black87),
                      _rowInfo('Payé',
                          '${r.montantPaye.toInt()} DH',
                          Colors.green),
                      _rowInfo('Reste',
                          '${r.resteAPayer.toInt()} DH',
                          Colors.red),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Barre
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                      AlwaysStoppedAnimation(barColor),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${(pct * 100).toInt()}% payé',
                      style: TextStyle(
                          color: barColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),

                  const Divider(height: 24),

                  // Liste
                  historique.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Icon(Icons.history,
                            color: Colors.grey.shade300,
                            size: 40),
                        const SizedBox(height: 8),
                        const Text('Aucun historique',
                            style: TextStyle(
                                color: Colors.grey)),
                      ]),
                    ),
                  )
                      : ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: historique.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final h = historique[i];
                        final montant = double.parse(
                            h['montant'].toString())
                            .toInt();
                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                  Colors.green.shade50,
                                  borderRadius:
                                  BorderRadius.circular(
                                      8),
                                ),
                                child: const Icon(
                                    Icons
                                        .arrow_downward_rounded,
                                    color: Colors.green,
                                    size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      h['description'] ??
                                          'Paiement',
                                      style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      h['date']?.toString() ??
                                          '',
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+$montant DH',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                      child: const Text('Fermer',
                          style:
                          TextStyle(color: Colors.black87)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // DIALOG : Modifier
  // ══════════════════════════════════════════
  void _showEditDialog(ResidentModel r) {
    final nomCtrl = TextEditingController(text: r.nom);
    final prenomCtrl = TextEditingController(text: r.prenom);
    final telCtrl =
    TextEditingController(text: r.telephone ?? '');
    String type = r.type;
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
                    const Text('Modifier Résident',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Prénom'),
                _field(prenomCtrl, ''),
                const SizedBox(height: 12),
                _label('Nom'),
                _field(nomCtrl, ''),
                const SizedBox(height: 12),
                _label('Téléphone'),
                _field(telCtrl, '',
                    inputType: TextInputType.phone),
                const SizedBox(height: 12),
                _label('Type'),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialog(
                              () => type = 'proprietaire'),
                      child: _typeBtn(
                          'Propriétaire', type == 'proprietaire'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialog(() => type = 'locataire'),
                      child: _typeBtn(
                          'Locataire', type == 'locataire'),
                    ),
                  ),
                ]),
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
                        await _service.updateResident(
                          userId: r.userId,
                          nom: nomCtrl.text,
                          prenom: prenomCtrl.text,
                          telephone: telCtrl.text.isEmpty
                              ? null
                              : telCtrl.text,
                          type: type,
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
                          width: 18,
                          height: 18,
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

  // ══════════════════════════════════════════
  // DIALOG : Supprimer
  // ══════════════════════════════════════════
  void _showDeleteConfirm(ResidentModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer ${r.nomComplet} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.deleteResident(
                  r.userId, r.appartementId);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // HELPERS UI
  // ══════════════════════════════════════════
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

  Widget _rowInfo(String label, String value, Color color,
      {bool bold = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14)),
        ],
      );
}