import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_stats.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(),
);

// ── Modo de vista (hoy / semana) ────────────────────────────────────────────

enum DashboardMode { today, weekly }

final dashboardModeProvider = StateProvider<DashboardMode>(
  (ref) => DashboardMode.today,
);

// ── Stats del día ────────────────────────────────────────────────────────────

final dailyStatsProvider = FutureProvider.autoDispose<DailyStats>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  final mode = ref.watch(dashboardModeProvider);

  if (mode == DashboardMode.weekly) {
    return repo.getWeeklyStats();
  }
  return repo.getDailyStats(DateTime.now());
});
