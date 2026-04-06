import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stripe_service.dart';

final checkoutLoadingProvider = StateProvider<bool>((ref) => false);

class SubscribeButton extends ConsumerWidget {
  final String botId;

  const SubscribeButton({
    super.key,
    required this.botId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(checkoutLoadingProvider);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1), // Dokki Primary Color
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: isLoading
            ? null
            : () async {
                ref.read(checkoutLoadingProvider.notifier).state = true;
                try {
                  // Исправлено: добавлены обязательные параметры botId и plan
                  await StripeService().createCheckoutSession(
                    botId: botId,
                    plan: 'monthly_50',
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  ref.read(checkoutLoadingProvider.notifier).state = false;
                }
              },
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Unlock All Bots',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
