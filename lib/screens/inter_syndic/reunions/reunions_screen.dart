import 'package:flutter/material.dart';
import '../../../models/reunion_model.dart';
import '../../../services/reunion_service.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
class _C {
  static const mint        = Color(0xFF4CAF82);
  static const mintLight   = Color(0xFFE8F5EE);
  static const coral       = Color(0xFFFF6B4A);
  static const coralLight  = Color(0xFFFFEDE9);
  static const cream       = Color(0xFFF4F6F8);
  static const dark        = Color(0xFF1C1C1E);
  static const gray        = Color(0xFF718096);
  static const divider     = Color(0xFFE2E8F0);
  static const white       = Color(0xFFFFFFFF);
  static const amber       = Color(0xFFF59E0B);
  static const amberLight  = Color(0xFFFFF7E6);
  static const blue        = Color(0xFF3B82F6);
  static const blueLight   = Color(0xFFEFF6FF);
  static const purple      = Color(0xFF8B5CF6);
  static const purpleLight = Color(0xFFF5F3FF);
  static const green       = Color(0xFF16A34A);
  static const greenLight  = Color(0xFFF0FDF4);
}

class ReunionsScreen extends StatefulWidget {
  final int trancheId;
  const ReunionsScreen({super.key, required this.trancheId});

  @override
  State<ReunionsScreen> createState() => _ReunionsScreenState();
}

class _ReunionsScreenState extends State<ReunionsScreen> {
  final _service = ReunionService();
  List<ReunionModel> _reunions = [];
  List<ReunionModel> _filtered = [];
  bool _loading = true;
  String _filterStatut = 'tous';
  final _searchCtrl = TextEditingController();

