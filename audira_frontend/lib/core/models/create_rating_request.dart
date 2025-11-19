/// Request para crear una nueva valoración
/// GA01-128: rating (1-5 estrellas)
/// GA01-129: comment (opcional, max 500 chars)
class CreateRatingRequest {
  final String entityType;
  final int entityId;
  final int rating;
  final String? comment;

  const CreateRatingRequest({
    required this.entityType,
    required this.entityId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'entityType': entityType,
      'entityId': entityId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }

  /// Validar que el rating esté entre 1 y 5
  bool isValid() {
    return rating >= 1 && rating <= 5 && (comment == null || comment!.length <= 500);
  }
}

/// Request para actualizar una valoración existente
/// GA01-130: Editar valoración
class UpdateRatingRequest {
  final int? rating;
  final String? comment;

  const UpdateRatingRequest({
    this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      if (rating != null) 'rating': rating,
      if (comment != null) 'comment': comment,
    };
  }

  /// Validar que el rating esté entre 1 y 5 si está presente
  bool isValid() {
    return (rating == null || (rating! >= 1 && rating! <= 5)) &&
        (comment == null || comment!.length <= 500);
  }
}
