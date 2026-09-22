import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/models/models.dart';

/// Clean High-Contrast Thermal Receipt Widget
/// Rendered inside RepaintBoundary with pure white background and pure black typography
/// for flawless 203 DPI thermal printing output.
class ReceiptWidget extends StatelessWidget {
  final SaleModel sale;
  final CustomerModel? customer;
  final TreasuryModel treasury;
  final String storeName;
  final String taxNumber;

  const ReceiptWidget({
    super.key,
    required this.sale,
    this.customer,
    required this.treasury,
    this.storeName = 'مجموعة الفخامة التجارية - LUXURY POS',
    this.taxNumber = '310987654300003',
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('yyyy-MM-dd HH:mm:ss');
    final currencyFormat = intl.NumberFormat('#,##0.00', 'ar_SA');

    return Container(
      width: 380,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Store Header
            Text(
              storeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'sans-serif',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'الرقم الضريبي: $taxNumber',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildDottedDivider(),
            const SizedBox(height: 8),

            // Invoice Meta
            _buildReceiptRow('رقم الفاتورة:', sale.invoiceNumber, isBold: true),
            _buildReceiptRow('التاريخ والوقت:', dateFormat.format(sale.createdAt)),
            _buildReceiptRow('الخزينة:', treasury.name),
            if (customer != null) ...[
              _buildReceiptRow('العميل:', customer!.name),
              _buildReceiptRow('جوال العميل:', customer!.phone),
            ],
            _buildReceiptRow('نوع الدفع:', sale.paymentType.displayNameArabic, isBold: true),

            const SizedBox(height: 8),
            _buildSolidDivider(),
            const SizedBox(height: 8),

            // Items Table Header
            const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'الصنف',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'الكمية',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'السعر',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'الإجمالي',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildDottedDivider(),
            const SizedBox(height: 6),

            // Items Rows
            ...sale.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        item.product.name,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        currencyFormat.format(item.unitPrice),
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        currencyFormat.format(item.totalPrice),
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            _buildSolidDivider(),
            const SizedBox(height: 8),

            // Financial Summary
            _buildReceiptRow('المجموع الفرعي:', '${currencyFormat.format(sale.totalAmount + sale.discount)} ر.س'),
            if (sale.discount > 0)
              _buildReceiptRow('الخصم:', '- ${currencyFormat.format(sale.discount)} ر.س', textColor: Colors.black),
            _buildReceiptRow(
              'الصافي المطلوب:',
              '${currencyFormat.format(sale.totalAmount)} ر.س',
              isBold: true,
              fontSize: 14,
            ),
            _buildDottedDivider(),
            const SizedBox(height: 4),
            _buildReceiptRow('المدفوع نقداً:', '${currencyFormat.format(sale.paidAmount)} ر.س'),
            if (sale.remainingDebt > 0) ...[
              _buildReceiptRow(
                'المتبقي في الذمة (دين):',
                '${currencyFormat.format(sale.remainingDebt)} ر.س',
                isBold: true,
              ),
              if (customer != null)
                _buildReceiptRow(
                  'إجمالي ديون العميل الحالية:',
                  '${currencyFormat.format(customer!.totalDebt + sale.remainingDebt)} ر.س',
                ),
            ],

            const SizedBox(height: 12),
            _buildDottedDivider(),
            const SizedBox(height: 12),

            // QR Code for Tax and Invoice Verification
            QrImageView(
              data: 'POS_INV:${sale.invoiceNumber}|TOTAL:${sale.totalAmount}|DATE:${sale.createdAt.toIso8601String()}|TAX:$taxNumber',
              version: QrVersions.auto,
              size: 130.0,
              gapless: false,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'امسح الرمز للتحقق من الفاتورة',
              style: TextStyle(fontSize: 10, color: Colors.black87),
            ),

            const SizedBox(height: 12),
            const Text(
              'شكراً لزيارتكم الكريمة\nالبضاعة المباعة تستبدل خلال 3 أيام بشرط وجود الفاتورة الأصلية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 11,
    Color textColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedDivider() {
    return const Text(
      '------------------------------------------------',
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(color: Colors.black54, fontSize: 10, letterSpacing: 2),
    );
  }

  Widget _buildSolidDivider() {
    return Container(
      height: 1.2,
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 2),
    );
  }
}
