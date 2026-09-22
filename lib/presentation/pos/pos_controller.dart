import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_database.dart';
import '../../domain/models/models.dart';
import 'pos_state.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final productsListStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllProducts();
});

final treasuriesListStreamProvider = StreamProvider<List<TreasuryModel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllTreasuries();
});

final customersListStreamProvider = StreamProvider<List<CustomerModel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllCustomers();
});

final posControllerProvider = StateNotifierProvider<PosController, PosState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PosController(db);
});

class PosController extends StateNotifier<PosState> {
  final AppDatabase _db;

  PosController(this._db) : super(const PosState()) {
    _initDefaultTreasury();
  }

  void _initDefaultTreasury() {
    final treasuries = _db.getAllTreasuries();
    if (treasuries.isNotEmpty) {
      final defaultT = treasuries.firstWhere((t) => t.isDefault, orElse: () => treasuries.first);
      state = state.copyWith(selectedTreasury: defaultT);
    }
  }

  void setTreasury(TreasuryModel treasury) {
    state = state.copyWith(selectedTreasury: treasury);
  }

  void setCustomer(CustomerModel? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(selectedCustomer: customer);
    }
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount.clamp(0.0, state.subtotal));
  }

  void toggleCamera(bool active) {
    state = state.copyWith(isCameraActive: active);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearErrorMessage() {
    state = state.copyWith(clearErrorMessage: true);
  }

  /// Adds a product to cart or increments if already present with stock validation
  bool addProduct(ProductModel product) {
    if (product.stockQuantity <= 0) {
      state = state.copyWith(
        lastErrorMessage: 'عفواً، نفد المخزون للمنتج: ${product.name}',
      );
      return false;
    }

    final currentItems = List<CartItem>.from(state.cartItems);
    final existingIndex = currentItems.indexWhere((i) => i.product.id == product.id);

    if (existingIndex != -1) {
      final currentItem = currentItems[existingIndex];
      // Check stock limit: block increment if qty >= stock_quantity
      if (currentItem.quantity >= product.stockQuantity) {
        state = state.copyWith(
          lastErrorMessage: 'تم الوصول للحد الأقصى للكمية المتاحة بالمخزون (${product.stockQuantity})',
        );
        return false;
      }
      currentItems[existingIndex] = currentItem.copyWith(
        quantity: currentItem.quantity + 1,
      );
    } else {
      currentItems.add(CartItem(
        product: product,
        quantity: 1,
        unitPrice: product.salePrice,
      ));
    }

    state = state.copyWith(
      cartItems: currentItems,
      clearErrorMessage: true,
    );
    return true;
  }

  /// Barcode Scanner Detection Entrypoint
  bool handleScannedBarcode(String barcode) {
    final product = _db.findProductByBarcode(barcode);
    if (product == null) {
      state = state.copyWith(
        lastErrorMessage: 'لم يتم العثور على منتج بالباركود: $barcode',
      );
      return false;
    }
    return addProduct(product);
  }

  /// Luxurious '+' button to increment item quantity in Cart
  bool incrementItem(CartItem item) {
    final currentItems = List<CartItem>.from(state.cartItems);
    final index = currentItems.indexWhere((i) => i.product.id == item.product.id);
    if (index == -1) return false;

    // Block increment if qty >= stock_quantity
    if (item.quantity >= item.product.stockQuantity) {
      state = state.copyWith(
        lastErrorMessage: 'الكمية المطلوبة تتجاوز المخزون المتوفر (${item.product.stockQuantity})',
      );
      return false;
    }

    currentItems[index] = item.copyWith(quantity: item.quantity + 1);
    state = state.copyWith(cartItems: currentItems, clearErrorMessage: true);
    return true;
  }

  void decrementItem(CartItem item) {
    final currentItems = List<CartItem>.from(state.cartItems);
    final index = currentItems.indexWhere((i) => i.product.id == item.product.id);
    if (index == -1) return;

    if (item.quantity > 1) {
      currentItems[index] = item.copyWith(quantity: item.quantity - 1);
    } else {
      currentItems.removeAt(index);
    }

    state = state.copyWith(cartItems: currentItems, clearErrorMessage: true);
  }

  void removeItem(CartItem item) {
    final currentItems = List<CartItem>.from(state.cartItems)
      ..removeWhere((i) => i.product.id == item.product.id);
    state = state.copyWith(cartItems: currentItems);
  }

  void clearCart() {
    state = state.copyWith(
      cartItems: const [],
      discount: 0.0,
      clearCustomer: true,
      clearErrorMessage: true,
    );
  }

  /// Executes atomic checkout via Drift ACID transaction
  Future<SaleModel?> checkout({
    required PaymentType paymentType,
    required double paidAmount,
    required double remainingDebt,
  }) async {
    if (state.cartItems.isEmpty) {
      state = state.copyWith(lastErrorMessage: 'السلة فارغة، أضف منتجات لإتمام البيع');
      return null;
    }

    final treasury = state.selectedTreasury ?? _db.getDefaultTreasury();

    if ((paymentType == PaymentType.creditDebt || paymentType == PaymentType.split) &&
        state.selectedCustomer == null) {
      state = state.copyWith(lastErrorMessage: 'يجب اختيار عميل لتسجيل البيع الآجل أو المجزأ');
      return null;
    }

    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final completedSale = await _db.executeSaleTransaction(
        items: state.cartItems,
        totalAmount: state.totalAmount,
        discount: state.discount,
        paidAmount: paidAmount,
        remainingDebt: remainingDebt,
        paymentType: paymentType,
        customerId: state.selectedCustomer?.id,
        treasuryId: treasury.id,
      );

      // Clear cart on successful transaction and preserve completed sale for receipt preview
      state = state.copyWith(
        cartItems: const [],
        discount: 0.0,
        isLoading: false,
        lastCompletedSale: completedSale,
      );

      return completedSale;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastErrorMessage: 'فشلت المعاملة: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }
}
