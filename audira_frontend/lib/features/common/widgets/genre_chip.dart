import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../core/models/genre.dart';

class GenreChip extends StatelessWidget {
  final Genre genre;

  const GenreChip({super.key, required this.genre});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(genre.name),
      backgroundColor: AppTheme.cardBlack,
      labelStyle: const TextStyle(color: Colors.white),
      side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      onPressed: () {
        Navigator.pushNamed(context, '/genre', arguments: genre.id);
      },
    );
  }
}
