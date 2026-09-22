import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/luxury_colors.dart';
import '../../../data/hardware/thermal_printer_service.dart';
import '../../../domain/models/models.dart';
import '../../common/glass_container.dart';
import '../pos_controller.dart';
import 'receipt_widget.dart';

/// Luxury Glass Checkout BottomSheet
/// Features Segmented Payment Selector (Cash, Debt, Split)
/// with real-time remaining debt calculation and Bluetooth thermal print trigger.
class CheckoutBottomSheet extends ConsumerStatefulWidget {
  const CheckoutBottomSheet({super.key});

  @override
  ConsumerState<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends ConsumerState<CheckoutBottomSheet> {
  PaymentType _selectedPaymentType = PaymentType.cash;
  final TextEditingController _paidAmountController = TextEditingController();
  final GlobalKey _receiptKey = GlobalKey();
  bool _isProcessing = false;
  SaleModel? _justCompletedSale;

  @override
  void initState() {
    super.initState();
    final posState = ref.read(posControllerProvider);
    _paidAmountController.text = posState.totalAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  double _getCalculatedPaidAmount(double total) {
    if (_selectedPaymentType == PaymentType.cash) {
      return total;
    } else if (_selectedPaymentType == PaymentType.creditDebt) {
      return 0.0;
    } else {
      final parsed = double.tryParse(_paidAmountController.text) ?? 0.0;
      return parsed.clamp(0.0, total);
    }
  }

  double _getCalculatedRemainingDebt(double total) {
    final paid = _getCalculatedPaidAmount(total);
    final diff = total - paid;
    return diff > 0 ? diff : 0.0;
  }

  Future<void> _handleConfirmPayment(BuildContext context) async {
    final posState = ref.read(posControllerProvider);
    final total = posState.totalAmount;
    final paid = _getCalculatedPaidAmount(total);
    final remainingDebt = _getCalculatedRemainingDebt(total);

    // Strict validation
    if ((_selectedPaymentType == PaymentType.creditDebt || _selectedPaymentType == PaymentType.split) &&
        posState.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنبيه: يجب اختيار عميل مسجل لإتمام البيع الآجل أو المجزأ'),
          backgroundColor: LuxuryColors.imperialCrimson,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final completedSale = await ref.read(posControllerProvider.notifier).checkout(
          paymentType: _selectedPaymentType,
          paidAmount: paid,
          remainingDebt: remainingDebt,
        );

    setState(() => _isProcessing = false);

    if (completedSale != null && mounted) {
      setState(() => _justCompletedSale = completedSale);
      _showReceiptPreviewAndPrint(context, completedSale);
    }
  }

  void _showReceiptPreviewAndPrint(BuildContext context, SaleModel sale) {
    final posState = ref.read(posControllerProvider);
    final treasury = posState.selectedTreasury ?? ref.read(appDatabaseProvider).getDefaultTreasury();
    final customer = posState.selectedCustomer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: LuxuryColors.obsidianBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Top Handle
                Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'معاينة الإيصال الحراري العربي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LuxuryColors.radiantGold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        Navigator.pop(ctx); // Close preview
                        Navigator.pop(context); // Close checkout sheet
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Scrollable Render Widget
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: RepaintBoundary(
                        key: _receiptKey,
                        child: ReceiptWidget(
                          sale: sale,
                          customer: customer,
                          treasury: treasury,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bluetooth Print Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuxuryColors.radiantGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.print, color: Colors.black),
                    label: const Text(
                      'طباعة الفاتورة عبر البلوتوث (ESC/POS)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () async {
                      final Uint8List? imageBytes =
                          await ThermalPrinterService.captureWidgetToMonochromeBytes(_receiptKey);
                      if (imageBytes != null) {
                        await ThermalPrinterService.instance.printArabicReceipt(imageBytes);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحويل الفاتورة لصورة نقطية أحادية وإرسال أمر الطباعة'),
                              backgroundColor: LuxuryColors.emeraldCash,
                            ),
                          );
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posControllerProvider);
    final currencyFormat = intl.NumberFormat('#,##0.00', 'ar_SA');
    final total = posState.totalAmount;
    final paid = _getCalculatedPaidAmount(total);
    final remainingDebt = _getCalculatedRemainingDebt(total);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'نافذة الدفع وإصدار الفاتورة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LuxuryColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: LuxuryColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Financial Summary Panel
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إجمالي الفاتورة المطلوب:',
                        style: TextStyle(color: LuxuryColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(total)} ر.س',
                        style: const TextStyle(
                          color: LuxuryColors.radiantGold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (posState.discount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: LuxuryColors.imperialCrimson.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LuxuryColors.imperialCrimson.withOpacity(0.4)),
                      ),
                      child: Text(
                        'خصم: ${currencyFormat.format(posState.discount)} ر.س',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Customer Selection Dropdown
            const Text(
              'العميل المرتبط بالفاتورة:',
              style: TextStyle(fontSize: 13, color: LuxuryColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Consumer(
              builder: (context, ref, _) {
                final customersAsync = ref.watch(customersListStreamProvider);
                return customersAsync.when(
                  data: (customers) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: LuxuryColors.obsidianSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CustomerModel?>(
                          value: posState.selectedCustomer,
                          isExpanded: true,
                          dropdownColor: LuxuryColors.obsidianCard,
                          hint: const Text('اختر عميل (اختياري للكاش، إلزامي للآجل)', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem<CustomerModel?>(
                              value: null,
                              child: Text('عميل نقدي عابر (بدون تسجيل)', style: TextStyle(color: Colors.white70)),
                            ),
                            ...customers.map(
                              (c) => DropdownMenuItem<CustomerModel?>(
                                value: c,
                                child: Text(
                                  '${c.name} (${c.phone}) - دين سابق: ${currencyFormat.format(c.totalDebt)} ر.س',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (selected) {
                            ref.read(posControllerProvider.notifier).setCustomer(selected);
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                );
              },
            ),
            const SizedBox(height: 18),

            // Segmented Payment Types
            const Text(
              'طريقة السداد:',
              style: TextStyle(fontSize: 13, color: LuxuryColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPaymentSegment(
                  type: PaymentType.cash,
                  label: 'كاش نقدي',
                  icon: Icons.payments_outlined,
                  activeColor: LuxuryColors.emeraldCash,
                ),
                const SizedBox(width: 8),
                _buildPaymentSegment(
                  type: PaymentType.creditDebt,
                  label: 'آجل بالكامل',
                  icon: Icons.account_balance_wallet_outlined,
                  activeColor: LuxuryColors.imperialCrimson,
                ),
                const SizedBox(width: 8),
                _buildPaymentSegment(
                  type: PaymentType.split,
                  label: 'دفع مجزأ',
                  icon: Icons.pie_chart_outline,
                  activeColor: LuxuryColors.amethystSplit,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Split Payment Details Input
            if (_selectedPaymentType == PaymentType.split) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المدفوع نقداً الآن:', style: TextStyle(fontSize: 12, color: LuxuryColors.textSecondary)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _paidAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: LuxuryColors.textPrimary, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: LuxuryColors.obsidianSurface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            suffixText: 'ر.س',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('المتبقي كدين:', style: TextStyle(fontSize: 12, color: LuxuryColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                          '${currencyFormat.format(remainingDebt)} ر.س',
                          style: const TextStyle(
                            color: LuxuryColors.imperialCrimson,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Remaining Debt notification for full credit
            if (_selectedPaymentType == PaymentType.creditDebt)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: LuxuryColors.imperialCrimson.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: LuxuryColors.imperialCrimson.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: LuxuryColors.imperialCrimson, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم تسجيل كامل المبلغ (${currencyFormat.format(total)} ر.س) كدين على العميل المختار.',
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            // Confirm & Print Action Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LuxuryColors.radiantGold,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isProcessing ? null : () => _handleConfirmPayment(context),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'تأكيد الدفع الذري وطباعة الفاتورة',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSegment({
    required PaymentType type,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedPaymentType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentType = type;
            final total = ref.read(posControllerProvider).totalAmount;
            if (type == PaymentType.cash) {
              _paidAmountController.text = total.toStringAsFixed(2);
            } else if (type == PaymentType.creditDebt) {
              _paidAmountController.text = '0.00';
            } else {
              _paidAmountController.text = (total / 2).toStringAsFixed(2);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.2) : LuxuryColors.obsidianSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : Colors.white10,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeColor : LuxuryColors.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : LuxuryColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
