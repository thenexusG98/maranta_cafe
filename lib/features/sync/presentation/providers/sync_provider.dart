import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/google_sheets_service.dart';

final googleSheetsServiceProvider = Provider<GoogleSheetsService>(
  (ref) => GoogleSheetsService(),
);

// ── Estado de sincronización ─────────────────────────────────────────────────

enum SyncStatus { idle, loading, success, error }

class SyncState {
  final SyncStatus status;
  final String message;
  final DateTime? lastSync;
  final int lastOrdersCount;
  final double lastTotalAmount;

  const SyncState({
    this.status         = SyncStatus.idle,
    this.message        = '',
    this.lastSync,
    this.lastOrdersCount = 0,
    this.lastTotalAmount = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSync,
    int? lastOrdersCount,
    double? lastTotalAmount,
  }) => SyncState(
    status:           status           ?? this.status,
    message:          message          ?? this.message,
    lastSync:         lastSync         ?? this.lastSync,
    lastOrdersCount:  lastOrdersCount  ?? this.lastOrdersCount,
    lastTotalAmount:  lastTotalAmount  ?? this.lastTotalAmount,
  );
}

class SyncNotifier extends StateNotifier<SyncState> {
  final GoogleSheetsService _service;

  SyncNotifier(this._service) : super(const SyncState()) {
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('last_sync_ts');
    if (ts != null) {
      state = state.copyWith(lastSync: DateTime.tryParse(ts));
    }
  }

  Future<void> syncToday() async {
    state = state.copyWith(status: SyncStatus.loading, message: 'Sincronizando...');

    final result = await _service.syncToday();

    final prefs = await SharedPreferences.getInstance();
    if (result.success) {
      await prefs.setString('last_sync_ts', result.timestamp.toIso8601String());
    }

    state = state.copyWith(
      status:          result.success ? SyncStatus.success : SyncStatus.error,
      message:         result.message,
      lastSync:        result.success ? result.timestamp : state.lastSync,
      lastOrdersCount: result.ordersCount,
      lastTotalAmount: result.totalAmount,
    );
  }

  void resetStatus() {
    state = state.copyWith(status: SyncStatus.idle, message: '');
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final service = ref.read(googleSheetsServiceProvider);
  return SyncNotifier(service);
});
