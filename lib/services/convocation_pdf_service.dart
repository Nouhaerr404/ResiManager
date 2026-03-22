// lib/services/convocation_pdf_service.dart
// ignore_for_file: avoid_multiple_underscores_for_members

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConvocationPdfService {
  static final _db = Supabase.instance.client;

  static final _coral      = PdfColor.fromHex('#E8603C');
  static final _coralLight = PdfColor.fromHex('#FFF0EB');
  static final _dark       = PdfColor.fromHex('#1A1A1A');
  static final _mid        = PdfColor.fromHex('#5A5A6A');
  static final _light      = PdfColor.fromHex('#9A9AAF');
  static final _bg         = PdfColor.fromHex('#F2F3F5');
  static final _divider    = PdfColor.fromHex('#E8E8F0');
  static final _headerSub  = PdfColor.fromHex('#FFCAB5');

  // ─────────────────────────────────────────────────────────
  // 1. Generer le PDF en memoire
  // ─────────────────────────────────────────────────────────
  static Future<Uint8List> generate({
    required String residentPrenom,
    required String residentNom,
    required String reunionTitre,
    required String reunionDate,
    required String reunionHeure,
    required String reunionLieu,
    required String residenceNom,
    required String trancheNom,
    String interSyndicNom = "L'Inter-Syndic",
  }) async {
    final doc   = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Stack(children: [
          pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),

          // Header
          pw.Positioned(
            top: 0, left: 0, right: 0,
            child: pw.Container(
              height: 68,
              color: _coral,
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    pw.Container(
                      width: 34, height: 34,
                      decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(6)),
                      alignment: pw.Alignment.center,
                      child: pw.Text('RM', style: pw.TextStyle(color: _coral, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                      pw.Text('ResiManager', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('Convocation Reunion Copropriete', style: pw.TextStyle(color: _headerSub, fontSize: 8)),
                    ]),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                    pw.Text(residenceNom, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Tranche : $trancheNom', style: pw.TextStyle(color: _headerSub, fontSize: 8)),
                  ]),
                ],
              ),
            ),
          ),

          // Corps
          pw.Positioned(
            top: 78, left: 26, right: 26, bottom: 46,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [

              // Titre
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: pw.BoxDecoration(color: _coralLight, borderRadius: pw.BorderRadius.circular(9)),
                child: pw.Column(children: [
                  pw.Text('CONVOCATION A LA REUNION',
                      style: pw.TextStyle(color: _coral, fontWeight: pw.FontWeight.bold, fontSize: 14),
                      textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 3),
                  pw.Text('"$reunionTitre"',
                      style: pw.TextStyle(color: _mid, fontSize: 10),
                      textAlign: pw.TextAlign.center),
                ]),
              ),
              pw.SizedBox(height: 14),

              // Adresse + date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('$residentPrenom $residentNom',
                        style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                    pw.Text(residenceNom, style: pw.TextStyle(color: _mid, fontSize: 9)),
                    pw.Text('Tranche : $trancheNom', style: pw.TextStyle(color: _mid, fontSize: 9)),
                  ]),
                  pw.Text('Le $today', style: pw.TextStyle(color: _light, fontSize: 8.5)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(height: 0.8, color: _divider),
              pw.SizedBox(height: 10),

              // Formule appel
              pw.RichText(text: pw.TextSpan(children: [
                pw.TextSpan(text: 'Madame, Monsieur ', style: pw.TextStyle(color: _dark, fontSize: 10.5)),
                pw.TextSpan(text: '$residentPrenom $residentNom',
                    style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                pw.TextSpan(text: ',', style: pw.TextStyle(color: _dark, fontSize: 10.5)),
              ])),
              pw.SizedBox(height: 6),
              pw.Text(
                'Nous avons l\'honneur de vous convoquer a la reunion de copropriete '
                    'de la $residenceNom, tranche $trancheNom, dont les details sont les suivants :',
                style: pw.TextStyle(color: _dark, fontSize: 10.5, lineSpacing: 1.8),
              ),
              pw.SizedBox(height: 12),

              // Box infos
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(color: _bg, borderRadius: pw.BorderRadius.circular(9)),
                child: pw.Row(children: [
                  pw.Container(
                    width: 5, height: 104,
                    decoration: pw.BoxDecoration(
                      color: _coral,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: const pw.Radius.circular(9),
                        bottomLeft: const pw.Radius.circular(9),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 12),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      _infoRow('DATE',  reunionDate),
                      pw.SizedBox(height: 10),
                      _infoRow('HEURE', reunionHeure),
                      pw.SizedBox(height: 10),
                      _infoRow('LIEU',  reunionLieu),
                    ]),
                  ),
                ]),
              ),
              pw.SizedBox(height: 12),

              // Corps texte
              pw.Text(
                'Votre presence est indispensable pour le bon deroulement de cette reunion. '
                    'Nous vous prions de bien vouloir confirmer votre participation aupres de '
                    'l\'administration dans les meilleurs delais.',
                style: pw.TextStyle(color: _dark, fontSize: 10.5, lineSpacing: 1.8),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'L\'ordre du jour sera communique lors de la reunion. Tout point que vous '
                    'souhaiteriez soumettre a la discussion peut etre transmis a l\'inter-syndic '
                    'avant la date de la reunion.',
                style: pw.TextStyle(color: _dark, fontSize: 10.5, lineSpacing: 1.8),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'En cas d\'empechement majeur, nous vous remercions de bien vouloir nous '
                    'en informer dans les plus brefs delais.',
                style: pw.TextStyle(color: _dark, fontSize: 10.5, lineSpacing: 1.8),
              ),
              pw.SizedBox(height: 16),
              pw.Container(height: 0.8, color: _divider),
              pw.SizedBox(height: 9),

              // Signature
              pw.Text('Cordialement,', style: pw.TextStyle(color: _mid, fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Text(interSyndicNom,
                  style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.Text('Inter-Syndic - $residenceNom',
                  style: pw.TextStyle(color: _coral, fontSize: 8.5)),
            ]),
          ),

          // Footer
          pw.Positioned(
            bottom: 0, left: 0, right: 0,
            child: pw.Container(
              height: 40, color: _bg,
              padding: const pw.EdgeInsets.symmetric(horizontal: 14),
              child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                pw.Container(height: 0.5, color: _divider),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Document genere par ResiManager  |  $residenceNom  |  Tranche : $trancheNom',
                  style: pw.TextStyle(color: _light, fontSize: 7.5),
                  textAlign: pw.TextAlign.center,
                ),
              ]),
            ),
          ),
        ]),
      ),
    );

    return doc.save();
  }

  // ─────────────────────────────────────────────────────────
  // 2. Creer notification resident + partager le PDF localement
  //
  // L'upload Storage necessite une policy RLS.
  // Si le bucket n'est pas configure, on envoie juste la notification
  // et on partage le PDF via le share sheet du telephone.
  //
  // Pour activer l'upload Storage :
  //   Supabase → Storage → convocations → Policies → ajouter :
  //   INSERT : TO authenticated WITH CHECK (bucket_id = 'convocations')
  //   SELECT : TO public USING (bucket_id = 'convocations')
  // ─────────────────────────────────────────────────────────
  static Future<void> uploadAndNotify({
    required Uint8List bytes,
    required int residentId,
    required int reunionId,
    required String reunionTitre,
    required String reunionDate,
    required String reunionHeure,
    required String reunionLieu,
  }) async {
    String? pdfUrl;

    // Tentative d'upload dans Storage (optionnel — necessite RLS configure)
    try {
      final ts   = DateTime.now().millisecondsSinceEpoch;
      final path = '$residentId/${reunionId}_$ts.pdf';

      await _db.storage.from('convocations').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
            contentType: 'application/pdf', upsert: true),
      );
      pdfUrl = _db.storage.from('convocations').getPublicUrl(path);
    } catch (_) {
      // RLS bloque l'upload — on continue sans URL Storage
      // Le PDF sera partage via share sheet separement
      pdfUrl = null;
    }

    // Creer la notification pour le resident
    final message = pdfUrl != null
        ? 'Vous etes convoque(e) a la reunion "$reunionTitre" '
        'le $reunionDate a $reunionHeure, $reunionLieu. PDF::$pdfUrl'
        : 'Vous etes convoque(e) a la reunion "$reunionTitre" '
        'le $reunionDate a $reunionHeure, lieu : $reunionLieu.';

    await _db.from('notifications').insert({
      'user_id':    residentId,
      'titre':      'Convocation : $reunionTitre',
      'message':    message,
      'type':       'reunion',
      'lu':         false,
      'reunion_id': reunionId,
    });

    // Partager le PDF via le share sheet (toujours disponible)
    await share(bytes, '${reunionTitre}_$residentId');
  }

  // ─────────────────────────────────────────────────────────
  // 3. Recuperer les convocations d'un resident (espace resident)
  // ─────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getConvocationsResident(int residentId) async {
    try {
      final res = await _db
          .from('notifications')
          .select('id, titre, message, lu, created_at, reunion_id')
          .eq('user_id', residentId)
          .eq('type', 'reunion')
          .order('created_at', ascending: false);

      return (res as List? ?? []).map((n) {
        final msg = n['message']?.toString() ?? '';
        final idx = msg.indexOf('PDF::');
        final pdfUrl = idx != -1 ? msg.substring(idx + 5) : null;
        final texte  = idx != -1 ? msg.substring(0, idx).trim() : msg;
        return {
          'id':         n['id'],
          'titre':      n['titre']?.toString() ?? '',
          'message':    texte,
          'pdf_url':    pdfUrl,
          'lu':         n['lu'] as bool? ?? false,
          'date':       n['created_at']?.toString() ?? '',
          'reunion_id': n['reunion_id'],
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // 4. Marquer comme lu
  // ─────────────────────────────────────────────────────────
  static Future<void> marquerLu(int notificationId) async {
    try {
      await _db.from('notifications').update({'lu': true}).eq('id', notificationId);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────
  // 5. Partager via le systeme (share sheet)
  // ─────────────────────────────────────────────────────────
  static Future<void> share(Uint8List bytes, String titre) async {
    final safe = titre.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    await Printing.sharePdf(bytes: bytes, filename: 'convocation_$safe.pdf');
  }

  // ─────────────────────────────────────────────────────────
  // 6. Apercu impression
  // ─────────────────────────────────────────────────────────
  static Future<void> preview(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  // Ligne info dans la box date/heure/lieu
  static pw.Widget _infoRow(String label, String value) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label,
          style: pw.TextStyle(color: PdfColor.fromHex('#9A9AAF'), fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 2),
      pw.Text(value,
          style: pw.TextStyle(color: PdfColor.fromHex('#1A1A1A'), fontSize: 12.5, fontWeight: pw.FontWeight.bold)),
    ]);
  }
}