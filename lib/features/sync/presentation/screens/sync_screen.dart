import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/sync_provider.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);

    // Mostrar snackbar según resultado
    ref.listen(syncProvider, (prev, next) {
      if (prev?.status == SyncStatus.loading) {
        if (next.status == SyncStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (next.status == SyncStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('☁️ Sincronización')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ilustrativo ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.coffeeBrown,
                    AppColors.coffeeDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.syncTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Exporta los datos del día a tu hoja de cálculo.\nSolo se envía al presionar el botón.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Última sincronización ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEE0D0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.caramel.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history, color: AppColors.caramel),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.lastSync,
                          style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          sync.lastSync != null
                            ? _formatDateTime(sync.lastSync!)
                            : AppStrings.neverSynced,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Datos que se enviarán ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEE0D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Qué se sincroniza?',
                    style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...[
                    ('📋', 'Todos los pedidos del día'),
                    ('💰', 'Ventas totales y por método de pago'),
                    ('📦', 'Estado actual del inventario'),
                    ('🕐', 'Fecha y hora del envío'),
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(item.$1, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(item.$2,
                          style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  )),

                  const Divider(height: 20),

                  Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined,
                        color: AppColors.caramel, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppStrings.syncWarning,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.caramel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Indicador de progreso / resultado ─────────────────────
            if (sync.status != SyncStatus.idle) ...[
              _StatusIndicator(status: sync.status, message: sync.message),
              const SizedBox(height: 16),
            ],

            // ── BOTÓN PRINCIPAL ───────────────────────────────────────
            ElevatedButton.icon(
              onPressed: sync.status == SyncStatus.loading
                ? null
                : () => ref.read(syncProvider.notifier).syncToday(),
              icon: sync.status == SyncStatus.loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                sync.status == SyncStatus.loading
                  ? 'Sincronizando...'
                  : AppStrings.syncBtn,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0F9D58), // Google green
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Instrucciones de configuración ────────────────────────
            _SetupInstructions(),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} '
           '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}

// ── Indicador de estado ───────────────────────────────────────────────────────

class _StatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final String message;

  const _StatusIndicator({required this.status, required this.message});

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.loading) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.caramel, strokeWidth: 2),
          SizedBox(width: 12),
          Text('Enviando datos...'),
        ],
      );
    }

    final isSuccess = status == SyncStatus.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isSuccess ? AppColors.success : AppColors.error).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isSuccess ? AppColors.success : AppColors.error).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: isSuccess ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isSuccess ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Instrucciones de configuración ───────────────────────────────────────────

class _SetupInstructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.help_outline, color: AppColors.caramel),
      title: const Text('¿Cómo configurar Google Sheets?',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEEE0D0)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              ...[
                '1. Ve a script.google.com y crea un nuevo proyecto.',
                '2. Copia el código doPost() del archivo apps_script.gs incluido en el proyecto.',
                '3. Pega el código en el editor y guarda.',
                '4. Clic en "Implementar" → "Nueva implementación".',
                '5. Tipo: "Aplicación web". Acceso: "Cualquier persona".',
                '6. Copia la URL generada.',
                '7. Pégala en lib/features/sync/data/services/google_sheets_service.dart reemplazando la URL de ejemplo.',
              ].map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(step,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  )),
              )),
            ],
          ),
        ),
      ],
    );
  }
}
