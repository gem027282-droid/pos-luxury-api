enum PaymentType {
  cash,
  creditDebt,
  split;

  String get displayNameArabic {
    switch (this) {
      case PaymentType.cash:
        return 'نقداً (كاش)';
      case PaymentType.creditDebt:
        return 'آجل (ذمم)';
      case PaymentType.split:
        return 'دفع مجزأ';
    }
  }

  String get dbValue {
    switch (this) {
      case PaymentType.cash:
        return 'CASH';
      case PaymentType.creditDebt:
        return 'CREDIT_DEBT';
      case PaymentType.split:
        return 'SPLIT';
    }
  }

  static PaymentType fromDb(String val) {
    switch (val) {
      case 'CREDIT_DEBT':
        return PaymentType.creditDebt;
      case 'SPLIT':
        return PaymentType.split;
      default:
        return PaymentType.cash;
    }
  }
}

class ProductModel {
  final int id;
  final String name;
  final String barcode;
  final String packaging;
  final double stockQuantity;
  final double costPrice;
  final double salePrice;
  final bool isActive;
  final bool isSynced;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    this.packaging = 'قطعة',
    required this.stockQuantity,
    required this.costPrice,
    required this.salePrice,
    this.isActive = true,
    this.isSynced = false,
    required this.updatedAt,
  });

  ProductModel copyWith({
    int? id,
    String? name,
    String? barcode,
    String? packaging,
    double? stockQuantity,
    double? costPrice,
    double? salePrice,
    bool? isActive,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      packaging: packaging ?? this.packaging,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CartItem {
  final ProductModel product;
  final double quantity;
  final double unitPrice;

  const CartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  bool get canIncrement => quantity < product.stockQuantity;

  CartItem copyWith({
    ProductModel? product,
    double? quantity,
    double? unitPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class TreasuryModel {
  final int id;
  final String name;
  final double balance;
  final bool isDefault;
  final bool isSynced;
  final DateTime updatedAt;

  const TreasuryModel({
    required this.id,
    required this.name,
    required this.balance,
    this.isDefault = false,
    this.isSynced = false,
    required this.updatedAt,
  });
}

class CustomerModel {
  final int id;
  final String name;
  final String phone;
  final double totalDebt;
  final String? notes;
  final bool isSynced;
  final DateTime updatedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.totalDebt = 0.0,
    this.notes,
    this.isSynced = false,
    required this.updatedAt,
  });
}

class SupplierModel {
  final int id;
  final String name;
  final String phone;
  final double totalCredit;
  final String? notes;
  final bool isSynced;
  final DateTime updatedAt;

  const SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    this.totalCredit = 0.0,
    this.notes,
    this.isSynced = false,
    required this.updatedAt,
  });
}

class SaleModel {
  final int id;
  final String invoiceNumber;
  final double totalAmount;
  final double discount;
  final double paidAmount;
  final double remainingDebt;
  final PaymentType paymentType;
  final int? customerId;
  final int treasuryId;
  final List<CartItem> items;
  final bool isSynced;
  final DateTime createdAt;

  const SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    this.discount = 0.0,
    required this.paidAmount,
    required this.remainingDebt,
    required this.paymentType,
    this.customerId,
    required this.treasuryId,
    this.items = const [],
    this.isSynced = false,
    required this.createdAt,
  });
}

class ExpenseModel {
  final int id;
  final String title;
  final double amount;
  final String category;
  final int treasuryId;
  final bool isSynced;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.treasuryId,
    this.isSynced = false,
    required this.createdAt,
  });
}
