// lib/services/expense_report_pdf_service.dart

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'finance_service.dart';

class ExpenseReportPdfService {
  static final _coral      = PdfColor.fromHex('#E8603C');
  static final _coralLight = PdfColor.fromHex('#FFF0EB');
  static final _dark       = PdfColor.fromHex('#1A1A1A');
  static final _mid        = PdfColor.fromHex('#5A5A6A');
  static final _light      = PdfColor.fromHex('#9A9AAF');
  static final _bg         = PdfColor.fromHex('#F2F3F5');
  static final _divider    = PdfColor.fromHex('#E8E8F0');
  static final _green      = PdfColor.fromHex('#34C98B');
  static final _greenLight = PdfColor.fromHex('#EBFAF4');

  static Future<Uint8List> generate({
    required String residenceNom,
    required String trancheNom,
    required int annee,
    required Map<String, dynamic> financeData,
    String generatorName = "L'Inter-Syndic",
  }) async {
    final doc = pw.Document();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final double totalDepenses = (financeData['total_depenses'] as num).toDouble();
    final double totalDepensesGlobales = (financeData['total_depenses_globales'] as num? ?? 0).toDouble();
    final double totalRevenus = (financeData['total_revenus'] as num).toDouble();
    final double solde = (financeData['solde'] as num).toDouble();
    final List<Map<String, dynamic>> recentExpenses = List<Map<String, dynamic>>.from(financeData['recent_expenses'] ?? []);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Container(
          height: 60,
          child: pw.Row(
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
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                  pw.Text('ResiManager', style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('Rapport Financier Annuel', style: pw.TextStyle(color: _mid, fontSize: 8)),
                ]),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                pw.Text(residenceNom, style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Tranche : $trancheNom | Année : $annee', style: pw.TextStyle(color: _mid, fontSize: 8)),
              ]),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${ctx.pageNumber} sur ${ctx.pagesCount} - Généré le $today',
            style: pw.TextStyle(color: _light, fontSize: 8),
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          
          // Titre principal
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: pw.BoxDecoration(color: _coralLight, borderRadius: pw.BorderRadius.circular(9)),
            child: pw.Column(children: [
              pw.Text('RAPPORT DE DEPENSES ET REVENUS',
                  style: pw.TextStyle(color: _coral, fontWeight: pw.FontWeight.bold, fontSize: 16),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.Text('Exercice $annee - Tranche $trancheNom',
                  style: pw.TextStyle(color: _mid, fontSize: 11),
                  textAlign: pw.TextAlign.center),
            ]),
          ),
          pw.SizedBox(height: 24),

          // Résumé financier (Cards)
          pw.Row(
            children: [
              _buildStatCard('REVENUS', '${totalRevenus.toStringAsFixed(2)} DH', _green, _greenLight),
              pw.SizedBox(width: 16),
              _buildStatCard('DEPENSES', '${(totalDepenses + totalDepensesGlobales).toStringAsFixed(2)} DH', _coral, _coralLight),
              pw.SizedBox(width: 16),
              _buildStatCard('SOLDE', '${solde.toStringAsFixed(2)} DH', solde >= 0 ? _green : _coral, solde >= 0 ? _greenLight : _coralLight),
            ],
          ),
          pw.SizedBox(height: 32),

          // Titre section tableau
          pw.Text('Détail des Dépenses', style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 12),

          // Tableau des dépenses
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _divider, width: 0.5),
              bottom: pw.BorderSide(color: _divider, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FixedColumnWidth(70),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _bg),
                children: [
                  _tableHeader('Date'),
                  _tableHeader('Description / Catégorie'),
                  _tableHeader('Tranche'),
                  _tableHeader('Type'),
                  _tableHeader('Montant'),
                ],
              ),
              // Lignes
              ...recentExpenses.map((e) {
                final dateStr = e['date'] != null ? DateFormat('dd/MM/yy').format(DateTime.parse(e['date'])) : '-';
                return pw.TableRow(
                  children: [
                    _tableCell(dateStr),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(e['description'] ?? 'Sans description', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(e['categorie_nom'] ?? '-', style: pw.TextStyle(fontSize: 8, color: _mid)),
                        ],
                      ),
                    ),
                    _tableCell(e['tranche'] ?? 'Général'),
                    _tableCell(e['type'] ?? 'Spécifique'),
                    _tableCell('${(e['montant'] as num).toDouble().toStringAsFixed(2)} DH', align: pw.TextAlign.right),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 40),

          // Breakdown section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Notes sur le calcul :', style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 6),
                    pw.Bullet(text: 'Les dépenses spécifiques sont affectées à 100% à cette tranche.', style: pw.TextStyle(fontSize: 8, color: _mid)),
                    pw.Bullet(text: 'Les dépenses "Quote-part Inter-Syndic" sont partagées entre les tranches gérées par le même Inter-Syndic.', style: pw.TextStyle(fontSize: 8, color: _mid)),
                    pw.Bullet(text: 'Les dépenses "Quote-part Global" correspondent à la part de cette tranche dans les frais généraux de la résidence.', style: pw.TextStyle(fontSize: 8, color: _mid)),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Container(
                width: 150,
                child: pw.Column(
                  children: [
                    _totalRow('Total Spécifique', totalDepenses),
                    _totalRow('Total Quote-part', totalDepensesGlobales),
                    pw.Divider(color: _dark, thickness: 1),
                    _totalRow('TOTAL CHARGES', totalDepenses + totalDepensesGlobales, isBold: true),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 60),
          
          // Signature
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Fait à $residenceNom', style: pw.TextStyle(color: _mid, fontSize: 9)),
                pw.SizedBox(height: 5),
                pw.Text('L\'INTER-SYNDIC', style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 30),
                pw.Container(width: 100, height: 1, color: _divider),
                pw.Text('Signature & Cachet', style: pw.TextStyle(color: _light, fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color, PdfColor bg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 8)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(color: _dark, fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: _dark)),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _dark), textAlign: align),
    );
  }

  static pw.Widget _totalRow(String label, double value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('${value.toStringAsFixed(2)} DH', style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static Future<void> preview(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> share(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: '$filename.pdf');
  }
}
