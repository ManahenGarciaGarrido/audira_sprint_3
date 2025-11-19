import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/payment_service.dart';
import '../../../core/models/payment.dart';
import '../../receipt/screens/receipt_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() {
        _error = 'Usuario no identificado';
        _isLoading = false;
      });
      return;
    }

    final response = await _paymentService.getPaymentsByUserId(userId);

    if (response.success && response.data != null) {
      setState(() {
        _payments = response.data!;
        // Sort by date, most recent first
        _payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Error al cargar el historial de pagos';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return AppTheme.errorRed;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.refunded:
        return Colors.purple;
      case PaymentStatus.cancelled:
        return AppTheme.textGrey;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.pending:
        return Icons.hourglass_empty;
      case PaymentStatus.processing:
        return Icons.sync;
      case PaymentStatus.refunded:
        return Icons.money_off;
      case PaymentStatus.cancelled:
        return Icons.cancel;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.stripe:
        return Icons.credit_score;
      case PaymentMethod.paypal:
        return Icons.payment;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadPaymentHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payment_outlined,
                            size: 64,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes pagos registrados',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPaymentHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return _buildPaymentCard(payment, index);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPaymentCard(Payment payment, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(payment.status),
                      color: _getStatusColor(payment.status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                payment.status.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(payment.status),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(payment.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textGrey,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: payment.status == PaymentStatus.completed
                              ? Colors.green
                              : AppTheme.textGrey,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getPaymentMethodIcon(payment.paymentMethod),
                    size: 20,
                    color: AppTheme.textGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    payment.paymentMethod.displayName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (payment.status == PaymentStatus.completed)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ReceiptScreen(payment: payment),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt, size: 16),
                      label: const Text('Ver recibo'),
                    ),
                ],
              ),
              if (payment.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          payment.errorMessage!,
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX();
  }

  void _showPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Detalles del Pago',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailCard(
                      'Estado',
                      payment.status.displayName,
                      icon: _getStatusIcon(payment.status),
                      iconColor: _getStatusColor(payment.status),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      'Monto',
                      '\$${payment.amount.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      'Método de pago',
                      payment.paymentMethod.displayName,
                      icon: _getPaymentMethodIcon(payment.paymentMethod),
                      iconColor: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      'ID de transacción',
                      payment.transactionId,
                      icon: Icons.qr_code,
                      iconColor: AppTheme.textGrey,
                      isSelectable: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      'Fecha de creación',
                      _formatDate(payment.createdAt),
                      icon: Icons.calendar_today,
                      iconColor: AppTheme.textGrey,
                    ),
                    if (payment.completedAt != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        'Fecha de completado',
                        _formatDate(payment.completedAt!),
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                      ),
                    ],
                    if (payment.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        'Error',
                        payment.errorMessage!,
                        icon: Icons.error,
                        iconColor: AppTheme.errorRed,
                      ),
                    ],
                    if (payment.retryCount > 0) ...[
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        'Intentos',
                        payment.retryCount.toString(),
                        icon: Icons.replay,
                        iconColor: Colors.orange,
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (payment.status == PaymentStatus.completed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReceiptScreen(payment: payment),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt),
                          label: const Text('Ver recibo completo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (payment.status == PaymentStatus.failed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            _retryPayment(payment);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar pago'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value, {
    required IconData icon,
    required Color iconColor,
    bool isSelectable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                isSelectable
                    ? SelectableText(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryPayment(Payment payment) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final response = await _paymentService.retryPayment(payment.id);

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      if (response.success && response.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data!.success
                  ? 'Pago procesado exitosamente'
                  : 'El pago falló nuevamente',
            ),
            backgroundColor:
                response.data!.success ? Colors.green : AppTheme.errorRed,
          ),
        );
        _loadPaymentHistory(); // Reload payments
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Error al reintentar el pago'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
