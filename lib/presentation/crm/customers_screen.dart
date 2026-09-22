import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/theme/luxury_colors.dart';
import '../common/glass_container.dart';
import '../pos/pos_controller.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = intl.NumberFormat('#,##0.00', 'ar_SA');
    final customersAsync = ref.watch(customersListStreamProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: LuxuryColors.obsidianBackground,
        appBar: AppBar(
          title: const Text('إدارة العملاء والديون المستحقة (CRM)'),
        ),
        body: customersAsync.when(
          data: (customers) {
            final totalDebts = customers.fold<double>(0.0, (acc, c) => acc + c.totalDebt);

            return Column(
              children: [
                // Top Financial Overview
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إجمالي الديون في ذمة العملاء:', style: TextStyle(color: LuxuryColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${currencyFormat.format(totalDebts)} ر.س',
                              style: const TextStyle(
                                color: LuxuryColors.imperialCrimson,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LuxuryColors.imperialCrimson.withOpacity(0.15),
                            border: Border.all(color: LuxuryColors.imperialCrimson.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.people_alt_outlined, color: LuxuryColors.imperialCrimson),
                        ),
                      ],
                    ),
                  ),
                ),

                // Customer List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final hasDebt = customer.totalDebt > 0;

                      return GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasDebt
                                    ? LuxuryColors.imperialCrimson.withOpacity(0.15)
                                    : LuxuryColors.emeraldCash.withOpacity(0.15),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: hasDebt ? LuxuryColors.imperialCrimson : LuxuryColors.emeraldCash,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'الجوال: ${customer.phone}',
                                    style: const TextStyle(fontSize: 11, color: LuxuryColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('الرصيد المدين:', style: TextStyle(fontSize: 10, color: Colors.white54)),
                                const SizedBox(height: 2),
                                Text(
                                  '${currencyFormat.format(customer.totalDebt)} ر.س',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: hasDebt ? LuxuryColors.imperialCrimson : LuxuryColors.emeraldCash,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('حدث خطأ: $err')),
        ),
      ),
    );
  }
}
