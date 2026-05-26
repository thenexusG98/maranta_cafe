import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Banner de alerta cuando hay insumos con stock bajo
class LowStockBanner extends StatelessWidget {
  final int count;

  const LowStockBanner({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count insumo${count != 1 ? 's' : ''} con stock bajo o agotado',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
