// lib/screens/resident/resident_convocations_screen.dart
// ignore_for_file: avoid_multiple_underscores_for_members

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/convocation_pdf_service.dart';

class _C {
  static const coral      = Color(0xFFE8603C);
  static const coralLight = Color(0xFFFFF0EB);
  static const bg         = Color(0xFFF2F3F5);
  static const white      = Color(0xFFFFFFFF);
  static const dark       = Color(0xFF1A1A1A);
  static const textMid    = Color(0xFF5A5A6A);
  static const textLight  = Color(0xFF9A9AAF);
  static const divider    = Color(0xFFE8E8F0);
  static const blue       = Color(0xFF4B6BFB);
  static const blueLight  = Color(0xFFEEF1FF);
  static const green      = Color(0xFF34C98B);
  static const greenLight = Color(0xFFEBFAF4);
}

class ResidentConvocationsScreen extends StatefulWidget {
  final int residentId;
  const ResidentConvocationsScreen({super.key, required this.residentId});

  @override
  State<ResidentConvocationsScreen> createState() => _ResidentConvocationsScreenState();
}

class _ResidentConvocationsScreenState extends State<ResidentConvocationsScreen> {
  List<Map<String, dynamic>> _convocations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ConvocationPdfService.getConvocationsResident(widget.residentId);
    setState(() { _convocations = data; _loading = false; });
  }

  Future<void> _openPdf(Map<String, dynamic> conv) async {
    final url = conv['pdf_url'] as String?;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF non disponible'), backgroundColor: _C.coral));
      return;
    }
    await ConvocationPdfService.marquerLu(conv['id'] as int);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = Uint8List.fromList(response.bodyBytes);
        await ConvocationPdfService.share(bytes, conv['titre'] ?? 'convocation');
        _load();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur ${response.statusCode}'), backgroundColor: _C.coral));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: _C.coral));
    }
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final nonLus = _convocations.where((c) => !(c['lu'] as bool? ?? false)).length;
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(child: Column(children: [
        // Header
        Container(
          color: _C.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 38, height: 38, decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.divider)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _C.dark)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('Mes Convocations', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
              Text(nonLus > 0 ? '$nonLus non lue(s)' : '${_convocations.length} convocation(s)',
                  style: TextStyle(color: nonLus > 0 ? _C.coral : _C.textLight, fontSize: 12)),
            ])),
            Container(width: 38, height: 38, decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: _C.coral, size: 20)),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _C.coral, strokeWidth: 2.5))
            : RefreshIndicator(
          color: _C.coral,
          onRefresh: _load,
          child: _convocations.isEmpty
              ? ListView(children: [
            const SizedBox(height: 80),
            Center(child: Column(children: [
              Container(width: 72, height: 72, decoration: BoxDecoration(color: _C.blueLight, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.mail_outline_rounded, color: _C.blue, size: 34)),
              const SizedBox(height: 18),
              const Text('Aucune convocation', style: TextStyle(color: _C.dark, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Vous recevrez ici vos convocations aux reunions', style: TextStyle(color: _C.textLight, fontSize: 13), textAlign: TextAlign.center),
            ])),
          ])
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            itemCount: _convocations.length,
            itemBuilder: (_, i) => _buildCard(_convocations[i]),
          ),
        )),
      ])),
    );
  }

  Widget _buildCard(Map<String, dynamic> conv) {
    final lu      = conv['lu'] as bool? ?? false;
    final titre   = conv['titre']?.toString() ?? '';
    final message = conv['message']?.toString() ?? '';
    final dateRaw = conv['date']?.toString() ?? '';
    final hasPdf  = (conv['pdf_url'] as String?)?.isNotEmpty ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lu ? _C.divider : _C.coral.withValues(alpha: 0.4), width: lu ? 1 : 1.5),
      ),
      child: Column(children: [
        // Corps
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: lu ? _C.blueLight : _C.coralLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.event_note_rounded, color: lu ? _C.blue : _C.coral, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(titre, style: TextStyle(fontWeight: lu ? FontWeight.w600 : FontWeight.w800, fontSize: 14, color: _C.dark, letterSpacing: -0.2))),
                if (!lu) Container(width: 8, height: 8, decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(4))),
              ]),
              const SizedBox(height: 5),
              Text(message, style: const TextStyle(color: _C.textMid, fontSize: 12, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 11, color: _C.textLight),
                const SizedBox(width: 4),
                Text('Recu le ${_formatDate(dateRaw)}', style: const TextStyle(color: _C.textLight, fontSize: 11)),
              ]),
            ])),
          ]),
        ),

        // Footer PDF
        if (hasPdf)
          GestureDetector(
            onTap: () => _openPdf(conv),
            child: Container(
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                border: Border(top: BorderSide(color: _C.divider)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(color: _C.coralLight, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: _C.coral, size: 16)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Convocation PDF', style: TextStyle(color: _C.dark, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('Appuyer pour ouvrir ou telecharger', style: TextStyle(color: _C.textLight, fontSize: 11)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: _C.coral, borderRadius: BorderRadius.circular(9)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.download_rounded, size: 14, color: _C.white),
                    SizedBox(width: 5),
                    Text('Ouvrir', style: TextStyle(color: _C.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
              border: Border(top: BorderSide(color: _C.divider)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: _C.textLight),
              const SizedBox(width: 8),
              Text(lu ? 'Convocation consultee' : 'PDF en cours de preparation', style: const TextStyle(color: _C.textLight, fontSize: 12)),
            ]),
          ),
      ]),
    );
  }
}