// lib/services/apartment_pdf_service.dart

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/appartement_model.dart';

class ApartmentPdfService {
  static final _coral      = PdfColor.fromHex('#E8603C');
  static final _coralLight = PdfColor.fromHex('#FFF0EB');
  static final _dark       = PdfColor.fromHex('#1A1A1A');
  static final _mid        = PdfColor.fromHex('#5A5A6A');
  static final _light      = PdfColor.fromHex('#9A9AAF');
  static final _bg         = PdfColor.fromHex('#F2F3F5');
  static final _divider    = PdfColor.fromHex('#E8E8F0');
  static final _headerSub  = PdfColor.fromHex('#FFCAB5');

  static Future<Uint8List> generate({
    required List<AppartementModel> apartments,
    required String residenceNom,
    required String trancheNom,
  }) async {
    final doc = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final occupiedCount = apartments.where((a) => a.statut == StatutAppartEnum.occupe).length;
    final vacantCount = apartments.where((a) => a.statut == StatutAppartEnum.libre).length;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(children: [
                  pw.Container(
                    width: 34, height: 34,
                    decoration: pw.BoxDecoration(color: _coral, borderRadius: pw.BorderRadius.circular(6)),
                    alignment: pw.Alignment.center,
                    child: pw.Text('RM', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('ResiManager', style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text('Rapport d\'Etat des Appartements', style: pw.TextStyle(color: _light, fontSize: 8)),
                  ]),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text(residenceNom, style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Tranche : $trancheNom', style: pw.TextStyle(color: _mid, fontSize: 8)),
                  pw.Text('Date : $today', style: pw.TextStyle(color: _light, fontSize: 8)),
                ]),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(height: 1, color: _divider),
            pw.SizedBox(height: 15),
          ],
        ),
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(color: _divider, thickness: 0.5),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Document genere par ResiManager', style: pw.TextStyle(color: _light, fontSize: 7)),
                pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: pw.TextStyle(color: _light, fontSize: 7)),
              ],
            ),
          ],
        ),
        build: (ctx) => [
          // Titre (Inspiré du theme convocation)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: pw.BoxDecoration(color: _coralLight, borderRadius: pw.BorderRadius.circular(9)),
            child: pw.Column(children: [
              pw.Text('RAPPORT D\'ÉTAT DES APPARTEMENTS',
                  style: pw.TextStyle(color: _coral, fontWeight: pw.FontWeight.bold, fontSize: 14),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 3),
              pw.Text('Résumé global de l\'inventaire et de l\'occupation',
                  style: pw.TextStyle(color: _mid, fontSize: 9),
                  textAlign: pw.TextAlign.center),
            ]),
          ),
          pw.SizedBox(height: 20),

          // Résumé Box (Inspiré du style "Box infos" avec bordure gauche coral)
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(color: _bg, borderRadius: pw.BorderRadius.circular(9)),
            child: pw.Row(children: [
              pw.Container(
                width: 5, height: 60,
                decoration: pw.BoxDecoration(
                  color: _coral,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: const pw.Radius.circular(9),
                    bottomLeft: const pw.Radius.circular(9),
                  ),
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('TOTAL', apartments.length.toString(), _dark),
                      _buildStatItem('OCCUPÉS', occupiedCount.toString(), _coral),
                      _buildStatItem('VACANTS', vacantCount.toString(), _mid),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          pw.SizedBox(height: 25),

          // Tableau
          pw.Table(
            border: pw.TableBorder.all(color: _divider, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Numero
              1: const pw.FlexColumnWidth(2.5), // Immeuble
              2: const pw.FlexColumnWidth(2), // Statut
              3: const pw.FlexColumnWidth(4), // Resident
            },
            children: [
              // Header du tableau
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _bg),
                children: [
                  _tableHeader('Numéro'),
                  _tableHeader('Immeuble'),
                  _tableHeader('Statut'),
                  _tableHeader('Résident'),
                ],
              ),
              // Lignes
              ...apartments.map((apt) => pw.TableRow(
                children: [
                  _tableCell(apt.numeroAppartement.isEmpty ? apt.numero : apt.numeroAppartement),
                  _tableCell(apt.immeubleNom ?? apt.immeubleNum ?? '-'),
                  _tableCell(
                    apt.statut == StatutAppartEnum.occupe ? 'Occupé' : 'Libre',
                    color: apt.statut == StatutAppartEnum.occupe ? _coral : _mid,
                    isBold: true,
                  ),
                  _tableCell(apt.residentNomComplet ?? (apt.statut == StatutAppartEnum.occupe ? 'Inconnu' : '-')),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Note de fin
          pw.Container(height: 0.8, color: _divider),
          pw.SizedBox(height: 10),
          pw.Text(
            'Ce rapport presente l\'etat actuel de l\'inventaire des appartements. Pour toute modification ou mise a jour, veuillez vous referer a l\'interface d\'administration de ResiManager.',
            style: pw.TextStyle(color: _light, fontSize: 8, lineSpacing: 1.5),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildStatItem(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: pw.TextStyle(color: _light, fontSize: 7, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(color: color, fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }


  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _tableCell(String text, {PdfColor? color, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: color ?? _dark,
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<void> share(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: '$filename.pdf');
  }

  static Future<void> preview(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
