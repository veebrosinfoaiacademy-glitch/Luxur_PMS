import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/clinic_logo.dart';

class HalfA4BillDialog extends StatelessWidget {
  final String patientName;
  final String patientId;
  final String treatmentName;
  final String sessionInfo;
  final int amount;
  final String paymentMode;
  final String billNumber;
  final String date;

  const HalfA4BillDialog({
    super.key,
    required this.patientName,
    required this.patientId,
    required this.treatmentName,
    required this.sessionInfo,
    this.amount = 4500,
    this.paymentMode = 'Online',
    this.billNumber = 'BILL-2025-0089',
    this.date = '15 Apr 2025',
  });

  static Future<void> show(
    BuildContext context, {
    required String patientName,
    required String patientId,
    required String treatmentName,
    required String sessionInfo,
    int amount = 4500,
    String paymentMode = 'Online',
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => HalfA4BillDialog(
        patientName: patientName,
        patientId: patientId,
        treatmentName: treatmentName,
        sessionInfo: sessionInfo,
        amount: amount,
        paymentMode: paymentMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Control Bar (Print & Close)
          Container(
            width: 440,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Bill Invoice Preview (Half-A4 / A5)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Triggering print dialog for Half-A4 receipt...')),
                        );
                      },
                      icon: const Icon(Icons.print, size: 14),
                      label: const Text('Print / Save PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actual Half-A4 Page (A5 format: approx 148mm x 210mm proportional aspect ratio)
          Container(
            width: 440,
            constraints: const BoxConstraints(maxHeight: 620),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Clinic Branding & Receipt Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ClinicLogo(),
                          const SizedBox(height: 6),
                          Text(
                            '28/4, Green View Plaza, Kadavanthra\nKochi, Kerala - 682020\nPhone: +91 484 220 5678',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TAX INVOICE',
                            style: AppTypography.headingSmall.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invoice No: $billNumber',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Date: $date',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),

                  // Patient Details Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAF7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E9E2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILLED TO:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              patientName,
                              style: GoogleFonts.ebGaramond(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Patient ID: $patientId',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PAID IN FULL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Payment Mode: $paymentMode',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Line Items Table
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: const Color(0xFFF1F5F9),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text('Service / Treatment Description', style: AppTypography.tableHeader.copyWith(fontSize: 10.5)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('Session', style: AppTypography.tableHeader.copyWith(fontSize: 10.5)),
                              ),
                              Text('Amount (₹)', style: AppTypography.tableHeader.copyWith(fontSize: 10.5)),
                            ],
                          ),
                        ),
                        // Table Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      treatmentName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      'Clinic procedure performed by Dr. Anjali Nair',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  sessionInfo,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5),
                                ),
                              ),
                              Text(
                                '₹${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Total calculation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text('Subtotal:  ', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
                              Text('₹$amount', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Taxes (GST 0% / Exempt):  ', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B))),
                              Text('₹0', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(height: 1, width: 160, color: const Color(0xFFCBD5E1)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Total Paid:  ', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                              Text(
                                '₹$amount',
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Signatures & Stamp area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Thank you for trusting Veebros Clinic.\nFor appointments: +91 484 220 5678',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 130,
                            height: 1,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Authorized Signatory',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
