import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/inventory_item.dart';
import '../providers/inventory_provider.dart';

class AddProductScreen extends ConsumerWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantalla simplificada - extensible para agregar recetas de insumos
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar al menú')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('☕', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text(
                'Gestión de menú disponible próximamente en esta versión',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Los productos de ejemplo ya están cargados en el POS.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
