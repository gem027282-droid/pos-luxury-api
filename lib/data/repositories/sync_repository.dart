import '../local/app_database.dart';
import '../network/dio_client.dart';

enum SyncStatus { idle, syncing, success, failed }

class SyncRepository {
  final AppDatabase db;
  final DioClient client;

  SyncRepository({required this.db, required this.client});

  Future<bool> synchronizeAll() async {
    try {
      // 1. Sync pending local sales to remote TiDB
      final unsyncedSales = db.getAllSales().where((s) => !s.isSynced).toList();
      if (unsyncedSales.isNotEmpty) {
        // Post payload to REST Gateway
        // client.dio.post(ApiEndpoints.syncSales, data: unsyncedSales.map(...).toList());
      }

      // 2. Fetch latest Products updates from TiDB Cloud
      // final response = await client.dio.get(ApiEndpoints.syncProducts);

      return true;
    } catch (_) {
      return false;
    }
  }
}
