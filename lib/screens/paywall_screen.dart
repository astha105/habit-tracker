// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:habit_tracker/services/payment_service.dart';
import 'package:habit_tracker/screens/track_progress_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _paymentService = PaymentService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _paymentService.init();

    _paymentService.onSuccess = (res) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TrackProgressScreen()),
      );
    };

    _paymentService.onFailure = (res) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${res.message}'),
          backgroundColor: const Color(0xFFD85A30),
        ),
      );
    };
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _pay() {
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    // Debug mode — bypass payment for simulator testing
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TrackProgressScreen()),
    );
    return;
  }
  setState(() => _loading = true);
  _paymentService.openCheckout(
    userPhone: '9999999999',
    userEmail: 'user@example.com',
    userName: 'User Name',
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0D0D0D), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('Unlock Progress',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF0D0D0D), letterSpacing: -0.4)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE6E5E0)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC8C0F8)),
                ),
                child: const Icon(Icons.show_chart_rounded, color: Color(0xFF7C6FD8), size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Track Progress',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Color(0xFF0D0D0D), letterSpacing: -1.2)),
              const SizedBox(height: 12),
              const Text(
                'Unlock detailed charts, streaks,\nheatmaps & top performer insights.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF5C5C5C), height: 1.6, letterSpacing: -0.1),
              ),
              const SizedBox(height: 32),
              _FeatureRow(icon: Icons.bar_chart_rounded, label: 'Weekly completion charts'),
              _FeatureRow(icon: Icons.local_fire_department_outlined, label: 'Streak tracking'),
              _FeatureRow(icon: Icons.grid_view_rounded, label: 'Activity heatmap'),
              _FeatureRow(icon: Icons.emoji_events_outlined, label: 'Top performer insights'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFE),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFC8C0F8)),
                ),
                child: const Text('One-time purchase · No subscription',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF534AB7), letterSpacing: 0.2)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6FD8),
                    disabledBackgroundColor: const Color(0xFFC8C0F8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Unlock for ₹199',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: -0.3)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Secure payment via Razorpay',
                  style: TextStyle(fontSize: 11, color: Color(0xFFA3A3A3))),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: const Color(0xFFF0EDFE), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: const Color(0xFF7C6FD8)),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF0D0D0D), letterSpacing: -0.2)),
        const Spacer(),
        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1D9E75)),
      ]),
    );
  }
}