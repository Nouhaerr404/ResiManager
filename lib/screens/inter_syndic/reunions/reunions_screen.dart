// lib/screens/inter_syndic/reunions/reunions_screen.dart
// ignore_for_file: avoid_multiple_underscores_for_members

import 'package:flutter/material.dart';
import '../../../models/reunion_model.dart';
import '../../../services/reunion_service.dart';
import '../../../services/convocation_pdf_service.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';

class _C {
  static const coral       = Color(0xFFE8603C);
  static const coralLight  = Color(0xFFFFF0EB);
  static const bg          = Color(0xFFF2F3F5);
  static const white       = Color(0xFFFFFFFF);
  static const dark        = Color(0xFF1A1A1A);
  static const textMid     = Color(0xFF5A5A6A);
  static const textLight   = Color(0xFF9A9AAF);
  static const divider     = Color(0xFFE8E8F0);
  static const iconBg      = Color(0xFFEDEDED);
  static const blue        = Color(0xFF4B6BFB);
  static const blueLight   = Color(0xFFEEF1FF);
  static const amber       = Color(0xFFF5A623);
  static const green       = Color(0xFF34C98B);
  static const greenLight  = Color(0xFFEBFAF4);
  static const purple      = Color(0xFF7C5CFC);
  static const purpleLight = Color(0xFFF3F0FF);
}

