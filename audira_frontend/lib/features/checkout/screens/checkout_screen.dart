import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/payment.dart';
import '../../../core/api/services/payment_service.dart';
import '../../../core/models/order.dart';
import '../../receipt/screens/receipt_screen.dart';
import 'payment_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Order order;

  const CheckoutScreen({super.key, required this.order});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = PaymentService();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.creditCard;

  // Card details
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummary(),
              const SizedBox(height: 24),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),
              if (_selectedPaymentMethod == PaymentMethod.creditCard ||
                  _selectedPaymentMethod == PaymentMethod.debitCard)
                _buildCardForm(),
              if (_selectedPaymentMethod == PaymentMethod.stripe)
                _buildStripeInfo(),
              const SizedBox(height: 24),
              _buildPayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de la orden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Número de orden:'),
                Text(
                  widget.order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:'),
                Text(
                  '\$${widget.order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.order.items.length} artículo(s)',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Método de pago',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      
      RadioGroup<PaymentMethod>(
        groupValue: _selectedPaymentMethod,
        onChanged: (PaymentMethod? value) { 
          if (value != null) {
            setState(() {
              _selectedPaymentMethod = value; 
            });
          }
        },
        child: Column(
          children: [
            _buildPaymentMethodOption(
              PaymentMethod.creditCard,
              Icons.credit_card,
            ),
            _buildPaymentMethodOption(
              PaymentMethod.debitCard,
              Icons.payment,
            ),
            _buildPaymentMethodOption(
              PaymentMethod.stripe,
              Icons.credit_score,
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildPaymentMethodOption(PaymentMethod method, IconData icon) {
  final isSelected = _selectedPaymentMethod == method;

  return Card(
    color: isSelected ? Colors.blue.shade900 : null,
    child: ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : null,
      ),
      title: Text(
        method.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Radio<PaymentMethod>(
        value: method,
      ),
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
    ),
  );
}

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de la tarjeta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Número de tarjeta',
            hintText: '1234 5678 9012 3456',
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el número de tarjeta';
            }
            final digits = value.replaceAll(' ', '');
            if (digits.length < 13 || digits.length > 16) {
              return 'Número de tarjeta inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardHolderController,
          decoration: const InputDecoration(
            labelText: 'Titular de la tarjeta',
            hintText: 'NOMBRE APELLIDO',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingresa el nombre del titular';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                decoration: const InputDecoration(
                  labelText: 'Vencimiento',
                  hintText: 'MM/AA',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la fecha';
                  }
                  if (!value.contains('/') || value.length != 5) {
                    return 'Formato MM/AA';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'CVV requerido';
                  }
                  if (value.length < 3) {
                    return 'CVV inválido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Para pruebas: tarjetas que empiezan con 4000 fallarán',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStripeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_score, color: Colors.purple.shade700),
              const SizedBox(width: 12),
              Text(
                'Pago con Stripe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Serás redirigido a la pasarela segura de Stripe para completar tu pago.',
            style: TextStyle(color: Colors.purple.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Pagar \$${widget.order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Prepare payment details
      Map<String, String>? paymentDetails;

      if (_selectedPaymentMethod == PaymentMethod.creditCard ||
          _selectedPaymentMethod == PaymentMethod.debitCard) {
        paymentDetails = {
          'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
          'cardHolder': _cardHolderController.text,
          'expiryDate': _expiryDateController.text,
          'cvv': _cvvController.text,
        };
      }

      debugPrint('Processing payment for order ${widget.order.id}');

      // Process payment
      final response = await _paymentService.processPayment(
        orderId: widget.order.id,
        userId: widget.order.userId,
        paymentMethod: _selectedPaymentMethod,
        amount: widget.order.totalAmount,
        paymentDetails: paymentDetails,
      );

      debugPrint('CheckoutScreen - Payment response - success: ${response.success}, data null: ${response.data == null}');

      if (response.success && response.data != null) {
        final paymentResponse = response.data!;
        debugPrint('PaymentResponse - success: ${paymentResponse.success}, payment null: ${paymentResponse.payment == null}');

        if (paymentResponse.success) {
          // Payment successful
          if (paymentResponse.payment != null) {
            debugPrint('Payment received with status: ${paymentResponse.payment!.status}');

            // Wait for payment to be COMPLETED before navigating
            await _waitForPaymentCompletion(paymentResponse.payment!);
          } else {
            setState(() {
              _isProcessing = false;
            });
            debugPrint('ERROR: Payment is null even though success is true');
            _showError('Error: Pago procesado pero respuesta incompleta');
          }
        } else {
          // Payment failed
          setState(() {
            _isProcessing = false;
          });
          debugPrint('Payment failed: ${paymentResponse.message}');
          _showPaymentResult(
            success: false,
            errorMessage: paymentResponse.message,
            payment: paymentResponse.payment,
          );
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
        debugPrint('API error: ${response.error}');
        _showError(response.error ?? 'Error al procesar el pago');
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in _processPayment: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isProcessing = false;
      });
      _showError('Error inesperado: $e');
    }
  }

  Future<void> _waitForPaymentCompletion(Payment initialPayment) async {
    Payment currentPayment = initialPayment;
    int attempts = 0;
    const maxAttempts = 10; // 10 intentos = 10 segundos máximo
    const pollInterval = Duration(seconds: 1);

    debugPrint('=== Waiting for payment to be COMPLETED ===');
    debugPrint('Initial payment status: ${currentPayment.status}');

    // Si ya está COMPLETED, navegar inmediatamente
    if (currentPayment.status == PaymentStatus.completed) {
      debugPrint('Payment already COMPLETED, navigating to success screen');
      setState(() {
        _isProcessing = false;
      });
      _showPaymentResult(success: true, payment: currentPayment);
      return;
    }

    // Polling loop: esperar hasta que el estado sea COMPLETED
    while (attempts < maxAttempts) {
      await Future.delayed(pollInterval);
      attempts++;

      debugPrint('Polling attempt $attempts/$maxAttempts - Checking payment status...');

      // Obtener el estado actualizado del payment
      final response = await _paymentService.getPaymentById(currentPayment.id);

      if (response.success && response.data != null) {
        currentPayment = response.data!;
        debugPrint('Payment status: ${currentPayment.status}');

        if (currentPayment.status == PaymentStatus.completed) {
          debugPrint('✓ Payment is now COMPLETED! Navigating to success screen');
          setState(() {
            _isProcessing = false;
          });
          _showPaymentResult(success: true, payment: currentPayment);
          return;
        } else if (currentPayment.status == PaymentStatus.failed) {
          debugPrint('✗ Payment FAILED');
          setState(() {
            _isProcessing = false;
          });
          _showPaymentResult(
            success: false,
            payment: currentPayment,
            errorMessage: 'El pago falló: ${currentPayment.errorMessage ?? "Error desconocido"}',
          );
          return;
        }

        // Si sigue en PROCESSING, continuar esperando
        debugPrint('Payment still in ${currentPayment.status}, waiting...');
      } else {
        debugPrint('Error fetching payment status: ${response.error}');
      }
    }

    // Timeout: el pago no se completó en el tiempo esperado
    debugPrint('⚠ Timeout waiting for payment completion');
    setState(() {
      _isProcessing = false;
    });
    _showError('El pago está siendo procesado. Por favor verifica el estado más tarde.');

    // Navegar al inicio
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showPaymentResult({
    required bool success,
    Payment? payment,
    String? errorMessage,
  }) {
    if (success && payment != null) {
      // Navigate to success screen with library integration
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            payment: payment,
            order: widget.order,
          ),
        ),
      );
    } else {
      // Navigate to error screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentResultScreen(
            success: false,
            payment: payment,
            errorMessage: errorMessage,
            order: widget.order,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Expiry date formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length >= 2) {
      final buffer = StringBuffer();
      buffer.write(text.substring(0, 2));
      if (text.length > 2) {
        buffer.write('/');
        buffer.write(text.substring(2));
      }

      return TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.length),
      );
    }

    return newValue;
  }
}

// Payment result screen
class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final Payment? payment;
  final String? errorMessage;
  final Order order;

  const PaymentResultScreen({
    super.key,
    required this.success,
    this.payment,
    this.errorMessage,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del pago'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                success ? '¡Pago exitoso!' : 'Pago fallido',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (payment != null) ...[
                Text(
                  'ID de transacción:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  payment!.transactionId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Monto: \$${payment!.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (success) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => ReceiptScreen(payment: payment!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt),
                  label: const Text('Ver recibo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (payment != null) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final paymentService = PaymentService();
                    final response =
                        await paymentService.retryPayment(payment!.id);

                    if (context.mounted) {
                      if (response.success && response.data != null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => PaymentResultScreen(
                              success: response.data!.success,
                              payment: response.data!.payment,
                              errorMessage: response.data!.success
                                  ? null
                                  : response.data!.message,
                              order: order,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response.error ?? 'Error al reintentar el pago',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
