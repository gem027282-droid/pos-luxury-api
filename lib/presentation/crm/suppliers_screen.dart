import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/theme/luxury_colors.dart';
import '../common/glass_container.dart';
import '../pos/pos_controller.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = intl.NumberFormat('#,##0.00', 'ar_SA');
    final db = ref.watch(appDatabaseProvider);
    final suppliers = db.getAllSuppliers();
    final totalCredits = suppliers.fold<double>(0.0, (acc, s) => acc + s.totalCredit);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: LuxuryColors.obsidianBackground,
        appBar: AppBar(
          title: const Text('إدارة الموردين والمستحقات الدائنة (SRM)'),
        ),
        body: Column(
          children: [
            // Top Credit Overview
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
                        const Text('إجمالي مستحقات الموردين علينا:', style: TextStyle(color: LuxuryColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${currencyFormat.format(totalCredits)} ر.س',
                          style: const TextStyle(
                            color: LuxuryColors.radiantGold,
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
                        color: LuxuryColors.radiantGold.withOpacity(0.15),
                        border: Border.all(color: LuxuryColors.radiantGold.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: LuxuryColors.radiantGold),
                    ),
                  ],
                ),
              ),
            ),

            // Suppliers List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: suppliers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];

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
                            color: LuxuryColors.radiantGold.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: LuxuryColors.radiantGold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'هاتف: ${supplier.phone}',
                                style: const TextStyle(fontSize: 11, color: LuxuryColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('المستحق للمورد:', style: TextStyle(fontSize: 10, color: Colors.white54)),
                            const SizedBox(height: 2),
                            Text(
                              '${currencyFormat.format(supplier.totalCredit)} ر.س',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: LuxuryColors.radiantGold,
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
        ),
      ),
    );
  }
}
