
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ReceiptService {
  // Encryption key and IV (for demonstration; use secure key management in production)
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooknows!'); // 32 chars
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  
  static Future<File> generateDonationReceipt({
    required String receiptNumber,
    required DateTime date,
    required int amount,
    required String ngoName,
    required String category,
    required String donorName,
    required String donorEmail,
    String? donorPhone,
    String? paymentId,
    String? paymentMethod,
    bool isMonthlySubscription = false,
  }) async {
    final pdf = pw.Document();
    
    final dateFormatted = DateFormat('dd MMMM yyyy').format(date);
    final timeFormatted = DateFormat('hh:mm a').format(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(receiptNumber, dateFormatted),
              pw.SizedBox(height: 30),
              
              // Success Banner
              _buildSuccessBanner(amount),
              pw.SizedBox(height: 30),
              
              // Thank You Message
              _buildThankYouMessage(ngoName),
              pw.SizedBox(height: 25),
              
              // Donor Information
              _buildSection('DONOR INFORMATION', [
                _buildInfoRow('Name', donorName),
                _buildInfoRow('Email', donorEmail),
                if (donorPhone != null && donorPhone.isNotEmpty)
                  _buildInfoRow('Phone', donorPhone),
              ]),
              pw.SizedBox(height: 20),
              
              // Donation Details
              _buildSection('DONATION DETAILS', [
                _buildInfoRow('Amount', '₹$amount'),
                _buildInfoRow('Date', dateFormatted),
                _buildInfoRow('Time', timeFormatted),
                _buildInfoRow('Category', category),
                _buildInfoRow('Beneficiary', ngoName),
                _buildInfoRow('Payment Type', isMonthlySubscription ? 'Monthly Auto-Pay' : 'One-Time'),
                if (paymentMethod != null)
                  _buildInfoRow('Payment Method', paymentMethod),
                if (paymentId != null)
                  _buildInfoRow('Transaction ID', paymentId),
              ]),
              pw.SizedBox(height: 30),
              
              // Footer Note
              _buildFooterNote(),
              
              pw.Spacer(),
              
              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    // Save encrypted PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/donation_receipt_$receiptNumber.pdf');
    final pdfBytes = await pdf.save();
    final encrypted = _encrypter.encryptBytes(pdfBytes, iv: _iv);
    await file.writeAsBytes(encrypted.bytes);
    return file;
  }

  /// Decrypts an encrypted PDF receipt file
  static Future<Uint8List> decryptReceiptFile(File file) async {
    final encryptedBytes = await file.readAsBytes();
    final decrypted = _encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: _iv);
    return Uint8List.fromList(decrypted);
  }

  static pw.Widget _buildHeader(String receiptNumber, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0099B8), width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF0099B8),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'Connect NGO',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'DONATION RECEIPT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF333333),
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Receipt #',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                receiptNumber,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Date: $date',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSuccessBanner(int amount) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF0099B8),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(30),
            ),
            child: pw.Icon(
              const pw.IconData(0xe86c), // check icon
              color: const PdfColor.fromInt(0xFF0099B8),
              size: 24,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Payment Successful',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '₹$amount',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 36,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThankYouMessage(String ngoName) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF5F9FA),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE0E0E0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Thank you for your generous contribution!',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF333333),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Your donation to $ngoName will help make a real difference in the lives of those in need. '
            'We are grateful for your support in our mission to create positive change.',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
              lineSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF0099B8),
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFE0E0E0)),
          ),
          child: pw.Column(
            children: rows,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterNote() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF9E6),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFE082)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ℹ️ ',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Expanded(
            child: pw.Text(
              'This receipt is auto-generated and serves as proof of your donation. '
              'Please keep it for your records. For any queries, contact support@connectngo.com',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey800,
                lineSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Connect NGO',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF0099B8),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Empowering Communities, Changing Lives',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'www.connectngo.com',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'support@connectngo.com',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> shareReceipt(File receiptFile) async {
    await Share.shareXFiles(
      [XFile(receiptFile.path)],
      text: 'My Donation Receipt from Connect NGO',
      subject: 'Donation Receipt',
    );
  }

  static Future<void> generateAndShareReceipt({
    required String receiptNumber,
    required DateTime date,
    required int amount,
    required String ngoName,
    required String category,
    required String donorName,
    required String donorEmail,
    String? donorPhone,
    String? paymentId,
    String? paymentMethod,
    bool isMonthlySubscription = false,
  }) async {
    final file = await generateDonationReceipt(
      receiptNumber: receiptNumber,
      date: date,
      amount: amount,
      ngoName: ngoName,
      category: category,
      donorName: donorName,
      donorEmail: donorEmail,
      donorPhone: donorPhone,
      paymentId: paymentId,
      paymentMethod: paymentMethod,
      isMonthlySubscription: isMonthlySubscription,
    );
    
    await shareReceipt(file);
  }
}