const _pickerAccent = Color(0xFFE8603C);

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

  // Vrais noms charges depuis Supabase
  String _residenceNom   = '';
  String _trancheNom     = '';
  String _interSyndicNom = '';

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
      final results = await Future.wait([
        _service.getReunionsByTranche(widget.trancheId).timeout(const Duration(seconds: 15)),
        _service.getTrancheInfo(widget.trancheId),
      ]);
      final reunions = results[0] as List<ReunionModel>;
      final info     = results[1] as Map<String, String>;
      setState(() {
        _reunions      = reunions;
        _trancheNom    = info['tranche_nom']      ?? '';
        _residenceNom  = info['residence_nom']    ?? '';
        _interSyndicNom = (info['inter_syndic_nom']?.isNotEmpty == true)
            ? info['inter_syndic_nom']!
            : "L'Inter-Syndic";
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      debugPrint('>>> ERREUR _load reunions: $e');
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _reunions.where((r) {
        final matchSearch = r.titre.toLowerCase().contains(q) || r.lieu.toLowerCase().contains(q);
        final matchStatut = _filterStatut == 'tous' || r.statut.name == _filterStatut;
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
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: _C.coral, strokeWidth: 2.5),
                SizedBox(height: 16),
                Text('Chargement...', style: TextStyle(color: _C.textLight, fontSize: 13)),
              ]))
                  : RefreshIndicator(
                color: _C.coral,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    _buildPageTitle(),
                    const SizedBox(height: 20),
                    _buildStats(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildFilterTabs(),
                    const SizedBox(height: 24),
                    Text('${_filtered.length} reunion${_filtered.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.3)),
                    const SizedBox(height: 14),
                    if (_filtered.isEmpty) _buildEmpty() else ..._filtered.map(_buildReunionCard),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _C.dark),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.grid_view_rounded, color: _C.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('ResiManager', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2)),
          Text('inter_syndic', style: TextStyle(color: _C.textLight, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: _showAddReunionDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(22)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, size: 16, color: _C.white),
              SizedBox(width: 6),
              Text('Planifier', style: TextStyle(color: _C.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildPageTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Reunions', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text('${_reunions.length} reunion(s) au total', style: const TextStyle(color: _C.textMid, fontSize: 13)),
    ]);
  }

  Widget _buildStats() {
    final planifiees = _reunions.where((r) => r.statut == StatutReunionEnum.planifiee).length;
    final confirmees = _reunions.where((r) => r.statut == StatutReunionEnum.confirmee).length;
    final terminees  = _reunions.where((r) => r.statut == StatutReunionEnum.terminee).length;
    return Row(children: [
      _statCard(Icons.event_outlined, '$planifiees', 'Planifiees', _C.blue, _C.blueLight),
      const SizedBox(width: 10),
      _statCard(Icons.check_circle_outline_rounded, '$confirmees', 'Confirmees', _C.green, _C.greenLight),
      const SizedBox(width: 10),
      _statCard(Icons.event_available_outlined, '$terminees', 'Terminees', _C.textMid, _C.iconBg),
    ]);
  }

  Widget _statCard(IconData icon, String value, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.divider)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _C.dark, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _C.textLight, fontSize: 10), overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: _C.dark),
        decoration: const InputDecoration(
          hintText: 'Rechercher par titre ou lieu...',
          hintStyle: TextStyle(color: _C.textLight, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: _C.textLight, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [('tous','Tous'),('planifiee','Planifiees'),('confirmee','Confirmees'),('terminee','Terminees'),('annulee','Annulees')];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: filters.map((f) {
        final isSelected = _filterStatut == f.$1;
        return GestureDetector(
          onTap: () => _setFilter(f.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _C.coral : _C.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isSelected ? _C.coral : _C.divider),
            ),
            child: Text(f.$2, style: TextStyle(color: isSelected ? _C.white : _C.textMid, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: _C.purpleLight, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.event_busy_rounded, color: _C.purple, size: 30)),
        const SizedBox(height: 16),
        const Text('Aucune reunion', style: TextStyle(color: _C.dark, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Appuyez sur Planifier pour creer une reunion', style: TextStyle(color: _C.textLight, fontSize: 12)),
      ]),
    );
  }

  Widget _buildReunionCard(ReunionModel r) {
    final statutColor = _getStatutColor(r.statut);
    final months = ['','jan','fev','mar','avr','mai','jun','jul','aou','sep','oct','nov','dec'];
    final month  = months[r.date.month];
    final day    = r.date.day.toString().padLeft(2, '0');
    final isDone = r.statut == StatutReunionEnum.terminee;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 50, height: 58,
              decoration: BoxDecoration(color: isDone ? _C.iconBg : _C.coral, borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(month, style: TextStyle(color: isDone ? _C.textLight : Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
                Text(day, style: TextStyle(color: isDone ? _C.textMid : _C.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(r.titre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _C.dark, letterSpacing: -0.2))),
                  const SizedBox(width: 8),
                  _badgeStatut(r.statutLabel, statutColor),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 12, runSpacing: 6, children: [
                  _metaChip(Icons.access_time_rounded, r.heureFormatee, _C.amber),
                  _metaChip(Icons.location_on_outlined, r.lieu, _C.coral),
                  if ((r.nbParticipants ?? 0) > 0)
                    _metaChip(Icons.people_outline_rounded,
                        '${r.nbParticipants} conv  ${r.nbConfirmes ?? 0} confirmes', _C.purple),
                ]),
                if (r.description != null && r.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10)),
                    child: Text(r.description!, style: const TextStyle(color: _C.textMid, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ]),
            ),
            PopupMenuButton<String>(
              icon: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.divider)),
                  child: const Icon(Icons.more_horiz_rounded, color: _C.textMid, size: 16)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 8,
              onSelected: (val) {
                if (val == 'modifier')     _showEditDialog(r);
                if (val == 'statut')       _showStatutDialog(r);
                if (val == 'convoquer')    _showConvocationDialog(r);
                if (val == 'participants') _showParticipantsDialog(r);
                if (val == 'supprimer')    _showDeleteConfirm(r);
              },
              itemBuilder: (_) => [
                _menuItem('modifier',     Icons.edit_rounded,           'Modifier',                _C.dark),
                _menuItem('statut',       Icons.swap_horiz,             'Changer statut',          _C.blue),
                _menuItem('convoquer',    Icons.send_rounded,           'Envoyer convocations',    _C.green),
                _menuItem('participants', Icons.people_outline_rounded, 'Voir participants',        _C.coral),
                _menuItem('supprimer',    Icons.delete_rounded,         'Supprimer',               _C.coral),
              ],
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
            border: Border(top: BorderSide(color: _C.divider)),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: _C.textLight),
            const SizedBox(width: 6),
            Expanded(child: Text(r.dateFormatee, style: const TextStyle(color: _C.textMid, fontSize: 11))),
            if (r.peutConvoquer)
              GestureDetector(
                onTap: () => _showConvocationDialog(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.send_rounded, size: 12, color: _C.green),
                    SizedBox(width: 5),
                    Text('Envoyer convocations', style: TextStyle(color: _C.green, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _badgeStatut(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _metaChip(IconData icon, String text, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(color: _C.textMid, fontSize: 11)),
  ]);

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) => PopupMenuItem(
    value: value,
    child: Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color)),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );

  Color _getStatutColor(StatutReunionEnum s) {
    switch (s) {
      case StatutReunionEnum.planifiee: return _C.blue;
      case StatutReunionEnum.confirmee: return _C.green;
      case StatutReunionEnum.terminee:  return _C.textMid;
      case StatutReunionEnum.annulee:   return _C.coral;
    }
  }

  // ══════════════════════════════════════════════════════════
  // DIALOGS helpers
  // ══════════════════════════════════════════════════════════

  Widget _dHeader(BuildContext ctx, String title, IconData icon, Color color, Color bg, {String? subtitle}) {
    return Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _C.dark)),
        if (subtitle != null) Text(subtitle, style: const TextStyle(color: _C.textLight, fontSize: 12), overflow: TextOverflow.ellipsis),
      ])),
      GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(width: 30, height: 30,
            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.divider)),
            child: const Icon(Icons.close_rounded, size: 15, color: _C.textMid)),
      ),
    ]);
  }

  Widget _dialogActions({required BuildContext ctx, required bool saving, required String confirmLabel, required Color confirmColor, required VoidCallback onConfirm}) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: saving ? null : () => Navigator.pop(ctx),
        child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
            child: const Text('Annuler', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14))),
      )),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: saving ? null : onConfirm,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: saving ? confirmColor.withValues(alpha: 0.5) : confirmColor, borderRadius: BorderRadius.circular(12)),
            child: saving
                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _C.white, strokeWidth: 2)))
                : Text(confirmLabel, textAlign: TextAlign.center, style: const TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 14))),
      )),
    ]);
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _C.textMid)));

  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) => TextField(
    controller: ctrl, maxLines: maxLines,
    style: const TextStyle(fontSize: 14, color: _C.dark),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: _C.textLight, fontSize: 13),
      filled: true, fillColor: _C.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _C.coral, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
  );

  Widget _pickerBox({required IconData icon, required String? value, required String hint}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)),
    child: Row(children: [
      Icon(icon, color: _C.textLight, size: 18), const SizedBox(width: 10),
      Text(value ?? hint, style: TextStyle(color: value != null ? _C.dark : _C.textLight, fontSize: 14)),
    ]),
  );

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, color: _C.coral, size: 16), const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: _C.coral, fontSize: 12))),
    ]),
  );

  // ══════════════════════════════════════════════════════════
  // DIALOG AJOUTER
  // ══════════════════════════════════════════════════════════
  void _showAddReunionDialog() {
    final titreCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final lieuCtrl  = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String? errorMsg;
    bool saving = false;

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dHeader(ctx, 'Planifier une reunion', Icons.event_rounded, _C.coral, _C.coralLight),
          const SizedBox(height: 20),
          if (errorMsg != null) ...[_errorBox(errorMsg!), const SizedBox(height: 12)],
          _label('Titre *'), _field(titreCtrl, 'ex: Assemblee generale annuelle'), const SizedBox(height: 12),
          _label('Description'), _field(descCtrl, 'Ordre du jour...', maxLines: 3), const SizedBox(height: 12),
          _label('Lieu *'), _field(lieuCtrl, 'ex: Salle de reunion Bloc A'), const SizedBox(height: 12),
          _label('Date *'),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days:1)), firstDate: DateTime(2020), lastDate: DateTime(2030),
                  builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _pickerAccent)), child: child!));
              if (d != null) setDialog(() => selectedDate = d);
            },
            child: _pickerBox(icon: Icons.calendar_today_outlined,
                value: selectedDate != null ? '${selectedDate!.day.toString().padLeft(2,'0')}/${selectedDate!.month.toString().padLeft(2,'0')}/${selectedDate!.year}' : null,
                hint: 'Selectionner une date'),
          ),
          const SizedBox(height: 12),
          _label('Heure *'),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now(),
                  builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _pickerAccent)), child: child!));
              if (t != null) setDialog(() => selectedTime = t);
            },
            child: _pickerBox(icon: Icons.access_time_rounded,
                value: selectedTime != null ? '${selectedTime!.hour.toString().padLeft(2,'0')}:${selectedTime!.minute.toString().padLeft(2,'0')}' : null,
                hint: 'Selectionner une heure'),
          ),
          const SizedBox(height: 24),
          _dialogActions(ctx: ctx, saving: saving, confirmLabel: 'Planifier', confirmColor: _C.coral, onConfirm: () async {
            if (titreCtrl.text.trim().isEmpty) { setDialog(() => errorMsg = 'Titre obligatoire'); return; }
            if (lieuCtrl.text.trim().isEmpty)  { setDialog(() => errorMsg = 'Lieu obligatoire');  return; }
            if (selectedDate == null)           { setDialog(() => errorMsg = 'Date obligatoire');  return; }
            if (selectedTime == null)           { setDialog(() => errorMsg = 'Heure obligatoire'); return; }
            setDialog(() { saving = true; errorMsg = null; });
            final heure = '${selectedTime!.hour.toString().padLeft(2,'0')}:${selectedTime!.minute.toString().padLeft(2,'0')}:00';
            final err = await _service.addReunion(titre: titreCtrl.text, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text, date: selectedDate!, heure: heure, lieu: lieuCtrl.text, trancheId: widget.trancheId);
            if (!ctx.mounted) return;
            if (err != null) { setDialog(() { errorMsg = err; saving = false; }); } else { Navigator.pop(ctx); _load(); }
          }),
        ]))),
      ),
    ));
  }

  // ══════════════════════════════════════════════════════════
  // DIALOG MODIFIER
  // ══════════════════════════════════════════════════════════
  void _showEditDialog(ReunionModel r) {
    final titreCtrl = TextEditingController(text: r.titre);
    final descCtrl  = TextEditingController(text: r.description ?? '');
    final lieuCtrl  = TextEditingController(text: r.lieu);
    DateTime selectedDate = r.date;
    TimeOfDay selectedTime = TimeOfDay(hour: int.parse(r.heure.substring(0,2)), minute: int.parse(r.heure.substring(3,5)));
    bool saving = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _dHeader(ctx, 'Modifier la reunion', Icons.edit_rounded, _C.blue, _C.blueLight),
          const SizedBox(height: 20),
          _label('Titre'), _field(titreCtrl, ''), const SizedBox(height: 12),
          _label('Description'), _field(descCtrl, '', maxLines: 3), const SizedBox(height: 12),
          _label('Lieu'), _field(lieuCtrl, ''), const SizedBox(height: 12),
          _label('Date'),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030),
                  builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _pickerAccent)), child: child!));
              if (d != null) setDialog(() => selectedDate = d);
            },
            child: _pickerBox(icon: Icons.calendar_today_outlined, value: '${selectedDate.day.toString().padLeft(2,'0')}/${selectedDate.month.toString().padLeft(2,'0')}/${selectedDate.year}', hint: ''),
          ),
          const SizedBox(height: 12),
          _label('Heure'),
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(context: ctx, initialTime: selectedTime,
                  builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: _pickerAccent)), child: child!));
              if (t != null) setDialog(() => selectedTime = t);
            },
            child: _pickerBox(icon: Icons.access_time_rounded, value: '${selectedTime.hour.toString().padLeft(2,'0')}:${selectedTime.minute.toString().padLeft(2,'0')}', hint: ''),
          ),
          const SizedBox(height: 24),
          _dialogActions(ctx: ctx, saving: saving, confirmLabel: 'Enregistrer', confirmColor: _C.blue, onConfirm: () async {
            setDialog(() => saving = true);
            final heure = '${selectedTime.hour.toString().padLeft(2,'0')}:${selectedTime.minute.toString().padLeft(2,'0')}:00';
            await _service.updateReunion(reunionId: r.id, titre: titreCtrl.text, description: descCtrl.text.trim().isEmpty ? null : descCtrl.text, date: selectedDate, heure: heure, lieu: lieuCtrl.text);
            if (!ctx.mounted) return;
            Navigator.pop(ctx); _load();
          }),
        ]))),
      ),
    ));
  }

  // ══════════════════════════════════════════════════════════
  // DIALOG STATUT
  // ══════════════════════════════════════════════════════════
  void _showStatutDialog(ReunionModel r) {
    final statuts = [
      (StatutReunionEnum.planifiee, 'Planifiee', _C.blue),
      (StatutReunionEnum.confirmee, 'Confirmee', _C.green),
      (StatutReunionEnum.terminee,  'Terminee',  _C.textMid),
      (StatutReunionEnum.annulee,   'Annulee',   _C.coral),
    ];
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _dHeader(ctx, 'Changer le statut', Icons.swap_horiz_rounded, _C.blue, _C.blueLight),
        const SizedBox(height: 20),
        ...statuts.map((s) => GestureDetector(
          onTap: () async { await _service.updateStatut(r.id, s.$1); if (!ctx.mounted) return; Navigator.pop(ctx); _load(); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: r.statut == s.$1 ? s.$3.withValues(alpha: 0.08) : _C.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: r.statut == s.$1 ? s.$3 : _C.divider, width: r.statut == s.$1 ? 1.5 : 1),
            ),
            child: Row(children: [
              Icon(r.statut == s.$1 ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: r.statut == s.$1 ? s.$3 : _C.textLight, size: 18),
              const SizedBox(width: 12),
              Text(s.$2, style: TextStyle(color: r.statut == s.$1 ? s.$3 : _C.dark, fontWeight: r.statut == s.$1 ? FontWeight.w700 : FontWeight.normal, fontSize: 14)),
            ]),
          ),
        )),
        GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
              child: const Text('Annuler', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14))),
        ),
      ])),
    ));
  }

  // ══════════════════════════════════════════════════════════
  // DIALOG CONVOCATION — genere PDF + upload Supabase Storage
  // ══════════════════════════════════════════════════════════
  // ══════════════════════════════════════════════════════════
