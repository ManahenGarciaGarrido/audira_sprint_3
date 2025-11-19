import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/download_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/models/song.dart';
import '../../../core/models/downloaded_song.dart';

/// Botón de descarga para canciones
/// GA01-135: Botón y permisos (solo si comprado)
class DownloadButton extends StatefulWidget {
  final Song song;
  final bool showLabel;
  final VoidCallback? onDownloadComplete;

  const DownloadButton({
    super.key,
    required this.song,
    this.showLabel = false,
    this.onDownloadComplete,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _isProcessing = false;

  Future<void> _handleDownload() async {
    final downloadProvider = context.read<DownloadProvider>();
    final libraryProvider = context.read<LibraryProvider>();

    // GA01-135: Verificar que la canción esté comprada
    if (!libraryProvider.isSongPurchased(widget.song.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes comprar esta canción para descargarla'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Verificar permisos
      final hasPermission = await downloadProvider.hasStoragePermission();
      if (!hasPermission) {
        final granted = await downloadProvider.requestStoragePermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se necesitan permisos de almacenamiento'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }
      }

      // Iniciar descarga
      final success = await downloadProvider.downloadSong(widget.song);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.song.name} descargada correctamente'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          widget.onDownloadComplete?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al descargar la canción'),
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
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    final downloadProvider = context.read<DownloadProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar descarga'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la descarga de "${widget.song.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);

      final success = await downloadProvider.deleteDownload(widget.song.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Descarga eliminada'
                  : 'Error al eliminar la descarga',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final libraryProvider = context.watch<LibraryProvider>();

    final isPurchased = libraryProvider.isSongPurchased(widget.song.id);
    final status = downloadProvider.getDownloadStatus(widget.song.id);
    final progress = downloadProvider.getDownloadProgress(widget.song.id);

    // No mostrar botón si no está comprada
    if (!isPurchased) {
      return const SizedBox.shrink();
    }

    // Mostrar progreso de descarga
    if (status == DownloadStatus.downloading && progress != null) {
      return _buildDownloadProgress(progress);
    }

    // Mostrar botón según estado
    if (status == DownloadStatus.downloaded) {
      return _buildDownloadedButton();
    }

    return _buildDownloadButton();
  }

  Widget _buildDownloadButton() {
    return widget.showLabel
        ? TextButton.icon(
            onPressed: _isProcessing ? null : _handleDownload,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Descargar'),
          )
        : IconButton(
            onPressed: _isProcessing ? null : _handleDownload,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Descargar',
          );
  }

  Widget _buildDownloadedButton() {
    return widget.showLabel
        ? TextButton.icon(
            onPressed: _isProcessing ? null : _handleDelete,
            icon: const Icon(Icons.download_done_rounded, color: Colors.green),
            label: const Text('Descargada'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          )
        : IconButton(
            onPressed: _isProcessing ? null : _handleDelete,
            icon: const Icon(Icons.download_done_rounded, color: Colors.green),
            tooltip: 'Descargada - Toca para eliminar',
          ).animate().scale(duration: 300.ms);
  }

  Widget _buildDownloadProgress(DownloadProgress progress) {
    return SizedBox(
      width: widget.showLabel ? null : 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.progress,
            strokeWidth: 3,
          ),
          Text(
            '${(progress.progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
