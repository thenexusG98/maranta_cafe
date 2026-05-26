import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/daily_stats.dart';

/// Podio visual de los 3 productos más vendidos
class TopProductsPodium extends StatelessWidget {
  final List<TopProduct> products;

  const TopProductsPodium({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    // Garantizamos máximo 3 posiciones
    final top = List.generate(3, (i) => i < products.length ? products[i] : null);

    // Orden del podio: 2º, 1º, 3º
    final podiumOrder = [
      _PodiumSlot(position: 2, product: top[1], height: 100),
      _PodiumSlot(position: 1, product: top[0], height: 130),
      _PodiumSlot(position: 3, product: top[2], height: 80),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.creamDark,
            AppColors.caramelLight.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Área del podio
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: podiumOrder.map((slot) => Expanded(
                child: _PodiumColumn(slot: slot),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot {
  final int position;
  final TopProduct? product;
  final double height;

  const _PodiumSlot({
    required this.position,
    required this.product,
    required this.height,
  });
}

class _PodiumColumn extends StatelessWidget {
  final _PodiumSlot slot;

  const _PodiumColumn({required this.slot});

  Color get _medalColor {
    switch (slot.position) {
      case 1: return AppColors.gold;
      case 2: return AppColors.silver;
      case 3: return AppColors.bronze;
      default: return AppColors.textHint;
    }
  }

  Color get _barColor {
    switch (slot.position) {
      case 1: return AppColors.gold.withOpacity(0.85);
      case 2: return AppColors.silver.withOpacity(0.85);
      case 3: return AppColors.bronze.withOpacity(0.85);
      default: return AppColors.creamDark;
    }
  }

  String get _medal {
    switch (slot.position) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = slot.product;

    if (product == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(_medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Container(
            height: slot.height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.creamDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: const Color(0xFFDDD0C0)),
            ),
            alignment: Alignment.center,
            child: const Text('—', style: TextStyle(color: AppColors.textHint)),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Emoji
        Text(product.imageEmoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        // Nombre truncado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            product.productName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${product.quantitySold} uds',
          style: TextStyle(
            fontSize: 11,
            color: _medalColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        // Barra del podio
        Container(
          height: slot.height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: _medalColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            _medal,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ],
    );
  }
}
