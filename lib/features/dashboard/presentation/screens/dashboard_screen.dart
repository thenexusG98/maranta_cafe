import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/daily_stats.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/top_products_podium.dart';
import '../widgets/hourly_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dailyStatsProvider);
    final mode       = ref.watch(dashboardModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Estadísticas'),
        actions: [
          // Toggle Hoy / Semana
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ToggleButtons(
                isSelected: [
                  mode == DashboardMode.today,
                  mode == DashboardMode.weekly,
                ],
                onPressed: (i) {
                  ref.read(dashboardModeProvider.notifier).state =
                    i == 0 ? DashboardMode.today : DashboardMode.weekly;
                },
                borderRadius: BorderRadius.circular(20),
                color: Colors.white70,
                selectedColor: Colors.white,
                fillColor: Colors.white.withOpacity(0.2),
                constraints: const BoxConstraints(minHeight: 34, minWidth: 64),
                children: const [
                  Text('Hoy',    style: TextStyle(fontSize: 13)),
                  Text('Semana', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),

      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.caramel)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('No hay datos disponibles',
                style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Registra tu primera venta para ver estadísticas',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dailyStatsProvider),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          color: AppColors.caramel,
          onRefresh: () async => ref.invalidate(dailyStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── KPI Cards ────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: StatsCard(
                    icon: Icons.attach_money,
                    iconColor: AppColors.success,
                    label: AppStrings.dailySales,
                    value: '\$${stats.totalSales.toStringAsFixed(2)}',
                    subtitle: mode == DashboardMode.today ? 'Hoy' : 'Esta semana',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    icon: Icons.receipt_long,
                    iconColor: AppColors.info,
                    label: AppStrings.totalOrders,
                    value: '${stats.totalOrders}',
                    subtitle: 'Pedidos',
                  ),
                ),
              ]),

              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: StatsCard(
                    icon: Icons.trending_up,
                    iconColor: AppColors.caramel,
                    label: AppStrings.avgTicket,
                    value: '\$${stats.avgTicket.toStringAsFixed(2)}',
                    subtitle: 'Ticket promedio',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentBreakdownCard(stats: stats),
                ),
              ]),

              const SizedBox(height: 24),

              // ── Top 3 Productos ───────────────────────────────────────
              Text('🏆 ${AppStrings.topSales}',
                style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),

              if (stats.topProducts.isEmpty)
                _EmptySection(
                  message: 'Sin ventas ${mode == DashboardMode.today ? "hoy" : "esta semana"}',
                )
              else
                TopProductsPodium(products: stats.topProducts),

              const SizedBox(height: 24),

              // ── Gráfico de horas pico ──────────────────────────────────
              if (mode == DashboardMode.today) ...[
                Text('⏰ ${AppStrings.peakHours}',
                  style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Distribución de ventas por hora',
                  style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                stats.hourlySales.every((h) => h.amount == 0)
                  ? _EmptySection(message: 'Sin ventas registradas hoy')
                  : HourlyChart(hourlySales: stats.hourlySales),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cards auxiliares ──────────────────────────────────────────────────────────

class _PaymentBreakdownCard extends StatelessWidget {
  final DailyStats stats;
  const _PaymentBreakdownCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final methods = stats.salesByPaymentMethod;

    String _label(String key) {
      switch (key) {
        case 'cash':     return '💵 Efectivo';
        case 'card':     return '💳 Tarjeta';
        case 'transfer': return '📲 Transfer.';
        default:         return key;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pagos', style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13,
              color: AppColors.textSecondary,
            )),
            const SizedBox(height: 8),
            if (methods.isEmpty)
              const Text('—', style: TextStyle(color: AppColors.textHint))
            else
              ...methods.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_label(e.key), style: const TextStyle(fontSize: 12)),
                    Text('${e.value}', style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13,
                    )),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.creamDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center),
    );
  }
}
