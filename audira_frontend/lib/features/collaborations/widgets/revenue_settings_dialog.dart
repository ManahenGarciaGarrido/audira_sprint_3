// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';
import '../../../core/models/collaborator.dart';
import '../../../core/api/services/collaboration_service.dart';

/// Dialog for setting revenue percentage for a collaborator
/// GA01-155: Definir porcentaje de ganancias
class RevenueSettingsDialog extends StatefulWidget {
  final Collaborator collaboration;

  const RevenueSettingsDialog({
    super.key,
    required this.collaboration,
  });

  @override
  State<RevenueSettingsDialog> createState() => _RevenueSettingsDialogState();
}

class _RevenueSettingsDialogState extends State<RevenueSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _percentageController = TextEditingController();
  final CollaborationService _collaborationService = CollaborationService();

  bool _isLoading = false;
  double? _currentTotalRevenue;
  bool _loadingTotalRevenue = false;

  @override
  void initState() {
    super.initState();
    _percentageController.text =
        widget.collaboration.revenuePercentage.toStringAsFixed(1);
    _loadTotalRevenue();
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalRevenue() async {
    setState(() => _loadingTotalRevenue = true);

    try {
      final response = widget.collaboration.isForSong
          ? await _collaborationService
              .getSongTotalRevenue(widget.collaboration.songId!)
          : await _collaborationService
              .getAlbumTotalRevenue(widget.collaboration.albumId!);

      if (response.success && response.data != null) {
        setState(() {
          _currentTotalRevenue = response.data;
        });
      }
    } catch (e) {
      // Silently fail - total revenue is just informational
    } finally {
      setState(() => _loadingTotalRevenue = false);
    }
  }

  Future<void> _updateRevenue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final percentage = double.parse(_percentageController.text);
      final response =
          await _collaborationService.updateRevenuePercentage(
        collaborationId: widget.collaboration.id,
        percentage: percentage,
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Porcentaje de ganancias actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception(response.error ?? 'Error desconocido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entityType = widget.collaboration.isForSong ? 'Canción' : 'Álbum';
    final availablePercentage = _currentTotalRevenue != null
        ? 100 -
            (_currentTotalRevenue! - widget.collaboration.revenuePercentage)
        : null;

    return AlertDialog(
      backgroundColor: AppTheme.surfaceBlack,
      title: Row(
        children: [
          const Icon(Icons.attach_money, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Porcentaje de Ganancias',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collaboration info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.collaboration.isForSong
                              ? Icons.music_note
                              : Icons.album,
                          size: 20,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$entityType ID: ${widget.collaboration.entityId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 16, color: AppTheme.textGrey),
                        const SizedBox(width: 8),
                        Text(
                          'Artista ID: ${widget.collaboration.artistId}',
                          style: const TextStyle(color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.work,
                            size: 16, color: AppTheme.textGrey),
                        const SizedBox(width: 8),
                        Text(
                          'Rol: ${widget.collaboration.role}',
                          style: const TextStyle(color: AppTheme.textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Current total revenue
              if (_loadingTotalRevenue)
                const Center(child: CircularProgressIndicator())
              else if (_currentTotalRevenue != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pie_chart,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Distribución actual',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total asignado:',
                              style: TextStyle(color: AppTheme.textGrey)),
                          Text(
                            '${_currentTotalRevenue!.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      if (availablePercentage != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Disponible:',
                                style: TextStyle(color: AppTheme.textGrey)),
                            Text(
                              '${availablePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: availablePercentage > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Percentage input
              const Text(
                'Porcentaje de ganancias (%)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _percentageController,
                decoration: InputDecoration(
                  hintText: '0.0 - 100.0',
                  prefixIcon: const Icon(Icons.percent),
                  suffixText: '%',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.backgroundBlack,
                  helperText: availablePercentage != null
                      ? 'Máximo disponible: ${availablePercentage.toStringAsFixed(1)}%'
                      : null,
                  helperStyle: TextStyle(
                    color: availablePercentage != null &&
                            availablePercentage > 0
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un porcentaje';
                  }
                  final percentage = double.tryParse(value);
                  if (percentage == null) {
                    return 'Porcentaje inválido';
                  }
                  if (percentage < 0 || percentage > 100) {
                    return 'El porcentaje debe estar entre 0 y 100';
                  }
                  if (availablePercentage != null &&
                      percentage > availablePercentage) {
                    return 'Excede el porcentaje disponible (${availablePercentage.toStringAsFixed(1)}%)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quick percentage buttons
              const Text(
                'Selección rápida',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [10.0, 20.0, 25.0, 33.3, 50.0].map((percentage) {
                  final isAvailable =
                      availablePercentage == null ||
                      percentage <= availablePercentage;
                  return ActionChip(
                    label: Text(
                      '${percentage.toStringAsFixed(percentage == 33.3 ? 1 : 0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: isAvailable
                        ? () {
                            _percentageController.text =
                                percentage.toStringAsFixed(1);
                          }
                        : null,
                    backgroundColor: isAvailable
                        ? AppTheme.surfaceBlack
                        : AppTheme.backgroundBlack,
                    side: BorderSide(
                      color: isAvailable
                          ? AppTheme.primaryBlue
                          : AppTheme.textGrey.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateRevenue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
