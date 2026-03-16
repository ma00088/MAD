import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../providers/notification_provider.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> selectedPlan;

  const SubscriptionPaymentScreen({Key? key, required this.selectedPlan})
    : super(key: key);

  @override
  _SubscriptionPaymentScreenState createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPaymentMethod = 'credit_card';
  bool _termsAccepted = false;
  bool _isProcessing = false;

  // Form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
      });
    }
  }

  // ========== CREATE SUBSCRIPTION RECORD IN STUDENT_MEMBERSHIPS ==========
  Future<void> _createSubscriptionRecord(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime expiryDate = now.add(Duration(days: widget.selectedPlan['duration']));
      
      // Get user details
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      String studentName = userDoc.get('fullName') ?? 'Student';
      String studentId = userDoc.get('studentId') ?? '';
      
      // Parse price from string (e.g., "BD 15.00" -> 15.00)
      double price = 0.0;
      dynamic priceValue = widget.selectedPlan['price'];
      
      if (priceValue is String) {
        // Remove 'BD ' and any commas, then parse
        String cleanPrice = priceValue.replaceAll('BD ', '').replaceAll(',', '');
        price = double.parse(cleanPrice);
      } else if (priceValue is num) {
        price = priceValue.toDouble();
      }
      
      // Create subscription record
      await FirebaseFirestore.instance.collection('student_memberships').add({
        'studentId': userId,
        'studentName': studentName,
        'studentIdNumber': studentId,
        'planName': widget.selectedPlan['name'].toString().trim(),
        'price': price,
        'durationDays': widget.selectedPlan['duration'],
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(expiryDate),
        'status': 'active',
        'autoRenewal': true,
        'paymentMethod': _selectedPaymentMethod,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Subscription record created in student_memberships');
    } catch (e) {
      print('❌ Error creating subscription record: $e');
      // Don't throw - we still want to show success to user
    }
  }

  // ========== ADD SUBSCRIPTION NOTIFICATION ==========
  Future<void> _addSubscriptionNotification() async {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      String planName = widget.selectedPlan['name'].toString().trim();
      String expiryDate = _calculateExpiryDate();
      
      await notificationProvider.addNotification(
        title: 'Subscription Activated',
        message: 'Your $planName subscription is now active. Valid until $expiryDate. Enjoy unlimited rides!',
        type: 'subscription',
        data: {
          'plan': planName,
          'expiry': expiryDate,
        },
      );
      
      // Add a reminder notification for renewal (30 days before expiry for annual, 7 days for monthly)
      if (widget.selectedPlan['duration'] >= 365) {
        // Annual plan - remind 30 days before
        await notificationProvider.addNotification(
          title: 'Subscription Renewal Reminder',
          message: 'Your annual subscription will expire in 30 days. Renew now to continue enjoying benefits.',
          type: 'subscription',
          data: {
            'plan': planName,
            'expiry': expiryDate,
            'reminder': true,
          },
        );
      } else {
        // Monthly/Quarterly - remind 7 days before
        await notificationProvider.addNotification(
          title: 'Subscription Renewal Reminder',
          message: 'Your subscription will expire soon. Renew now to avoid interruption.',
          type: 'subscription',
          data: {
            'plan': planName,
            'expiry': expiryDate,
            'reminder': true,
          },
        );
      }
      
      print('✅ Subscription notifications added successfully');
    } catch (e) {
      print('Error adding subscription notification: $e');
    }
  }

  String _calculateExpiryDate() {
    DateTime now = DateTime.now();
    DateTime newExpiry = now.add(
      Duration(days: widget.selectedPlan['duration']),
    );
    return "${_getMonthName(newExpiry.month)} ${newExpiry.day}, ${newExpiry.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Plan Summary
            _buildPlanSummary(),
            // Payment Form
            _buildPaymentForm(),
            // Terms and Conditions
            _buildTermsSection(),
            // Pay Button
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummary() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plan Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.selectedPlan['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.selectedPlan['price'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            widget.selectedPlan['period'],
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.selectedPlan['price'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            _buildPaymentMethodOption(
              'credit_card',
              'Credit/Debit Card',
              Icons.credit_card,
            ),
            _buildPaymentMethodOption('paypal', 'PayPal', Icons.payment),
            _buildPaymentMethodOption(
              'bank_transfer',
              'Bank Transfer',
              Icons.account_balance,
            ),
            if (_selectedPaymentMethod == 'credit_card') ...[
              SizedBox(height: 24),
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_selectedPaymentMethod == 'credit_card') {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card number';
                    }
                    if (value.replaceAll(' ', '').length < 16) {
                      return 'Please enter a valid card number';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: InputDecoration(
                        labelText: 'MM/YY',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        if (_selectedPaymentMethod == 'credit_card') {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (value) {
                        if (_selectedPaymentMethod == 'credit_card') {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _cardHolderController,
                decoration: InputDecoration(
                  labelText: 'Card Holder Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (_selectedPaymentMethod == 'credit_card') {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card holder name';
                    }
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? AppColors.primary
                : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _selectedPaymentMethod == value
              ? AppColors.primary.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _selectedPaymentMethod == value
                  ? AppColors.primary
                  : Colors.grey,
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _selectedPaymentMethod == value
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            Spacer(),
            if (_selectedPaymentMethod == value)
              Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) =>
                    setState(() => _termsAccepted = value ?? false),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      margin: EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: (_isProcessing || !_termsAccepted) ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isProcessing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Pay ${widget.selectedPlan['price']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ========== PROCESS PAYMENT ==========
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(Duration(seconds: 2));

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DateTime now = DateTime.now();
        DateTime newExpiry = now.add(
          Duration(days: widget.selectedPlan['duration']),
        );
        String formattedExpiry =
            "${_getMonthName(newExpiry.month)} ${newExpiry.day}, ${newExpiry.year}";

        // 1. Update user subscription in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'hasSubscription': true,
          'subscriptionType': widget.selectedPlan['name'],
          'subscriptionExpiry': formattedExpiry,
          'autoRenewal': true,
          'ridesUsed': 0,
          'lastRenewal': FieldValue.serverTimestamp(),
          'paymentMethod': _selectedPaymentMethod,
          'email': _emailController.text,
          'phone': _phoneController.text,
        }, SetOptions(merge: true));

        // 2. CREATE SUBSCRIPTION RECORD IN STUDENT_MEMBERSHIPS COLLECTION
        await _createSubscriptionRecord(user.uid);

        // 3. Add subscription notification
        await _addSubscriptionNotification();

        setState(() => _isProcessing = false);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Icon(Icons.check_circle, color: AppColors.primary, size: 50),
              content: Text(
                'Payment successful! Subscription activated.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Return to home with success
                  },
                  child: Text('OK', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('You must be logged in')));
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}