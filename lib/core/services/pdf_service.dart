import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:djoulagest_mobile/core/utils/formatters.dart';
import 'package:djoulagest_mobile/features/logistics/domain/entities/mission_entity.dart';
import 'package:djoulagest_mobile/features/sales/domain/entities/sale_entity.dart';

class PdfService {
  // ─── Bon de livraison (mission logistique) ──────────────────────────────────

  static Future<void> openBonLivraison(MissionEntity mission) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('BON DE LIVRAISON', mission.numero),
            pw.SizedBox(height: 20),
            _sectionTitle('Trajet'),
            _row('Départ', mission.depotDepartNom ?? '—'),
            _row('Destination', mission.depotArriveeNom ?? '—'),
            _row('Chauffeur', mission.chauffeurNom ?? '—'),
            _row('Véhicule', mission.vehiculeImmat ?? '—'),
            pw.SizedBox(height: 16),
            if (mission.dateDepartPrevue != null)
              _row('Départ prévu', AppFormatters.dateTime(mission.dateDepartPrevue!)),
            if (mission.dateDepartReelle != null)
              _row('Départ réel', AppFormatters.dateTime(mission.dateDepartReelle!)),
            if (mission.dateArriveeReelle != null)
              _row('Arrivée', AppFormatters.dateTime(mission.dateArriveeReelle!)),
            if (mission.lignes.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _sectionTitle('Marchandises transportées'),
              pw.SizedBox(height: 8),
              _table(
                headers: ['Produit', 'Réf.', 'Qté envoyée', 'Qté reçue'],
                rows: mission.lignes.map((l) => [
                  l.produitNom,
                  l.produitReference,
                  l.quantite.toStringAsFixed(0),
                  (l.quantiteRecue ?? l.quantite).toStringAsFixed(0),
                ]).toList(),
              ),
            ],
            if (mission.isLitige && mission.motifLitige != null) ...[
              pw.SizedBox(height: 20),
              _sectionTitle('Litige signalé'),
              _row('Motif', mission.motifLitige!),
            ],
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _signatureBox('Signature expéditeur'),
                _signatureBox('Signature destinataire'),
              ],
            ),
            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );

    await _saveAndOpen(pdf, 'bon_livraison_${mission.numero}.pdf');
  }

  // ─── Facture de vente ───────────────────────────────────────────────────────

  static Future<void> openFacture(SaleEntity sale) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('FACTURE', sale.numero),
            pw.SizedBox(height: 20),
            _sectionTitle('Client'),
            _row('Nom', sale.clientNom),
            pw.SizedBox(height: 16),
            _sectionTitle('Paiement'),
            _row('Statut', sale.statutLabel),
            if (sale.modePaiement != null)
              _row('Mode', sale.modePaiement!),
            _row('Montant TTC', AppFormatters.gnf(sale.montantTtc)),
            if (sale.remise > 0) _row('Remise', AppFormatters.gnf(sale.remise)),
            _row('Montant payé', AppFormatters.gnf(sale.montantPaye)),
            if (!sale.isSolde)
              _row('Reste à payer', AppFormatters.gnf(sale.resteAPayer)),
            pw.SizedBox(height: 20),
            _row('Date', AppFormatters.dateTime(sale.createdAt)),
            pw.Spacer(),
            _footer(),
          ],
        ),
      ),
    );

    await _saveAndOpen(pdf, 'facture_${sale.numero}.pdf');
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static pw.Widget _header(String type, String numero) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('DjoulaGest',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1A56A0))),
            pw.Text('Système de gestion intégrée',
                style: pw.TextStyle(fontSize: 10,
                    color: const PdfColor.fromInt(0xFF6B7280))),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(type,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(numero,
                style: pw.TextStyle(fontSize: 14,
                    color: const PdfColor.fromInt(0xFF1A56A0))),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
              color: PdfColor.fromInt(0xFF1A56A0), width: 1.5),
        ),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF1A56A0),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 10,
                    color: const PdfColor.fromInt(0xFF6B7280))),
          ),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    const headerColor = PdfColor.fromInt(0xFF1A56A0);
    const rowEven = PdfColor.fromInt(0xFFF9FAFB);

    return pw.Table(
      border: pw.TableBorder.all(
          color: const PdfColor.fromInt(0xFFE5E7EB), width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerColor),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(h,
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          )).toList(),
        ),
        ...rows.asMap().entries.map((e) => pw.TableRow(
          decoration: pw.BoxDecoration(
              color: e.key % 2 == 0 ? rowEven : PdfColors.white),
          children: e.value.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(cell, style: const pw.TextStyle(fontSize: 9)),
          )).toList(),
        )),
      ],
    );
  }

  static pw.Widget _signatureBox(String label) {
    return pw.Container(
      width: 200,
      height: 80,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
            color: const PdfColor.fromInt(0xFFD1D5DB), width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Center(
        child: pw.Text(label,
            style: pw.TextStyle(fontSize: 9,
                color: const PdfColor.fromInt(0xFF9CA3AF))),
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Text(
      'Document généré par DjoulaGest — ${AppFormatters.dateTime(DateTime.now())}',
      style: pw.TextStyle(
          fontSize: 8, color: const PdfColor.fromInt(0xFF9CA3AF)),
    );
  }

  static Future<void> _saveAndOpen(pw.Document pdf, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
