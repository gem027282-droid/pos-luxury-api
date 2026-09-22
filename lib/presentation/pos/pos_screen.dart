import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/luxury_colors.dart';
import '../../data/hardware/barcode_handler.dart';
import '../../domain/models/models.dart';
import '../common/animated_counter.dart';
import '../common/glass_container.dart';
import 'pos_controller.dart';
import 'pos_state.dart';
import 'widgets/checkout_bottom_sheet.dart';

/// 2027 Luxury POS Screen (iOS & Android)
/// Features:
/// - Top: Treasury Selector & Live Search
/// - Middle: Live Camera Viewfinder with Animated Laser Beam
/// - List: Cart Items with Luxurious Gold '+' Button & Stock Protection
/// - Bottom: Floating Glass Checkout Bar with Radiant Gold Total
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;
  BarcodeScannerHandler? _barcodeHandler;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualBarcodeInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 1. Initialize Laser Beam Animation (1500ms cycle)
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // 2. Initialize Barcode Scanner Handler with Debounce Latch
    _barcodeHandler = BarcodeScannerHandler(
      onBarcodeDetected: (barcode) {
        final success = ref.read(posControllerProvider.notifier).handleScannedBarcode(barcode);
        if (success) {
          _showToast('تمت إضافة المنتج للسلة بنجاح', isError: false);
        } else {
          final errorMsg = ref.read(posControllerProvider).lastErrorMessage ?? 'منتج غير معروف';
          _showToast(errorMsg, isError: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _barcodeHandler?.dispose();
    _searchController.dispose();
    _manualBarcodeInputController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? LuxuryColors.imperialCrimson : LuxuryColors.emeraldCash,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _openCheckoutModal() {
    final posState = ref.read(posControllerProvider);
    if (posState.cartItems.isEmpty) {
      _showToast('السلة فارغة، أضف منتجات أولاً', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CheckoutBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posControllerProvider);
    final currencyFormat = intl.NumberFormat('#,##0.00', 'ar_SA');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: LuxuryColors.obsidianBackground,
        body: Stack(
          children: [
            // Background Ambient Radial Glow
            Positioned(
              top: -80,
              right: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LuxuryColors.radiantGold.withOpacity(0.06),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // 1. TOP BAR: Treasury Selector & Live Product Search
                  _buildTopBar(posState),

                  // 2. MIDDLE: Live Camera Viewfinder with Laser Scanner
                  if (posState.isCameraActive) _buildLiveViewfinder(posState),

                  // 3. CART LIST / ITEMS VIEW
                  Expanded(
                    child: _buildCartOrProductsArea(posState, currencyFormat),
                  ),

                  // 4. BOTTOM: Floating Glass Checkout Bar
                  _buildFloatingCheckoutBar(posState, currencyFormat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Top Bar: Treasury Selector & Live Search
  // ===========================================================================

  Widget _buildTopBar(PosState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Treasury Dropdown Selector
          Expanded(
            flex: 5,
            child: Consumer(
              builder: (context, ref, _) {
                final treasuriesAsync = ref.watch(treasuriesListStreamProvider);
                return treasuriesAsync.when(
                  data: (treasuries) {
                    final selectedT = state.selectedTreasury ??
                        (treasuries.isNotEmpty ? treasuries.first : null);

                    return GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      borderRadius: 12,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TreasuryModel>(
                          value: selectedT,
                          isExpanded: true,
                          dropdownColor: LuxuryColors.obsidianCard,
                          icon: const Icon(Icons.account_balance, color: LuxuryColors.radiantGold, size: 18),
                          items: treasuries.map((t) {
                            return DropdownMenuItem<TreasuryModel>(
                              value: t,
                              child: Text(
                                '${t.name} (${t.balance.toStringAsFixed(0)} ر.س)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newT) {
                            if (newT != null) {
                              ref.read(posControllerProvider.notifier).setTreasury(newT);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => const SizedBox(),
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // Camera Viewfinder Toggle Button
          GlassContainer(
            borderRadius: 12,
            padding: const EdgeInsets.all(8),
            onTap: () {
              ref.read(posControllerProvider.notifier).toggleCamera(!state.isCameraActive);
            },
            child: Icon(
              state.isCameraActive ? Icons.videocam : Icons.videocam_off_outlined,
              color: state.isCameraActive ? LuxuryColors.radiantGold : LuxuryColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),

          // Quick Barcode Manual Entry Trigger
          GlassContainer(
            borderRadius: 12,
            padding: const EdgeInsets.all(8),
            onTap: _showManualBarcodeDialog,
            child: const Icon(Icons.keyboard, color: LuxuryColors.radiantGold, size: 20),
          ),
        ],
      ),
    );
  }

  void _showManualBarcodeDialog() {
    _manualBarcodeInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: LuxuryColors.obsidianCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('إدخال الباركود يدوياً', style: TextStyle(color: LuxuryColors.radiantGold)),
            content: TextField(
              controller: _manualBarcodeInputController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'مثال: 628100001111',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: LuxuryColors.obsidianSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (val) {
                Navigator.pop(ctx);
                if (val.trim().isNotEmpty) {
                  _barcodeHandler?.onBarcodeDetected(val.trim());
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LuxuryColors.radiantGold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final val = _manualBarcodeInputController.text.trim();
                  Navigator.pop(ctx);
                  if (val.isNotEmpty) {
                    _barcodeHandler?.onBarcodeDetected(val);
                  }
                },
                child: const Text('إضافة للسلة'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Live Camera Viewfinder with Animated Laser Line
  // ===========================================================================

  Widget _buildLiveViewfinder(PosState state) {
    return Container(
      height: 155,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LuxuryColors.radiantGold.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: LuxuryColors.radiantGold.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live Mobile Scanner Feed
            if (_barcodeHandler != null)
              MobileScanner(
                controller: _barcodeHandler!.scannerController,
                onDetect: _barcodeHandler!.handleBarcodeCapture,
                errorBuilder: (context, error, child) {
                  return Container(
                    color: LuxuryColors.obsidianCard,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: LuxuryColors.textSecondary, size: 36),
                          const SizedBox(height: 6),
                          const Text(
                            'المسح اليدوي نشط (الكاميرا غير متصلة بالمحاكي)',
                            style: TextStyle(fontSize: 11, color: LuxuryColors.textSecondary),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.qr_code, size: 16, color: LuxuryColors.radiantGold),
                            label: const Text('إدخال باركود تجريبي', style: TextStyle(color: LuxuryColors.radiantGold, fontSize: 11)),
                            onPressed: _showManualBarcodeDialog,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Scanning Crosshair Overlay
            Center(
              child: Container(
                width: 220,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Animated Scanning Laser Line
            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 155 * _laserAnimation.value,
                  left: 30,
                  right: 30,
                  child: Container(
                    height: 2.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          LuxuryColors.imperialCrimson.withOpacity(0.1),
                          LuxuryColors.imperialCrimson,
                          LuxuryColors.radiantGold,
                          LuxuryColors.imperialCrimson,
                          LuxuryColors.imperialCrimson.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: LuxuryColors.imperialCrimson.withOpacity(0.8),
                          blurRadius: 10,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Indicator Badge for scanner lock status
            Positioned(
              bottom: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _barcodeHandler?.isLocked ?? false
                            ? LuxuryColors.imperialCrimson
                            : LuxuryColors.emeraldCash,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _barcodeHandler?.isLocked ?? false ? 'جارٍ التحقق...' : 'الماسح جاهز',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
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

  // ===========================================================================
  // Cart Items List
  // ===========================================================================

  Widget _buildCartOrProductsArea(PosState state, intl.NumberFormat currencyFormat) {
    if (state.cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LuxuryColors.acrylicGlass.withOpacity(0.4),
                border: Border.all(color: LuxuryColors.radiantGold.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: LuxuryColors.radiantGold,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'سلة المبيعات فارغة الآن',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: LuxuryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'قم بمسح الباركود عبر الكاميرا أو اضغط أدناه لإضافة منتج',
              style: TextStyle(fontSize: 12, color: LuxuryColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: LuxuryColors.radiantGold.withOpacity(0.15),
                foregroundColor: LuxuryColors.radiantGold,
                side: const BorderSide(color: LuxuryColors.radiantGold, width: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('تصفح المنتجات المتوفرة بالمخزن'),
              onPressed: () => _showProductsCatalogModal(context),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 6, bottom: 90),
      itemCount: state.cartItems.length,
      itemBuilder: (context, index) {
        final item = state.cartItems[index];
        return _buildCartItemCard(item, currencyFormat);
      },
    );
  }

  Widget _buildCartItemCard(CartItem item, intl.NumberFormat currencyFormat) {
    final canAddMore = item.canIncrement;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Leading Icon & Product Packaging
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: LuxuryColors.radiantGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LuxuryColors.radiantGold.withOpacity(0.25)),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: LuxuryColors.radiantGold, size: 22),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: LuxuryColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${currencyFormat.format(item.unitPrice)} ر.س',
                        style: const TextStyle(fontSize: 12, color: LuxuryColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'المخزون: ${item.product.stockQuantity.toInt()}',
                          style: const TextStyle(fontSize: 10, color: LuxuryColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quantity Control Buttons with Smooth Rolling Numbers
            Row(
              children: [
                // Decrement Button
                _buildQuantityActionButton(
                  icon: Icons.remove,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(posControllerProvider.notifier).decrementItem(item);
                  },
                ),
                const SizedBox(width: 6),

                // Rolling Animated Quantity Display
                Container(
                  constraints: const BoxDirectionConstraints(minWidth: 28),
                  alignment: Alignment.center,
                  child: AnimatedCounter(
                    text: item.quantity.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: LuxuryColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Luxurious Gold Increment Button (Blocked if qty >= stock)
                _buildQuantityActionButton(
                  icon: Icons.add,
                  isGoldAccent: canAddMore,
                  isDisabled: !canAddMore,
                  onTap: () {
                    if (canAddMore) {
                      HapticFeedback.lightImpact();
                      ref.read(posControllerProvider.notifier).incrementItem(item);
                    } else {
                      HapticFeedback.mediumImpact();
                      _showToast(
                        'لا يمكن إضافة المزيد: تم الوصول للحد الأقصى في المخزون (${item.product.stockQuantity.toInt()})',
                        isError: true,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isGoldAccent = false,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.white10
              : (isGoldAccent ? LuxuryColors.radiantGold : Colors.white12),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isGoldAccent && !isDisabled
              ? [
                  BoxShadow(
                    color: LuxuryColors.radiantGold.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled
              ? Colors.white30
              : (isGoldAccent ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  // ===========================================================================
  // Floating Glass Checkout Bar (Total in Radiant Gold #E5B869)
  // ===========================================================================

  Widget _buildFloatingCheckoutBar(PosState state, intl.NumberFormat currencyFormat) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(14),
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          customBorderGradient: LuxuryColors.specularBorder,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total Amount in Radiant Gold
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'الإجمالي الصافي',
                        style: TextStyle(fontSize: 11, color: LuxuryColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${state.totalItemsCount.toInt()} قطعة)',
                        style: const TextStyle(fontSize: 10, color: LuxuryColors.radiantGold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AnimatedCounter(
                    text: currencyFormat.format(state.totalAmount),
                    suffix: 'ر.س',
                    style: const TextStyle(
                      color: LuxuryColors.radiantGold,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              // Checkout Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LuxuryColors.radiantGold,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.payment, color: Colors.black, size: 20),
                label: const Text(
                  'متابعة الدفع',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: state.cartItems.isEmpty ? null : _openCheckoutModal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Product Catalog Modal (For Manual Browsing)
  // ===========================================================================

  void _showProductsCatalogModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: LuxuryColors.obsidianBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'قائمة المنتجات المتوفرة بالمخزن',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: LuxuryColors.radiantGold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final productsAsync = ref.watch(productsListStreamProvider);
                      return productsAsync.when(
                        data: (products) {
                          return ListView.separated(
                            itemCount: products.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final p = products[index];
                              return GlassContainer(
                                borderRadius: 14,
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'باركود: ${p.barcode} | متاح: ${p.stockQuantity.toInt()}',
                                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${p.salePrice.toStringAsFixed(2)} ر.س',
                                      style: const TextStyle(
                                        color: LuxuryColors.radiantGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: LuxuryColors.radiantGold),
                                      onPressed: () {
                                        final added = ref
                                            .read(posControllerProvider.notifier)
                                            .addProduct(p);
                                        if (added) {
                                          _showToast('تمت إضافة ${p.name} للسلة');
                                        } else {
                                          _showToast(
                                            ref.read(posControllerProvider).lastErrorMessage ?? '',
                                            isError: true,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('خطأ: $err')),
                      );
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
}
