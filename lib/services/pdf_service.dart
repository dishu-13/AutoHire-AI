import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/resume_result.dart';

class PdfService {
  Future<void> exportResume({
    required ResumeResult result,
    required String candidateName,
  }) async {
    final document = pw.Document(
      title: 'Tailored Resume',
      author: candidateName.isEmpty ? 'AutoHire AI' : candidateName,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(36),
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) => [
          pw.Text(
            candidateName.isEmpty ? 'Tailored Resume' : candidateName,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            result.optimizedResume,
            style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 3),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'ATS Score: ${result.atsScore}/100',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (result.keywords.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Keywords: ${result.keywords.join(', ')}'),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'tailored_resume.pdf',
    );
  }
}