  // kept for picker theming — same value as original
  static const _purple = Color(0xFF4CAF82);
  static const _bg     = Color(0xFFF4F6F8);

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
          .getReunionsByTranche(widget.trancheId)
          .timeout(const Duration(seconds: 15));
      setState(() {
        _reunions = data;
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
      _filtered = _reunions.where((r) {
        final matchSearch =
            r.titre.toLowerCase().contains(q) ||
                r.lieu.toLowerCase().contains(q);
        final matchStatut = _filterStatut == 'tous' ||
            r.statut.name == _filterStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void _setFilter(String f) {
    setState(() => _filterStatut = f);
    _applyFilter();
  }

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════
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
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 44, height: 44,
                      child: CircularProgressIndicator(
                          color: _C.mint, strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                    const Text('Chargement...',
                        style: TextStyle(
                            color: _C.gray, fontSize: 13)),
                  ],
                ),
              )
                  : RefreshIndicator(
                color: _C.mint,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    _buildStats(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildFilterTabs(),
                    const SizedBox(height: 20),
                    Row(children: [
                      Container(
                          width: 4, height: 16,
                          decoration: BoxDecoration(
                              color: _C.mint,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Text(
                        '${_filtered.length} réunion${_filtered.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: _C.dark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    if (_filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filtered.map(_buildReunionCard),
                  ],
                ),
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
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: _C.cream,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: _C.dark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gestion des réunions',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: _C.dark)),
                Text(
                  '${_reunions.length} réunion(s) au total',
                  style: const TextStyle(color: _C.gray, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showAddReunionDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                  color: _C.mint, borderRadius: BorderRadius.circular(22)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, size: 16, color: _C.white),
                  SizedBox(width: 6),
                  Text('Planifier',
                      style: TextStyle(
                          color: _C.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // STATS  — same logic, new look
  // ══════════════════════════════════════
  Widget _buildStats() {
    final planifiees =
        _reunions.where((r) => r.statut == StatutReunionEnum.planifiee).length;
    final confirmees =
        _reunions.where((r) => r.statut == StatutReunionEnum.confirmee).length;
    final terminees =
        _reunions.where((r) => r.statut == StatutReunionEnum.terminee).length;

    return Row(children: [
      _statCard(Icons.event_rounded,          '$planifiees', 'Planifiées',  _C.blue,  _C.blueLight),
      const SizedBox(width: 10),
      _statCard(Icons.check_circle_rounded,   '$confirmees', 'Confirmées',  _C.mint,  _C.mintLight),
      const SizedBox(width: 10),
      _statCard(Icons.event_available_rounded,'$terminees',  'Terminées',   _C.gray,  _C.cream),
    ]);
  }

  Widget _statCard(IconData icon, String value, String label,
      Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.divider),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: _C.dark)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: _C.gray, fontSize: 10),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // SEARCH
  // ══════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: const InputDecoration(
          hintText: 'Rechercher par titre ou lieu...',
          hintStyle: TextStyle(color: _C.gray, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: _C.gray, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // FILTER TABS  — same logic
  // ══════════════════════════════════════
  Widget _buildFilterTabs() {
    final filters = [
      ('tous',      'Tous'),
      ('planifiee', 'Planifiées'),
      ('confirmee', 'Confirmées'),
      ('terminee',  'Terminées'),
      ('annulee',   'Annulées'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterStatut == f.$1;
          return GestureDetector(
            onTap: () => _setFilter(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _C.mint : _C.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: isSelected ? _C.mint : _C.divider),
              ),
              child: Text(f.$2,
                  style: TextStyle(
                      color: isSelected ? _C.white : _C.gray,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════
  // EMPTY STATE
  // ══════════════════════════════════════
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: _C.purpleLight,
              borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.event_busy_rounded,
              color: _C.purple, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Aucune réunion',
            style: TextStyle(
                color: _C.dark, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Appuyez sur Planifier pour créer une réunion',
            style: TextStyle(color: _C.gray, fontSize: 12)),
      ]),
    );
  }

  // ══════════════════════════════════════
  // REUNION CARD  — same logic, new skin
  // ══════════════════════════════════════
  Widget _buildReunionCard(ReunionModel r) {
    final statutColor = _getStatutColor(r.statut);

    final months = [
      '', 'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    final month = months[r.date.month];
    final day   = r.date.day.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main body ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date badge
                Container(
                  width: 50, height: 58,
                  decoration: BoxDecoration(
                    color: r.statut == StatutReunionEnum.terminee
                        ? _C.gray : _C.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(month,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      Text(day,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.1)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(r.titre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: _C.dark)),
                        ),
                        const SizedBox(width: 8),
                        _badgeStatut(r.statutLabel, statutColor),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _metaChip(Icons.access_time_rounded,
                              r.heureFormatee, _C.amber),
                          _metaChip(Icons.location_on_rounded,
                              r.lieu, _C.coral),
                          if (r.nbParticipants != null &&
                              r.nbParticipants! > 0)
                            _metaChip(
                                Icons.people_rounded,
                                '${r.nbParticipants} conv · '
                                    '${r.nbConfirmes ?? 0} conf.',
                                _C.purple),
                        ],
                      ),
                      if (r.description != null &&
                          r.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _C.cream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(r.description!,
                              style: const TextStyle(
                                  color: _C.gray, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ),
                // Menu — same items & onSelected logic
                PopupMenuButton<String>(
                  icon: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                        color: _C.cream,
                        borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.more_horiz_rounded,
                        color: _C.gray, size: 16),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 8,
                  onSelected: (val) {
                    switch (val) {
                      case 'modifier':     _showEditDialog(r);         break;
                      case 'statut':       _showStatutDialog(r);       break;
                      case 'convoquer':    _showConvocationDialog(r);  break;
                      case 'participants': _showParticipantsDialog(r); break;
                      case 'supprimer':    _showDeleteConfirm(r);      break;
                    }
                  },
                  itemBuilder: (_) => [
                    _menuItem('modifier',     Icons.edit_rounded,   'Modifier',             _C.dark),
                    _menuItem('statut',       Icons.swap_horiz,     'Changer statut',       _C.blue),
                    _menuItem('convoquer',    Icons.send_rounded,   'Envoyer convocations', _C.green),
                    _menuItem('participants', Icons.people_rounded, 'Voir participants',    _C.mint),
                    _menuItem('supprimer',    Icons.delete_rounded, 'Supprimer',            _C.coral),
                  ],
                ),
              ],
            ),
          ),
          // ── Footer ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: _C.mintLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 12, color: _C.gray),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(r.dateFormatee,
                      style: const TextStyle(color: _C.gray, fontSize: 11)),
                ),
                // same condition as original peutConvoquer button
                if (r.peutConvoquer)
                  GestureDetector(
                    onTap: () => _showConvocationDialog(r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _C.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.send_rounded,
                              size: 12, color: _C.green),
                          SizedBox(width: 5),
                          Text('Envoyer convocations',
                              style: TextStyle(
                                  color: _C.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeStatut(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _metaChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: _C.gray, fontSize: 11)),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Color _getStatutColor(StatutReunionEnum statut) {
    switch (statut) {
      case StatutReunionEnum.planifiee: return _C.blue;
      case StatutReunionEnum.confirmee: return _C.green;
      case StatutReunionEnum.terminee:  return _C.gray;
      case StatutReunionEnum.annulee:   return _C.coral;
    }
  }

  // ══════════════════════════════════════
  // BOTTOM NAV  — same logic
  // ══════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, -2),
          )
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _C.mint,
        unselectedItemColor: _C.gray,
        backgroundColor: _C.white,
        elevation: 0,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Résidents'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined), label: 'Réunions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.wallet_outlined), label: 'Finances'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_parking), label: 'Parkings'),
        ],
        onTap: (i) {},
      ),
    );
  }

  // ══════════════════════════════════════════
  // DIALOG : Ajouter réunion  — same logic
  // ══════════════════════════════════════════
  void _showAddReunionDialog() {
    final titreCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final lieuCtrl  = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dHeader(ctx, 'Planifier une réunion',
                      Icons.event_rounded, _C.mint, _C.mintLight,
                      saving: saving),
                  const SizedBox(height: 20),
                  if (errorMsg != null) ...[
                    _errorBox(errorMsg!), const SizedBox(height: 12),
                  ],
                  _label('Titre *'),
                  _field(titreCtrl, 'ex: Assemblée générale annuelle'),
                  const SizedBox(height: 12),
                  _label('Description'),
                  _multilineField(descCtrl, 'Ordre du jour, détails...'),
                  const SizedBox(height: 12),
                  _label('Lieu *'),
                  _field(lieuCtrl, 'ex: Salle de réunion Bloc A'),
                  const SizedBox(height: 12),
                  _label('Date *'),
                  _datePicker(
                    ctx: ctx,
                    value: selectedDate != null
                        ? '${selectedDate!.day.toString().padLeft(2, '0')}/'
                        '${selectedDate!.month.toString().padLeft(2, '0')}/'
                        '${selectedDate!.year}'
                        : null,
                    onPicked: (d) => setDialog(() => selectedDate = d),
                  ),
                  const SizedBox(height: 12),
                  _label('Heure *'),
                  _timePicker(
                    ctx: ctx,
                    value: selectedTime != null
                        ? '${selectedTime!.hour.toString().padLeft(2, '0')}:'
                        '${selectedTime!.minute.toString().padLeft(2, '0')}'
                        : null,
                    onPicked: (t) => setDialog(() => selectedTime = t),
                  ),
                  const SizedBox(height: 24),
                  _dialogActions(
                    ctx: ctx,
                    saving: saving,
                    confirmLabel: 'Planifier',
                    confirmColor: _C.mint,
                    onConfirm: () async {
                      if (titreCtrl.text.trim().isEmpty) {
                        setDialog(() => errorMsg = 'Titre obligatoire'); return;
                      }
                      if (lieuCtrl.text.trim().isEmpty) {
                        setDialog(() => errorMsg = 'Lieu obligatoire'); return;
                      }
                      if (selectedDate == null) {
                        setDialog(() => errorMsg = 'Date obligatoire'); return;
                      }
                      if (selectedTime == null) {
                        setDialog(() => errorMsg = 'Heure obligatoire'); return;
                      }
                      setDialog(() { saving = true; errorMsg = null; });
                      final heure =
                          '${selectedTime!.hour.toString().padLeft(2, '0')}:'
                          '${selectedTime!.minute.toString().padLeft(2, '0')}:00';
                      final err = await _service.addReunion(
                        titre:       titreCtrl.text,
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text,
                        date:        selectedDate!,
                        heure:       heure,
                        lieu:        lieuCtrl.text,
                        trancheId:   widget.trancheId,
                      );
                      if (!ctx.mounted) return;
                      if (err != null) {
                        setDialog(() { errorMsg = err; saving = false; });
                      } else {
                        Navigator.pop(ctx);
                        _load();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // DIALOG : Modifier réunion  — same logic
  // ══════════════════════════════════════════
  void _showEditDialog(ReunionModel r) {
    final titreCtrl = TextEditingController(text: r.titre);
    final descCtrl  = TextEditingController(text: r.description ?? '');
    final lieuCtrl  = TextEditingController(text: r.lieu);
    DateTime selectedDate = r.date;
    TimeOfDay selectedTime = TimeOfDay(
      hour:   int.parse(r.heure.substring(0, 2)),
      minute: int.parse(r.heure.substring(3, 5)),
    );
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dHeader(ctx, 'Modifier la réunion',
                      Icons.edit_rounded, _C.blue, _C.blueLight),
                  const SizedBox(height: 20),
                  _label('Titre'),
                  _field(titreCtrl, ''),
                  const SizedBox(height: 12),
                  _label('Description'),
                  _multilineField(descCtrl, ''),
                  const SizedBox(height: 12),
                  _label('Lieu'),
                  _field(lieuCtrl, ''),
                  const SizedBox(height: 12),
                  _label('Date'),
                  _datePicker(
                    ctx: ctx,
                    value: '${selectedDate.day.toString().padLeft(2, '0')}/'
                        '${selectedDate.month.toString().padLeft(2, '0')}/'
                        '${selectedDate.year}',
                    onPicked: (d) => setDialog(() => selectedDate = d),
                    initialDate: selectedDate,
                  ),
                  const SizedBox(height: 12),
                  _label('Heure'),
                  _timePicker(
                    ctx: ctx,
                    value: '${selectedTime.hour.toString().padLeft(2, '0')}:'
                        '${selectedTime.minute.toString().padLeft(2, '0')}',
                    onPicked: (t) => setDialog(() => selectedTime = t),
                    initialTime: selectedTime,
                  ),
                  const SizedBox(height: 24),
                  _dialogActions(
                    ctx: ctx,
                    saving: saving,
                    confirmLabel: 'Enregistrer',
                    confirmColor: _C.mint,
                    onConfirm: () async {
                      setDialog(() => saving = true);
                      final heure =
                          '${selectedTime.hour.toString().padLeft(2, '0')}:'
                          '${selectedTime.minute.toString().padLeft(2, '0')}:00';
                      await _service.updateReunion(
                        reunionId:   r.id,
                        titre:       titreCtrl.text,
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text,
                        date:        selectedDate,
                        heure:       heure,
                        lieu:        lieuCtrl.text,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // DIALOG : Changer statut  — same logic
  // ══════════════════════════════════════════
  void _showStatutDialog(ReunionModel r) {
    final statuts = [
      (StatutReunionEnum.planifiee, 'Planifiée',  _C.blue),
      (StatutReunionEnum.confirmee, 'Confirmée',  _C.green),
      (StatutReunionEnum.terminee,  'Terminée',   _C.gray),
      (StatutReunionEnum.annulee,   'Annulée',    _C.coral),
    ];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dHeader(ctx, 'Changer le statut',
                  Icons.swap_horiz_rounded, _C.blue, _C.blueLight),
              const SizedBox(height: 20),
              ...statuts.map((s) {
                final isSelected = r.statut == s.$1;
                return GestureDetector(
                  onTap: () async {
                    await _service.updateStatut(r.id, s.$1);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _load();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? s.$3.withValues(alpha: 0.08) : _C.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? s.$3 : _C.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? s.$3 : _C.gray,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(s.$2,
                          style: TextStyle(
                            color: isSelected ? s.$3 : _C.dark,
                            fontWeight: isSelected
                                ? FontWeight.w700 : FontWeight.normal,
                            fontSize: 14,
                          )),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: _C.cream,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Annuler',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _C.dark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // DIALOG : Envoyer convocations  — same logic
  // ══════════════════════════════════════════
  void _showConvocationDialog(ReunionModel r) {
    List<Map<String, dynamic>> residents = [];
    Set<int> selectedIds = {};
    bool loadingResidents = true;
    bool sending = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          if (loadingResidents) {
            loadingResidents = false;
            _service.getResidentsDeTranche(widget.trancheId).then((data) {
              if (ctx.mounted) {
                setDialog(() {
                  residents = data;
                  selectedIds = data.map((r) => r['id'] as int).toSet();
                });
              }
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dHeader(ctx, 'Envoyer Convocations',
                      Icons.send_rounded, _C.green, _C.greenLight),
                  const SizedBox(height: 16),
                  // info réunion
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _C.mintLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _C.mint.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.event_rounded,
                              color: _C.mint, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(r.titre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _C.dark)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          '${r.dateFormatee} à ${r.heureFormatee}  ·  ${r.lieu}',
                          style: const TextStyle(
                              color: _C.gray, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (errorMsg != null) ...[
                    _errorBox(errorMsg!), const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Résidents (${selectedIds.length}/${residents.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13, color: _C.dark),
                      ),
                      GestureDetector(
                        onTap: residents.isEmpty ? null : () {
                          setDialog(() {
                            if (selectedIds.length == residents.length) {
                              selectedIds.clear();
                            } else {
                              selectedIds = residents
                                  .map((r) => r['id'] as int).toSet();
                            }
                          });
                        },
                        child: Text(
                          selectedIds.length == residents.length
                              ? 'Désélectionner tout'
                              : 'Sélectionner tout',
                          style: const TextStyle(
                              color: _C.mint, fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  residents.isEmpty
                      ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: _C.mint)))
                      : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: residents.length,
                      itemBuilder: (_, i) {
                        final res = residents[i];
                        final id = res['id'] as int;
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeColor: _C.mint,
                          value: selectedIds.contains(id),
                          onChanged: (val) {
                            setDialog(() {
                              if (val == true) {
                                selectedIds.add(id);
                              } else {
                                selectedIds.remove(id);
                              }
                            });
                          },
                          title: Text(
                            '${res['prenom']} ${res['nom']}',
                            style: const TextStyle(
                                fontSize: 13, color: _C.dark),
                          ),
                          subtitle: Text(
                            res['email']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: _C.gray),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              color: _C.cream,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Text('Annuler',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: _C.dark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: sending || selectedIds.isEmpty ? null : () async {
                          setDialog(() => sending = true);
                          final err = await _service.envoyerConvocations(
                              r.id, selectedIds.toList());
                          if (!ctx.mounted) return;
                          if (err != null) {
                            setDialog(() { errorMsg = err; sending = false; });
                          } else {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '✓ ${selectedIds.length} convocation(s) envoyée(s)'),
                                backgroundColor: _C.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            _load();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              color: (sending || selectedIds.isEmpty)
                                  ? _C.green.withValues(alpha: 0.5)
                                  : _C.green,
                              borderRadius: BorderRadius.circular(12)),
                          child: sending
                              ? const Center(
                              child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: _C.white, strokeWidth: 2)))
                              : Text('Envoyer (${selectedIds.length})',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: _C.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // DIALOG : Participants  — same logic
  // ══════════════════════════════════════════
  void _showParticipantsDialog(ReunionModel r) {
    List<ReunionResidentModel> participants = [];
    bool loading = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          if (loading) {
            loading = false;
            _service.getConvocations(r.id).then((data) {
              if (ctx.mounted) setDialog(() => participants = data);
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dHeader(ctx, 'Participants',
                      Icons.people_rounded, _C.mint, _C.mintLight,
                      subtitle: r.titre),
                  const SizedBox(height: 16),
                  if (participants.isNotEmpty) ...[
                    Row(children: [
                      _miniStat('${participants.length}', 'Total', _C.blue),
                      const SizedBox(width: 8),
                      _miniStat(
                          '${participants.where((p) => p.confirmation == ConfirmationEnum.confirme).length}',
                          'Confirmés', _C.green),
                      const SizedBox(width: 8),
                      _miniStat(
                          '${participants.where((p) => p.confirmation == ConfirmationEnum.en_attente).length}',
                          'En attente', _C.amber),
                    ]),
                    const SizedBox(height: 14),
                  ],
                  Container(height: 1, color: _C.divider),
                  const SizedBox(height: 12),
                  participants.isEmpty
                      ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(children: [
                          CircularProgressIndicator(color: _C.mint),
                          SizedBox(height: 8),
                          Text('Chargement...',
                              style: TextStyle(color: _C.gray)),
                        ]),
                      ))
                      : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: participants.length,
                      separatorBuilder: (_, __) =>
                          Container(height: 1, color: _C.divider),
                      itemBuilder: (_, i) {
                        final p = participants[i];
                        final confColor =
                        _getConfirmationColor(p.confirmation);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                  color: _C.mintLight,
                                  borderRadius:
                                  BorderRadius.circular(12)),
                              child: Center(
                                child: Text(
                                  (p.prenom?.isNotEmpty ?? false)
                                      ? p.prenom![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: _C.mint,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(p.nomComplet,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _C.dark)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: confColor.withValues(alpha: 0.1),
                                  borderRadius:
                                  BorderRadius.circular(20)),
                              child: Text(p.confirmationLabel,
                                  style: TextStyle(
                                      color: confColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.cream,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Fermer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.dark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
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

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ]),
      ),
    );
  }

  Color _getConfirmationColor(ConfirmationEnum c) {
    switch (c) {
      case ConfirmationEnum.confirme:   return _C.green;
      case ConfirmationEnum.absent:     return _C.coral;
      case ConfirmationEnum.en_attente: return _C.amber;
    }
  }

  // ══════════════════════════════════════════
  // DIALOG : Supprimer  — same logic
  // ══════════════════════════════════════════
  void _showDeleteConfirm(ReunionModel r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                    color: _C.coralLight,
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.delete_rounded,
                    color: _C.coral, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Confirmer la suppression',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17, color: _C.dark)),
              const SizedBox(height: 8),
              Text('Supprimer "${r.titre}" ?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _C.gray, fontSize: 13)),
              const SizedBox(height: 6),
              const Text(
                'Les convocations associées seront aussi supprimées.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _C.gray, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.cream,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Annuler',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.dark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await _service.deleteReunion(r.id);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: _C.coral,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Supprimer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _C.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SHARED DIALOG HELPERS
  // ══════════════════════════════════════════

  /// Shared dialog header with icon badge + close button
  Widget _dHeader(
      BuildContext ctx,
      String title,
      IconData icon,
      Color color,
      Color bg, {
        bool saving = false,
        String? subtitle,
      }) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17, color: _C.dark)),
            if (subtitle != null)
              Text(subtitle,
                  style: const TextStyle(color: _C.gray, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      GestureDetector(
        onTap: saving ? null : () => Navigator.pop(ctx),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
              color: _C.cream, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.close_rounded, size: 15, color: _C.gray),
        ),
      ),
    ]);
  }

  Widget _dialogActions({
    required BuildContext ctx,
    required bool saving,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: saving ? null : () => Navigator.pop(ctx),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: _C.cream, borderRadius: BorderRadius.circular(12)),
            child: const Text('Annuler',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GestureDetector(
          onTap: saving ? null : onConfirm,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: saving
                    ? confirmColor.withValues(alpha: 0.5) : confirmColor,
                borderRadius: BorderRadius.circular(12)),
            child: saving
                ? const Center(
                child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: _C.white, strokeWidth: 2)))
                : Text(confirmLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _C.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
      ),
    ]);
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12, color: _C.gray)),
  );

  Widget _field(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(fontSize: 14, color: _C.dark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.gray, fontSize: 13),
      filled: true,
      fillColor: _C.cream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _C.mint, width: 1.5),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
  );

  Widget _multilineField(TextEditingController ctrl, String hint) =>
      TextField(
        controller: ctrl,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _C.gray, fontSize: 13),
          filled: true,
          fillColor: _C.cream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.mint, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      );

  // same logic — only the picker box look changed
  Widget _datePicker({
    required BuildContext ctx,
    required String? value,
    required ValueChanged<DateTime> onPicked,
    DateTime? initialDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate:
          initialDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (c, child) => Theme(
            data: Theme.of(c).copyWith(
              colorScheme: const ColorScheme.light(primary: _purple),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: _pickerBox(
          icon: Icons.calendar_today_rounded, value: value,
          hint: 'Sélectionner une date'),
    );
  }

  Widget _timePicker({
    required BuildContext ctx,
    required String? value,
    required ValueChanged<TimeOfDay> onPicked,
    TimeOfDay? initialTime,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: ctx,
          initialTime: initialTime ?? TimeOfDay.now(),
          builder: (c, child) => Theme(
            data: Theme.of(c).copyWith(
              colorScheme: const ColorScheme.light(primary: _purple),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: _pickerBox(
          icon: Icons.access_time_rounded, value: value,
          hint: 'Sélectionner une heure'),
    );
  }

  Widget _pickerBox(
      {required IconData icon, required String? value, required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _C.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.divider),
      ),
      child: Row(children: [
        Icon(icon, color: _C.gray, size: 18),
        const SizedBox(width: 10),
        Text(value ?? hint,
            style: TextStyle(
                color: value != null ? _C.dark : _C.gray, fontSize: 14)),
      ]),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _C.coralLight, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: _C.coral, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: const TextStyle(color: _C.coral, fontSize: 12))),
      ]),
    );
  }

  // kept for backward compat
  ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
    backgroundColor: _purple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)),
  );

  ButtonStyle _outlineStyle() => OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8)),
  );

  Widget _loader() => const SizedBox(
    width: 18, height: 18,
    child: CircularProgressIndicator(
        color: Colors.white, strokeWidth: 2),
  );
}