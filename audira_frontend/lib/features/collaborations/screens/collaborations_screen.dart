// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/collaborator.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/collaboration_service.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/add_collaborator_dialog.dart';
import '../widgets/revenue_settings_dialog.dart';
import 'collaboration_invitations_screen.dart';

/// Main screen for managing collaborations
/// GA01-154: Añadir/aceptar colaboradores
/// GA01-155: Definir porcentaje de ganancias
class CollaborationsScreen extends StatefulWidget {
  const CollaborationsScreen({super.key});

  @override
  State<CollaborationsScreen> createState() => _CollaborationsScreenState();
}

class _CollaborationsScreenState extends State<CollaborationsScreen>
    with SingleTickerProviderStateMixin {
  final CollaborationService _collaborationService = CollaborationService();
  final MusicService _musicService = MusicService();
  late TabController _tabController;

  List<Collaborator> _myCollaborations = []; // Where I'm a collaborator
  List<Collaborator> _invitedCollaborations = []; // Where I invited others
  List<Song> _mySongs = [];
  List<Album> _myAlbums = [];
  int _pendingInvitationsCount = 0;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistId = authProvider.currentUser!.id;

      // Load all collaborations for this artist
      final collaborationsResponse =
          await _collaborationService.getArtistCollaborations(artistId);
      if (collaborationsResponse.success &&
          collaborationsResponse.data != null) {
        final allCollaborations = collaborationsResponse.data!;

        // Separate by invited vs collaborator
        _myCollaborations = allCollaborations
            .where((c) => c.artistId == artistId && c.isAccepted)
            .toList();
        _invitedCollaborations = allCollaborations
            .where((c) => c.invitedBy == artistId && c.isAccepted)
            .toList();
      }

      // Load pending invitations count
      final pendingResponse =
          await _collaborationService.getPendingInvitations(artistId);
      if (pendingResponse.success && pendingResponse.data != null) {
        _pendingInvitationsCount = pendingResponse.data!.length;
      }

      // Load user's songs and albums
      final songsResponse = await _musicService.getSongsByArtist(artistId);
      if (songsResponse.success && songsResponse.data != null) {
        _mySongs = songsResponse.data!;
      }

      final albumsResponse = await _musicService.getAlbumsByArtist(artistId);
      if (albumsResponse.success && albumsResponse.data != null) {
        _myAlbums = albumsResponse.data!;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddCollaboratorDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddCollaboratorDialog(
        songs: _mySongs,
        albums: _myAlbums,
      ),
    );

    if (result == true) {
      _loadData(); // Reload data after adding collaborator
    }
  }

  Future<void> _showRevenueSettings(Collaborator collaboration) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RevenueSettingsDialog(
        collaboration: collaboration,
      ),
    );

    if (result == true) {
      _loadData(); // Reload data after updating revenue
    }
  }

  Future<void> _removeCollaboration(Collaborator collaboration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Eliminar Colaboración'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de eliminar esta colaboración?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response =
            await _collaborationService.deleteCollaboration(collaboration.id);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Colaboración eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colaboraciones'),
        actions: [
          // Invitations badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CollaborationInvitationsScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                tooltip: 'Invitaciones pendientes',
              ),
              if (_pendingInvitationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_pendingInvitationsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis Colaboraciones'),
            Tab(text: 'Colaboradores Invitados'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyCollaborationsTab(),
                    _buildInvitedCollaborationsTab(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCollaboratorDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Invitar Colaborador'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildMyCollaborationsTab() {
    if (_myCollaborations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes colaboraciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aún no participas en ninguna colaboración',
              style: TextStyle(color: AppTheme.textGrey),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myCollaborations.length,
        itemBuilder: (context, index) {
          final collaboration = _myCollaborations[index];
          return _buildCollaborationCard(collaboration, isOwner: false)
              .animate(delay: (index * 50).ms)
              .fadeIn()
              .slideX(begin: -0.1);
        },
      ),
    );
  }

  Widget _buildInvitedCollaborationsTab() {
    if (_invitedCollaborations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_add,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No has invitado colaboradores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Invita artistas a colaborar en tus canciones',
              style: TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddCollaboratorDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Invitar Colaborador'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invitedCollaborations.length,
        itemBuilder: (context, index) {
          final collaboration = _invitedCollaborations[index];
          return _buildCollaborationCard(collaboration, isOwner: true)
              .animate(delay: (index * 50).ms)
              .fadeIn()
              .slideX(begin: -0.1);
        },
      ),
    );
  }

  Widget _buildCollaborationCard(Collaborator collaboration,
      {required bool isOwner}) {
    final entityType = collaboration.isForSong ? 'Canción' : 'Álbum';
    final icon = collaboration.isForSong ? Icons.music_note : Icons.album;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceBlack,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          '$entityType ID: ${collaboration.entityId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rol: ${collaboration.role}',
              style: const TextStyle(color: AppTheme.textGrey),
            ),
            if (collaboration.revenuePercentage > 0)
              Text(
                'Ganancias: ${collaboration.revenuePercentage.toStringAsFixed(1)}%',
                style: const TextStyle(color: AppTheme.primaryBlue),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 8),
                    Text('Artista ID: ${collaboration.artistId}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 8),
                    Text(
                      collaboration.createdAt != null
                          ? 'Creado: ${_formatDate(collaboration.createdAt!)}'
                          : 'Fecha desconocida',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isOwner) ...[
                      // Owner can set revenue percentage
                      OutlinedButton.icon(
                        onPressed: () => _showRevenueSettings(collaboration),
                        icon: const Icon(Icons.attach_money, size: 16),
                        label: const Text('Ganancias'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Owner can remove collaboration
                      OutlinedButton.icon(
                        onPressed: () => _removeCollaboration(collaboration),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Eliminar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ] else ...[
                      // Collaborator can only view
                      const Text(
                        'Fuiste invitado a esta colaboración',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
