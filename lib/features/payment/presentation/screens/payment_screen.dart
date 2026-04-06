import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../services/stripe_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String botId;
  final String botName;
  final String botDescription;
  final double priceMonthly;
  final double priceYearly;

  const PaymentScreen({
    super.key,
    required this.botId,
    required this.botName,
    required this.botDescription,
    required this.priceMonthly,
    required this.priceYearly,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPlan = 'yearly';
  bool _isLoading = false;

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);

    try {
      final session = ref.read(supabaseClientProvider).auth.currentSession;
      if (session == null) {
        context.push('/auth');
        return;
      }

      // Определяем технический ID плана для Stripe
      final String planId =
          _selectedPlan == 'monthly' ? 'monthly_50' : 'monthly_200';

      // Вызываем реальный Stripe сервис с новым параметром plan
      await StripeService().createCheckoutSession(
        botId: widget.botId,
        plan: planId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка оплаты: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = ref.watch(stringsProvider);

    final double savings = (widget.priceMonthly * 12) - widget.priceYearly;
    final int savingsPercent =
        (((widget.priceMonthly * 12) - widget.priceYearly) /
                (widget.priceMonthly * 12) *
                100)
            .round();
    final double currentPrice =
        _selectedPlan == 'monthly' ? widget.priceMonthly : widget.priceYearly;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.paySubscription,
            style: Theme.of(context).textTheme.titleMedium),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.botName,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(widget.botDescription,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                _buildPlanCard(
                  id: 'monthly',
                  title: s.payMonth[0].toUpperCase() + s.payMonth.substring(1),
                  price: '\$${widget.priceMonthly.toStringAsFixed(2)}',
                  period: '/${s.payMonth}',
                  s: s,
                ),
                const SizedBox(height: 16),
                _buildPlanCard(
                  id: 'yearly',
                  title: s.payYear[0].toUpperCase() + s.payYear.substring(1),
                  price: '\$${widget.priceYearly.toStringAsFixed(2)}',
                  period: '/${s.payYear}',
                  subtitle: 'Экономия \$$savings ($savingsPercent%)',
                  s: s,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            '${s.payAction} \$${currentPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String period,
    required AppStrings s,
    String? subtitle,
  }) {
    final bool isSelected = _selectedPlan == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(price,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: AppColors.accent)),
                      Text(period,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.accent, size: 28)
            else
              const Icon(Icons.radio_button_off,
                  color: AppColors.border, size: 28),
          ],
        ),
      ),
    );
  }
}