// REMPLACER uniquement la méthode _showConvocationDialog
// dans lib/screens/inter_syndic/reunions/reunions_screen.dart
// ══════════════════════════════════════════════════════════

// AJOUTER cet import en haut du fichier si pas déjà présent :
// import 'package:printing/printing.dart';

// ──────────────────────────────────────────────────────────
// DIALOG CONVOCATION — avec aperçu PDF pour l'inter-syndic
// ──────────────────────────────────────────────────────────
  void _showConvocationDialog(ReunionModel r) {
    List<Map<String, dynamic>> residents = [];
    Set<int> selectedIds = {};
    bool loadingResidents = true;
    bool sending = false;
    bool generatingPdf = false;

    // PDFs générés : residentId → bytes (pour aperçu)
    Map<int, Uint8List> pdfCache = {};
    bool pdfGenerated = false;  // true quand tous les PDFs sont prêts
    String? errorMsg;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) {
        if (loadingResidents) {
          loadingResidents = false;
          _service.getResidentsDeTranche(widget.trancheId).then((data) {
            if (ctx.mounted) setDialog(() {
              residents = data;
              selectedIds = data.map((r) => r['id'] as int).toSet();
            });
          });
        }

        // ── Ouvrir l'aperçu du PDF d'un résident ──────────
        Future<void> previewPdf(Map<String, dynamic> res) async {
          final bytes = pdfCache[res['id'] as int];
          if (bytes == null) return;
          await Printing.layoutPdf(onLayout: (_) async => bytes);
        }

        // ── Générer TOUS les PDFs + upload + notif ─────────
        Future<void> genererEtEnvoyer() async {
          setDialog(() { generatingPdf = true; errorMsg = null; pdfGenerated = false; });
          try {
            final selectedResidents = residents
                .where((res) => selectedIds.contains(res['id'] as int))
                .toList();

            for (final res in selectedResidents) {
              final pdfBytes = await ConvocationPdfService.generate(
                residentPrenom: res['prenom']?.toString() ?? '',
                residentNom:    res['nom']?.toString() ?? '',
                reunionTitre:   r.titre,
                reunionDate:    r.dateFormatee,
                reunionHeure:   r.heureFormatee,
                reunionLieu:    r.lieu,
                residenceNom:   _residenceNom,
                trancheNom:     _trancheNom,
                interSyndicNom: _interSyndicNom,
              );

              // Stocker en cache pour aperçu
              pdfCache[res['id'] as int] = pdfBytes;

              // Upload Supabase Storage + notification résident
              await ConvocationPdfService.uploadAndNotify(
                bytes:        pdfBytes,
                residentId:   res['id'] as int,
                reunionId:    r.id,
                reunionTitre: r.titre,
                reunionDate:  r.dateFormatee,
                reunionHeure: r.heureFormatee,
                reunionLieu:  r.lieu,
              );
            }

            // PDFs prêts → afficher la section aperçu
            if (ctx.mounted) setDialog(() { pdfGenerated = true; });

          } catch (e) {
            if (ctx.mounted) setDialog(() => errorMsg = 'Erreur PDF : $e');
          } finally {
            if (ctx.mounted) setDialog(() => generatingPdf = false);
          }
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── En-tête ────────────────────────────────────
              _dHeader(ctx, 'Envoyer Convocations', Icons.send_rounded, _C.green, _C.greenLight),
              const SizedBox(height: 16),

              // ── Info réunion ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.coralLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _C.coral.withValues(alpha: 0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.event_rounded, color: _C.coral, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(r.titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.dark))),
                  ]),
                  const SizedBox(height: 4),
                  Text('${r.dateFormatee}  a  ${r.heureFormatee}    ${r.lieu}',
                      style: const TextStyle(color: _C.textMid, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 12),

              // ── Erreur ─────────────────────────────────────
              if (errorMsg != null) ...[_errorBox(errorMsg!), const SizedBox(height: 8)],

              // ── Section aperçu PDFs (après génération) ─────
              if (pdfGenerated) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.greenLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.green.withValues(alpha: 0.4)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.check_circle_rounded, color: _C.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${pdfCache.length} PDF(s) genere(s) et envoye(s)',
                        style: const TextStyle(color: _C.green, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    // Liste des résidents avec bouton aperçu
                    ...residents
                        .where((res) => pdfCache.containsKey(res['id'] as int))
                        .map((res) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: _C.coral, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${res['prenom']} ${res['nom']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.dark)),
                          const Text('PDF prêt', style: TextStyle(fontSize: 10, color: _C.textLight)),
                        ])),
                        // Bouton Aperçu
                        GestureDetector(
                          onTap: () => previewPdf(res),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: _C.blueLight, borderRadius: BorderRadius.circular(8)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.visibility_rounded, size: 13, color: _C.blue),
                              SizedBox(width: 5),
                              Text('Apercu', style: TextStyle(color: _C.blue, fontSize: 11, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Bouton Partager
                        GestureDetector(
                          onTap: () async {
                            final bytes = pdfCache[res['id'] as int];
                            if (bytes != null) {
                              await ConvocationPdfService.share(
                                bytes,
                                '${res['prenom']}_${res['nom']}',
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(8)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.download_rounded, size: 13, color: _C.coral),
                              SizedBox(width: 5),
                              Text('Ouvrir', style: TextStyle(color: _C.coral, fontSize: 11, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ]),
                    )),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Bouton Fermer (après envoi réussi) ────────
                GestureDetector(
                  onTap: () { Navigator.pop(ctx); _load(); },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Terminer', textAlign: TextAlign.center,
                        style: TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),

              ] else ...[
                // ── Liste résidents (avant génération) ────────
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Residents (${selectedIds.length}/${residents.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _C.dark)),
                  GestureDetector(
                    onTap: residents.isEmpty ? null : () => setDialog(() {
                      if (selectedIds.length == residents.length) { selectedIds.clear(); }
                      else { selectedIds = residents.map((r) => r['id'] as int).toSet(); }
                    }),
                    child: Text(
                      selectedIds.length == residents.length ? 'Deselectionner tout' : 'Selectionner tout',
                      style: const TextStyle(color: _C.coral, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),

                residents.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _C.coral)))
                    : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: residents.length,
                    itemBuilder: (_, i) {
                      final res = residents[i];
                      final id  = res['id'] as int;
                      return CheckboxListTile(
                        dense: true, contentPadding: EdgeInsets.zero, activeColor: _C.coral,
                        value: selectedIds.contains(id),
                        onChanged: (val) => setDialog(() {
                          if (val == true) { selectedIds.add(id); } else { selectedIds.remove(id); }
                        }),
                        title: Text('${res['prenom']} ${res['nom']}',
                            style: const TextStyle(fontSize: 13, color: _C.dark)),
                        subtitle: Text(res['email']?.toString() ?? '',
                            style: const TextStyle(fontSize: 11, color: _C.textLight)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // ── Bouton Générer PDF + Envoyer ───────────────
                GestureDetector(
                  onTap: (generatingPdf || sending || selectedIds.isEmpty) ? null : genererEtEnvoyer,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: (generatingPdf || sending || selectedIds.isEmpty)
                          ? _C.blue.withValues(alpha: 0.4) : _C.blueLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.blue.withValues(alpha: 0.3)),
                    ),
                    child: generatingPdf
                        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _C.blue, strokeWidth: 2)),
                      SizedBox(height: 6),
                      Text('Génération en cours...', style: TextStyle(color: _C.blue, fontSize: 11)),
                    ]))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.picture_as_pdf_rounded, size: 16, color: _C.blue),
                      SizedBox(width: 8),
                      Text('Generer PDF + Envoyer aux residents',
                          style: TextStyle(color: _C.blue, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                ),

                // ── Boutons Annuler / Notifier sans PDF ───────
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _C.bg, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.divider),
                      ),
                      child: const Text('Annuler', textAlign: TextAlign.center,
                          style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: (sending || selectedIds.isEmpty) ? null : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final count = selectedIds.length;
                      setDialog(() => sending = true);
                      final err = await _service.envoyerConvocations(r.id, selectedIds.toList());
                      if (!ctx.mounted) return;
                      if (err != null) {
                        setDialog(() { errorMsg = err; sending = false; });
                      } else {
                        Navigator.pop(ctx);
                        messenger.showSnackBar(SnackBar(
                          content: Text('$count notification(s) envoyee(s)'),
                          backgroundColor: _C.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ));
                        _load();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: (sending || selectedIds.isEmpty)
                            ? _C.green.withValues(alpha: 0.5) : _C.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: sending
                          ? const Center(child: SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: _C.white, strokeWidth: 2)))
                          : Text('Notifier (${selectedIds.length})', textAlign: TextAlign.center,
                          style: const TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  )),
                ]),
              ],

            ]),
          ),
        );
      },
    ));
  }

  // ══════════════════════════════════════════════════════════
  // DIALOG PARTICIPANTS — confirmes seulement avec bouton PDF
  // ══════════════════════════════════════════════════════════
  void _showParticipantsDialog(ReunionModel r) {
    List<ReunionResidentModel> tous = [];
    bool loading = true;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) {
        if (loading) {
          loading = false;
          _service.getConvocations(r.id).then((data) { if (ctx.mounted) setDialog(() => tous = data); });
        }

        final confirmes = tous.where((p) => p.confirmation == ConfirmationEnum.confirme).toList();
        final enAttente = tous.where((p) => p.confirmation == ConfirmationEnum.en_attente).length;
        final absents   = tous.where((p) => p.confirmation == ConfirmationEnum.absent).length;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dHeader(ctx, 'Participants confirmes', Icons.people_outline_rounded, _C.green, _C.greenLight, subtitle: r.titre),
            const SizedBox(height: 16),

            if (tous.isNotEmpty) ...[
              Row(children: [
                _miniStat('${tous.length}',    'Convoques',  _C.blue),
                const SizedBox(width: 8),
                _miniStat('${confirmes.length}', 'Confirmes', _C.green),
                const SizedBox(width: 8),
                _miniStat('$enAttente',         'Attente',   _C.amber),
                const SizedBox(width: 8),
                _miniStat('$absents',           'Absents',   _C.coral),
              ]),
              const SizedBox(height: 14),
            ],

            Container(height: 1, color: _C.divider),
            const SizedBox(height: 12),

            if (loading)
              const Center(child: CircularProgressIndicator(color: _C.coral))
            else if (confirmes.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Column(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.how_to_reg_rounded, color: _C.green, size: 22)),
                const SizedBox(height: 10),
                const Text('Aucun participant confirme', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text('$enAttente resident(s) en attente', style: const TextStyle(color: _C.textLight, fontSize: 12)),
              ])))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: confirmes.length,
                  separatorBuilder: (_, __) => Container(height: 1, color: _C.divider),
                  itemBuilder: (_, i) {
                    final p = confirmes[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Text((p.prenom?.isNotEmpty ?? false) ? p.prenom![0].toUpperCase() : '?', style: const TextStyle(color: _C.green, fontWeight: FontWeight.w800, fontSize: 16)))),
                        const SizedBox(width: 12),
                        Expanded(child: Text(p.nomComplet, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.dark))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _C.greenLight, borderRadius: BorderRadius.circular(20)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, color: _C.green, size: 12), SizedBox(width: 4), Text('Confirme', style: TextStyle(color: _C.green, fontSize: 11, fontWeight: FontWeight.w700))])),
                        const SizedBox(width: 8),
                        // Bouton PDF individuel
                        GestureDetector(
                          onTap: () async {
                            final bytes = await ConvocationPdfService.generate(
                              residentPrenom: p.prenom ?? '',
                              residentNom:    p.nom    ?? '',
                              reunionTitre:   r.titre,
                              reunionDate:    r.dateFormatee,
                              reunionHeure:   r.heureFormatee,
                              reunionLieu:    r.lieu,
                              residenceNom:   _residenceNom,
                              trancheNom:     _trancheNom,
                              interSyndicNom: _interSyndicNom,
                            );
                            await ConvocationPdfService.share(bytes, '${p.prenom}_${p.nom}');
                          },
                          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: _C.blueLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.picture_as_pdf_rounded, color: _C.blue, size: 15)),
                        ),
                      ]),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
                  child: const Text('Fermer', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14))),
            ),
          ])),
        );
      },
    ));
  }

  Widget _miniStat(String value, String label, Color color) => Expanded(
    child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: TextStyle(color: color, fontSize: 9), textAlign: TextAlign.center),
        ])),
  );

  // ══════════════════════════════════════════════════════════
  // DIALOG SUPPRIMER
  // ══════════════════════════════════════════════════════════
  void _showDeleteConfirm(ReunionModel r) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_rounded, color: _C.coral, size: 26)),
        const SizedBox(height: 16),
        const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _C.dark)),
        const SizedBox(height: 8),
        Text('Supprimer "${r.titre}" ?', textAlign: TextAlign.center, style: const TextStyle(color: _C.textMid, fontSize: 13)),
        const SizedBox(height: 6),
        const Text('Les convocations associees seront aussi supprimees.', textAlign: TextAlign.center, style: TextStyle(color: _C.textLight, fontSize: 12)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx),
              child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.divider)),
                  child: const Text('Annuler', textAlign: TextAlign.center, style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 14))))),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () async { await _service.deleteReunion(r.id); if (!ctx.mounted) return; Navigator.pop(ctx); _load(); },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(12)),
                child: const Text('Supprimer', textAlign: TextAlign.center, style: TextStyle(color: _C.white, fontWeight: FontWeight.w700, fontSize: 14))),
          )),
        ]),
      ])),
    ));
  }
}