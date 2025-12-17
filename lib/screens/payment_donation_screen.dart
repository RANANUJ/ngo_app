import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/razorpay_service.dart';

class PaymentDonationScreen extends StatefulWidget {
  final String campaignId;
  final String campaignTitle;
  final String? campaignDescription;
  final num? goalAmount;
  final num? raisedAmount;
  final String donationType; // 'campaign', 'emergency', 'impact', 'donation_request'
  final Map<String, dynamic>? additionalData;

  const PaymentDonationScreen({
    Key? key,
    required this.campaignId,
    required this.campaignTitle,
    this.campaignDescription,
    this.goalAmount,
    this.raisedAmount,
    required this.donationType,
    this.additionalData,
  }) : super(key: key);

  @override
  State<PaymentDonationScreen> createState() => _PaymentDonationScreenState();
}

class _PaymentDonationScreenState extends State<PaymentDonationScreen> {
  static const Color primary = Color(0xFF0099B8);
  static const Color cardColor = Color(0xFF0099B8);
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  int? _selectedQuickAmount;
  bool _isAnonymous = false;
  String _selectedPaymentMethod = 'UPI'; // 'UPI', 'Card', 'Net Banking'
  bool _isLoading = false;
  late RazorpayService _razorpayService;

  final List<int> _quickAmounts = [100, 500, 1000, 2000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      
      // Try to get user name from volunteers or ngos collection
      try {
        var doc = await FirebaseFirestore.instance
            .collection('volunteers')
            .doc(user.uid)
            .get();
        
        if (!doc.exists) {
          doc = await FirebaseFirestore.instance
              .collection('ngos')
              .doc(user.uid)
              .get();
        }
        
        if (doc.exists) {
          final data = doc.data();
          _nameController.text = data?['name'] ?? data?['ngoName'] ?? user.displayName ?? '';
          _phoneController.text = data?['phone'] ?? '';
        } else {
          _nameController.text = user.displayName ?? '';
        }
      } catch (e) {
        _nameController.text = user.displayName ?? '';
      }
    }
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  int get _donationAmount {
    if (_selectedQuickAmount != null) return _selectedQuickAmount!;
    return int.tryParse(_amountController.text) ?? 0;
  }

