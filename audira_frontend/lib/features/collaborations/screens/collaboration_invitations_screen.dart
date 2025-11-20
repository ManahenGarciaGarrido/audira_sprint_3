// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/collaborator.dart';
import '../../../core/api/services/collaboration_service.dart';
import '../../../core/providers/auth_provider.dart';

/// Screen for viewing and responding to collaboration invitations
/// GA01-154: Aceptar/rechazar colaboradores
class CollaborationInvitationsScreen extends StatefulWidget {
  const CollaborationInvitationsScreen({super.key});

  @override
  State<CollaborationInvitationsScreen> createState() =>
      _CollaborationInvitationsScreenState();
}

class _CollaborationInvitationsScreenState
    extends State<CollaborationInvitationsScreen> {
  final CollaborationService _collaborationService = CollaborationService();

  List<Collaborator> _invitations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artistId = authProvider.currentUser!.id;
      final response =
          await _collaborationService.getPendingInvitations(artistId);

      if (response.success && response.data != null) {
        setState(() {
          _invitations = response.data!;
        });
      } else {
        throw Exception(response.error ?? 'Error desconocido');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInvitation(Collaborator invitation) async {
    try {
      final response =
          await _collaborationService.acceptInvitation(invitation.id);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitación aceptada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInvitations(); // Reload invitations
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

  Future<void> _rejectInvitation(Collaborator invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceBlack,
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Rechazar Invitación'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de rechazar esta invitación?\n\nNo podrás revertir esta acción.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response =
            await _collaborationService.rejectInvitation(invitation.id);

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitación rechazada'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadInvitations(); // Reload invitations
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
        title: const Text('Invitaciones Pendientes'),
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
                        onPressed: _loadInvitations,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _invitations.isEmpty
                  ? _buildEmptyState()
                  : _buildInvitationsList(),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.inbox,
              size: 64,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tienes invitaciones pendientes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando te inviten a colaborar, aparecerá aquí',
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildInvitationsList() {
    return RefreshIndicator(
      onRefresh: _loadInvitations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
          final invitation = _invitations[index];
          return _buildInvitationCard(invitation)
              .animate(delay: (index * 50).ms)
              .fadeIn()
              .slideX(begin: -0.1);
        },
      ),
    );
  }

  Widget _buildInvitationCard(Collaborator invitation) {
    final entityType = invitation.isForSong ? 'Canción' : 'Álbum';
    final icon = invitation.isForSong ? Icons.music_note : Icons.album;
    final color = invitation.isForSong ? AppTheme.primaryBlue : Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceBlack,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Colaboración en $entityType',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$entityType ID: ${invitation.entityId}',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Pendiente',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow(
              Icons.work,
              'Rol',
              invitation.role,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.person,
              'Invitado por',
              'Usuario ID: ${invitation.invitedBy}',
              color: AppTheme.textGrey,
            ),
            if (invitation.revenuePercentage > 0) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.attach_money,
                'Porcentaje de ganancias',
                '${invitation.revenuePercentage.toStringAsFixed(1)}%',
                color: Colors.green,
              ),
            ],
            if (invitation.createdAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.calendar_today,
                'Fecha de invitación',
                _formatDate(invitation.createdAt!),
                color: AppTheme.textGrey,
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectInvitation(invitation),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptInvitation(invitation),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.textGrey,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
