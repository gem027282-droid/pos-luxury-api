class ApiEndpoints {
  // TiDB Cloud Serverless / Backend REST Gateway
  static const String baseUrl = 'https://gateway.tidbcloud.com/v1beta1';

  static const String syncProducts = '/products/sync';
  static const String syncTreasuries = '/treasuries/sync';
  static const String syncCustomers = '/customers/sync';
  static const String syncSuppliers = '/suppliers/sync';
  static const String syncSales = '/sales/sync';
  static const String syncExpenses = '/expenses/sync';
}