  Future<void> _processDonation() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = _donationAmount;
    if (amount <= 0) {
      _showMessage('Please select or enter a valid amount', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Open Razorpay checkout
      _razorpayService.openCheckout(
        amount: amount.toDouble(),
        donorName: _isAnonymous ? 'Anonymous' : _nameController.text.trim(),
        donorEmail: _isAnonymous ? 'anonymous@example.com' : _emailController.text.trim(),
        donorPhone: _isAnonymous ? '0000000000' : _phoneController.text.trim(),
        campaignTitle: widget.campaignTitle,
        description: widget.campaignDescription,
        onSuccess: (PaymentSuccessResponse response) async {
          await _handlePaymentSuccess(response);
        },
        onFailure: (PaymentFailureResponse response) {
          _handlePaymentFailure(response);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error initiating payment: $e', isError: true);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Get NGO ID from campaign
      String? ngoId;
      final campaignDoc = await FirebaseFirestore.instance
          .collection(_getCollectionName(widget.donationType))
          .doc(widget.campaignId)
          .get();
      
      if (campaignDoc.exists) {
        ngoId = campaignDoc.data()?['createdBy'] ?? campaignDoc.data()?['ngoId'];
      }

      // Save donation to Firestore
      await _razorpayService.saveDonationToFirestore(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
        amount: _donationAmount.toDouble(),
        donorName: _nameController.text.trim(),
        donorEmail: _emailController.text.trim(),
        donorPhone: _phoneController.text.trim(),
        campaignId: widget.campaignId,
        campaignTitle: widget.campaignTitle,
        campaignType: widget.donationType,
        message: _messageController.text.trim(),
        isAnonymous: _isAnonymous,
        ngoId: ngoId,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your donation of ₹${_donationAmount.toStringAsFixed(0)} has been received successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment ID: ${response.paymentId}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close payment screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Payment successful but failed to save: $e', isError: true);
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    
    String errorMessage = 'Payment failed';
    if (response.message != null) {
      errorMessage = response.message!;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCollectionName(String campaignType) {
    switch (campaignType) {
      case 'emergency':
        return 'emergency_donations';
      case 'impact':
        return 'impacts';
      case 'donation_request':
        return 'donation_requests';
      case 'campaign':
      default:
        return 'campaigns';
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make a Donation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Details Section
            _buildCampaignDetails(),
            
            const SizedBox(height: 8),
            
            // Donation Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Donation Amount Section
                    _buildDonationAmountSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Anonymous Checkbox
                    _buildAnonymousCheckbox(),
                    
                    const SizedBox(height: 24),
                    
                    // Donor Information
                    _buildDonorInformation(),
                    
                    const SizedBox(height: 24),
                    
                    // Message Section
                    _buildMessageSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Security Badge
                    _buildSecurityBadge(),
                    
                    const SizedBox(height: 24),
                    
                    // Donate Button
                    _buildDonateButton(),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campaign Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.campaignTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.campaignDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.campaignDescription!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (widget.raisedAmount != null && widget.goalAmount != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '₹${widget.raisedAmount!.toInt()} raised',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
                Text(
                  '  Goal: ₹${widget.goalAmount!.toInt()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonationAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Donation Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Amount Input Field
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.currency_rupee, color: primary, size: 20),
            ),
            hintText: 'Enter custom amount (₹)',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: _selectedQuickAmount == null ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() => _selectedQuickAmount = null);
            }
          },
          validator: (value) {
            if (_selectedQuickAmount == null && (value == null || value.isEmpty)) {
              return 'Please enter or select an amount';
            }
            if (value != null && value.isNotEmpty) {
              final amount = int.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Quick Select Label
        const Text(
          'Quick Select',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        // Quick Amount Buttons
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _quickAmounts.map((amount) {
            final isSelected = _selectedQuickAmount == amount;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedQuickAmount = amount;
                  _amountController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? primary : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '₹$amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnonymousCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: _isAnonymous,
              onChanged: (value) {
                setState(() => _isAnonymous = value ?? false);
              },
              activeColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Make this donation anonymous',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your name will not be displayed publicly',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorInformation() {
    if (_isAnonymous) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Donor Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Full Name
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_outline, color: primary, size: 20),
            ),
            hintText: 'Full Name',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
          validator: (value) {
            if (!_isAnonymous && (value == null || value.isEmpty)) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        
        // Email Address
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.email_outlined, color: primary, size: 20),
            ),
            hintText: 'Email Address',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
          validator: (value) {
            if (!_isAnonymous && (value == null || value.isEmpty)) {
              return 'Please enter your email';
            }
            if (!_isAnonymous && !value!.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        
        // Phone Number
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_outlined, color: primary, size: 20),
            ),
            hintText: 'Phone Number',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.message_outlined, color: primary, size: 20),
            ),
            hintText: 'Your message of support',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // UPI
        _buildPaymentOption(
          icon: Icons.payment,
          iconColor: const Color(0xFF5DBF06),
          title: 'UPI',
          subtitle: 'Pay using UPI apps',
          value: 'UPI',
        ),
        const SizedBox(height: 12),
        
        // Card
        _buildPaymentOption(
          icon: Icons.credit_card,
          iconColor: cardColor,
          title: 'Card',
          subtitle: 'Credit/Debit Cards',
          value: 'Card',
        ),
        const SizedBox(height: 12),
        
        // Net Banking
        _buildPaymentOption(
          icon: Icons.account_balance,
          iconColor: const Color(0xFF9C27B0),
          title: 'Net Banking',
          subtitle: 'Pay via Internet Banking',
          value: 'Net Banking',
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.security, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment is secured by Razorpay with 256-bit SSL encryption',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateButton() {
    final amount = _donationAmount;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volunteer_activism, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    amount > 0 ? 'Donate ₹$amount' : 'Donate ₹0',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
