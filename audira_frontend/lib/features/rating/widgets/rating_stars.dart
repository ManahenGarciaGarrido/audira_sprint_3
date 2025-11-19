import 'package:flutter/material.dart';

/// Widget para mostrar y seleccionar estrellas de valoración
/// GA01-128: Puntuación de 1-5 estrellas
class RatingStars extends StatelessWidget {
  final int rating;
  final bool isInteractive;
  final ValueChanged<int>? onRatingChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const RatingStars({
    super.key,
    required this.rating,
    this.isInteractive = false,
    this.onRatingChanged,
    this.size = 24.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isFilled = starNumber <= rating;

        if (isInteractive) {
          return GestureDetector(
            onTap: () => onRatingChanged?.call(starNumber),
            child: _buildStar(isFilled),
          );
        } else {
          return _buildStar(isFilled);
        }
      }),
    );
  }

  Widget _buildStar(bool isFilled) {
    return Icon(
      isFilled ? Icons.star : Icons.star_border,
      color: isFilled ? activeColor : inactiveColor,
      size: size,
    );
  }
}

/// Widget para mostrar valoración promedio con estrellas y cantidad
class RatingDisplay extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final double starSize;

  const RatingDisplay({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    this.starSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: starSize,
        ),
        const SizedBox(width: 4),
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: starSize * 0.9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($totalRatings)',
          style: TextStyle(
            fontSize: starSize * 0.8,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar distribución de estrellas
class RatingDistribution extends StatelessWidget {
  final int fiveStars;
  final int fourStars;
  final int threeStars;
  final int twoStars;
  final int oneStar;

  const RatingDistribution({
    super.key,
    required this.fiveStars,
    required this.fourStars,
    required this.threeStars,
    required this.twoStars,
    required this.oneStar,
  });

  @override
  Widget build(BuildContext context) {
    final total = fiveStars + fourStars + threeStars + twoStars + oneStar;

    if (total == 0) {
      return const Text('No hay valoraciones aún');
    }

    return Column(
      children: [
        _buildDistributionRow(context, 5, fiveStars, total),
        _buildDistributionRow(context, 4, fourStars, total),
        _buildDistributionRow(context, 3, threeStars, total),
        _buildDistributionRow(context, 2, twoStars, total),
        _buildDistributionRow(context, 1, oneStar, total),
      ],
    );
  }

  Widget _buildDistributionRow(BuildContext context, int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Text('$stars'),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 16, color: Colors.amber),
              ],
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
