import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/theme.dart';

class SubscriptionPage extends StatefulWidget {
  final bool isRenewal;
  final String? currentPlan;
  final String? currentExpiry;
  final int? daysRemaining;
  final int? ridesUsed;

  const SubscriptionPage({
    Key? key,
    this.isRenewal = false,
    this.currentPlan,
    this.currentExpiry,
    this.daysRemaining,
    this.ridesUsed,
  }) : super(key: key);

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedPlanIndex = 1;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Monthly ',
      'price': 'BD 15.00',
      'period': 'one month',
      'duration': 30,
      'savings': '0%',
      'popularity': '2.5k+ active',
      'bestFor': 'Students',
      'features': [
        'Unlimited bus rides',
        'Priority boarding at peak times',
        '20% discount on guest tickets',
      ],
    },
    {
      'name': 'Quarterly ',
      'price': 'BD 45.00',
      'period': '3 months one (1 Semester)',
      'duration': 90,
      'savings': '0%',
      'popularity': '5k+ active',
      'bestFor': 'Regular riders',
      'isPopular': true,
      'features': [
        'All monthly benefits included',
        'Free ticket upgrades',
        'Priority customer support',
        'Exclusive event access',
      ],
    },
    {
      'name': 'Yearly ',
      'price': 'BD 150.00',
      'period': 'one year (3 Semesters)',
      'duration': 365,
      'savings': '17%',
      'popularity': '1.2k+ active',
      'bestFor': 'Daily commuters',
      'features': [
        'All quarterly benefits included',
        'VIP lounge access at major stations',
        'Exclusive merchandise discounts',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.isRenewal ? 'Renew Subscription' : 'Choose Your Plan',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          Tooltip(
            message: 'All plans include student benefits',
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.info_outline, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (widget.isRenewal && widget.currentPlan != null)
                  _buildCurrentMembershipCard(),
                _buildBenefitsHeader(),
                ..._plans.asMap().entries.map((entry) {
                  int index = entry.key;
                  var plan = entry.value;
                  return _buildPlanCard(
                    plan: plan,
                    index: index,
                    isSelected: _selectedPlanIndex == index,
                    onTap: () => setState(() => _selectedPlanIndex = index),
                  );
                }).toList(),
                _buildFAQSection(),
                const SizedBox(height: 20),
                _buildInfoNote(),
                const SizedBox(height: 30),
              ],
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomButton()),
        ],
      ),
    );
  }

  // ========== CURRENT MEMBERSHIP CARD ==========
  Widget _buildCurrentMembershipCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Opacity(
              opacity: 0.2,
              child: Text(
                '?',
                style: TextStyle(fontSize: 150, color: Colors.white),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CURRENT MEMBERSHIP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.currentPlan!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Days Remaining',
                            style: TextStyle(fontSize: 11, color: Colors.white),
                          ),
                          Text(
                            '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rides Used',
                            style: TextStyle(fontSize: 11, color: Colors.white),
                          ),
                          Text(
                            '/30',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Valid until: ',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========== BENEFITS HEADER ==========
  Widget _buildBenefitsHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentRedLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Membership Benefits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Save up to 17% with annual plans',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildBenefitItem(Icons.directions_bus, 'Unlimited Rides'),
              _buildBenefitItem(Icons.bolt, 'Priority Boarding'),
              _buildBenefitItem(Icons.local_offer, '20% Discount'),
              _buildBenefitItem(Icons.headset_mic, 'Priority Support'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentRedLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========== PLAN CARD ==========
  Widget _buildPlanCard({
    required Map<String, dynamic> plan,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (plan['isPopular'] == true
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1)),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (plan['isPopular'] == true)
              const Positioned(top: -10, right: 20, child: _PopularBadge()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan['price'],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan['period'],
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    if (plan['savings'] != '0%')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          'Save ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ...plan['features']
                    .map<Widget>(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.accentRedLight),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Best for: ',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentRedLight,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 10,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              plan['popularity'],
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== FAQ SECTION ==========
  Widget _buildFAQSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            question: 'Can I cancel my subscription?',
            answer:
                'Yes, you can cancel anytime from your profile settings. Refunds are prorated based on remaining days.',
          ),
          _buildFAQItem(
            question: 'How do I use my subscription?',
            answer:
                'Book rides through the app and select "Use Subscription" at checkout. Your digital pass will be automatically applied.',
          ),
          _buildFAQItem(
            question: 'Student verification process?',
            answer:
                'Upload your student ID during signup. Verification takes 24 hours. All plans include student pricing.',
          ),
          _buildFAQItem(
            question: 'Can I share my subscription?',
            answer:
                'Subscriptions are personal and non-transferable. However, yearly plan includes a monthly companion pass.',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(color: AppColors.accentRedLight),
      ],
    );
  }

  // ========== INFO NOTE ==========
  Widget _buildInfoNote() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentRedLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'All prices include VAT. 30-day money-back guarantee on all annual plans.',
              style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  // ========== BOTTOM BUTTON ==========
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _processSubscription,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.lock_outline),
          label: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.isRenewal ? 'Renew Now' : 'Subscribe Now',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  // ========== PROCESS SUBSCRIPTION ==========
  Future<void> _processSubscription() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    var selectedPlan = _plans[_selectedPlanIndex];
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DateTime now = DateTime.now();
      DateTime newExpiry = now.add(Duration(days: selectedPlan['duration']));
      String formattedExpiry = " , ";

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'hasSubscription': true,
        'subscriptionType': selectedPlan['name'],
        'subscriptionExpiry': formattedExpiry,
        'autoRenewal': true,
        'ridesUsed': 0,
        'lastRenewal': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Icon(Icons.check_circle, color: AppColors.primary, size: 50),
            content: Text(
              widget.isRenewal
                  ? 'Subscription renewed successfully!'
                  : 'Subscription activated successfully!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: Text('OK', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in')));
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
}

// ========== POPULAR BADGE WIDGET ==========
class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'MOST POPULAR',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
