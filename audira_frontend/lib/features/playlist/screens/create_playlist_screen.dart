import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/song.dart';
import '../../../config/theme.dart';

class CreatePlaylistScreen extends StatefulWidget {
  final int? playlistId; // For editing existing playlist

  const CreatePlaylistScreen({super.key, this.playlistId});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = false;
  bool _showPreview = false;

  final List<Song> _selectedSongs = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final libraryProvider = context.read<LibraryProvider>();

      if (!authProvider.isAuthenticated) {
        throw Exception('Please login to create playlists');
      }

      final playlist = await libraryProvider.createPlaylist(
        userId: authProvider.currentUser!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isPublic: _isPublic,
      );

      if (playlist != null) {
        // Add selected songs to playlist
        for (final song in _selectedSongs) {
          await libraryProvider.addSongToPlaylist(playlist.id, song.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Playlist created successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to create playlist');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _togglePreview() {
    setState(() => _showPreview = !_showPreview);
  }

  void _addSongsToPlaylist() {
    // Song selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Song selection - Coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.playlistId == null ? 'Create Playlist' : 'Edit Playlist'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: _togglePreview,
            tooltip: _showPreview ? 'Edit' : 'Preview',
          ),
        ],
      ),
      body: _showPreview ? _buildPreview() : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Playlist name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.playlist_play),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a playlist name';
                }
                return null;
              },
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Public/Private toggle
            Card(
              child: SwitchListTile(
                title: const Text('Make playlist public'),
                subtitle:
                    const Text('Anyone can see and listen to this playlist'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
                activeThumbColor: AppTheme.primaryBlue,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

            const SizedBox(height: 24),

            // Songs section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Songs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addSongsToPlaylist,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Songs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Selected songs list
            if (_selectedSongs.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.music_note,
                        size: 64, color: AppTheme.textGrey),
                    const SizedBox(height: 16),
                    Text(
                      'No songs added yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms)
            else
              ..._selectedSongs.map((song) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song.name),
                      subtitle: Text('Artist ID: ${song.artistId}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedSongs.remove(song);
                          });
                        },
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.playlist_play, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Untitled Playlist'
                      : _nameController.text.trim(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_descriptionController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.trim(),
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPublic ? 'Public' : 'Private',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.music_note,
                        size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedSongs.length} songs',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 24),

          // Preview info
          const Text(
            'Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your playlist will look to others',
            style: TextStyle(color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 24),

          // Songs preview
          if (_selectedSongs.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.music_note,
                      size: 64, color: AppTheme.textGrey),
                  const SizedBox(height: 16),
                  Text(
                    'No songs in this playlist',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ..._selectedSongs.asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(song.name),
                  subtitle: Text('Artist ID: ${song.artistId}'),
                  trailing: const Icon(Icons.play_arrow),
                ),
              ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: -0.2);
            }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        border: Border(
          top: BorderSide(color: AppTheme.textGrey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _savePlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.playlistId == null
                      ? 'Create Playlist'
                      : 'Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
