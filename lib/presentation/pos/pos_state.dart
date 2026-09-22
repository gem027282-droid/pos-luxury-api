import '../../domain/models/models.dart';

class PosState {
  final List<CartItem> cartItems;
  final TreasuryModel? selectedTreasury;
  final CustomerModel? selectedCustomer;
  final double discount;
  final bool isCameraActive;
  final String searchQuery;
  final bool isLoading;
  final String? lastErrorMessage;
  final SaleModel? lastCompletedSale;

  const PosState({
    this.cartItems = const [],
    this.selectedTreasury,
    this.selectedCustomer,
    this.discount = 0.0,
    this.isCameraActive = true,
    this.searchQuery = '',
    this.isLoading = false,
    this.lastErrorMessage,
    this.lastCompletedSale,
  });

  double get subtotal {
    double sum = 0.0;
    for (final item in cartItems) {
      sum += item.totalPrice;
    }
    return sum;
  }

  double get totalAmount {
    final net = subtotal - discount;
    return net > 0 ? net : 0.0;
  }

  double get totalItemsCount {
    double count = 0;
    for (final item in cartItems) {
      count += item.quantity;
    }
    return count;
  }

  bool get isEmpty => cartItems.isEmpty;

  PosState copyWith({
    List<CartItem>? cartItems,
    TreasuryModel? selectedTreasury,
    CustomerModel? selectedCustomer,
    bool clearCustomer = false,
    double? discount,
    bool? isCameraActive,
    String? searchQuery,
    bool? isLoading,
    String? lastErrorMessage,
    bool clearErrorMessage = false,
    SaleModel? lastCompletedSale,
  }) {
    return PosState(
      cartItems: cartItems ?? this.cartItems,
      selectedTreasury: selectedTreasury ?? this.selectedTreasury,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      discount: discount ?? this.discount,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      lastErrorMessage: clearErrorMessage ? null : (lastErrorMessage ?? this.lastErrorMessage),
      lastCompletedSale: lastCompletedSale ?? this.lastCompletedSale,
    );
  }
}
