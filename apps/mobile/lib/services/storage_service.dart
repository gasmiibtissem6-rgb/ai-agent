import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class StorageService {
  const StorageService();

  SupabaseStorageClient? get storage => SupabaseService.client?.storage;
}
