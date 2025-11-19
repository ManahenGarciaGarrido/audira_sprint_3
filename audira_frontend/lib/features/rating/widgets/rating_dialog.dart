import 'package:flutter/material.dart';
import 'package:audira_frontend/core/models/rating.dart';
import 'package:audira_frontend/core/api/services/rating_service.dart';
import 'package:audira_frontend/features/rating/widgets/rating_stars.dart';

/// Diálogo para crear o editar una valoración
/// GA01-128: Puntuación de 1-5 estrellas
/// GA01-129: Comentario opcional (500 chars)
/// GA01-130: Editar/eliminar valoración
class RatingDialog extends StatefulWidget {
  final String entityType;
  final int entityId;
  final Rating? existingRating;
  final String? entityName;

  const RatingDialog({
    super.key,
    required this.entityType,
    required this.entityId,
    this.existingRating,
    this.entityName,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _ratingService = RatingService();

  int _selectedRating = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _selectedRating = widget.existingRating!.rating;
      _commentController.text = widget.existingRating!.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una valoración'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final comment = _commentController.text.trim();

      if (widget.existingRating != null) {
        // GA01-130: Actualizar valoración existente
        final response = await _ratingService.updateRating(
          ratingId: widget.existingRating!.id,
          rating: _selectedRating,
          comment: comment.isEmpty ? null : comment,
        );

        if (response.success) {
          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Valoración actualizada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.error ?? 'Error al actualizar valoración'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // GA01-128, GA01-129: Crear nueva valoración
        final response = await _ratingService.createRating(
          entityType: widget.entityType,
          entityId: widget.entityId,
          rating: _selectedRating,
          comment: comment.isEmpty ? null : comment,
        );

        if (response.success) {
          if (mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Valoración creada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.error ?? 'Error al crear valoración'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRating() async {
    if (widget.existingRating == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar valoración'),
        content: const Text('¿Estás seguro de que quieres eliminar esta valoración?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _ratingService.deleteRating(widget.existingRating!.id);

      if (response.success) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Valoración eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Error al eliminar valoración'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRating != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar valoración' : 'Nueva valoración'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.entityName != null) ...[
                Text(
                  widget.entityName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // GA01-128: Selector de estrellas
              const Text('Valoración *'),
              const SizedBox(height: 8),
              Center(
                child: RatingStars(
                  rating: _selectedRating,
                  isInteractive: true,
                  onRatingChanged: (rating) {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                  size: 40.0,
                ),
              ),
              const SizedBox(height: 24),

              // GA01-129: Comentario opcional (500 chars)
              const Text('Comentario (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu opinión...',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'El comentario no puede exceder 500 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                '${_commentController.text.length}/500 caracteres',
                style: TextStyle(
                  fontSize: 12,
                  color: _commentController.text.length > 500
                      ? Colors.red
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // GA01-130: Botón eliminar (solo si está editando)
        if (isEditing)
          TextButton(
            onPressed: _isLoading ? null : _deleteRating,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),

        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),

        ElevatedButton(
          onPressed: _isLoading ? null : _submitRating,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Actualizar' : 'Publicar'),
        ),
      ],
    );
  }
}

/// Función helper para mostrar el diálogo de valoración
Future<bool?> showRatingDialog(
  BuildContext context, {
  required String entityType,
  required int entityId,
  Rating? existingRating,
  String? entityName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => RatingDialog(
      entityType: entityType,
      entityId: entityId,
      existingRating: existingRating,
      entityName: entityName,
    ),
  );
}
