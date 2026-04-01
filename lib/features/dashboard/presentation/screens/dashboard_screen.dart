import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';
// ИСПРАВЛЕННЫЕ ПУТИ ИМПОРТА (на два уровня вверх)
import '../../providers/dashboard_providers.dart';
import '../../domain/dashboard_metrics.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Подключаем наш новый провайдер реальных метрик
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.surface,
      ),
      body: metricsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Ошибка загрузки данных: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (metrics) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Обзор аналитики',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  isDesktop
                      ? _buildDesktopGrid(metrics)
                      : _buildMobileList(metrics),
                  const SizedBox(height: 32),
                  _buildChartSection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String subtitle) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopGrid(DashboardMetrics metrics) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: _getCards(metrics),
    );
  }

  Widget _buildMobileList(DashboardMetrics metrics) {
    return Column(
      children: _getCards(metrics).map((card) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: card,
        );
      }).toList(),
    );
  }

  List<Widget> _getCards(DashboardMetrics metrics) {
    return [
      _buildStatCard(
          Icons.smart_toy, metrics.activeBots.toString(), 'бота активно'),
      _buildStatCard(Icons.message, metrics.totalMessages.toString(),
          'сообщений обработано'),
      _buildStatCard(Icons.people, metrics.activeUsers.toString(),
          'активных пользователей'),
      _buildStatCard(
          Icons.timer, metrics.avgResponseTime, 'среднее время ответа'),
    ];
  }

  Widget _buildChartSection() {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Активность за неделю',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 200,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Пн',
                            'Вт',
                            'Ср',
                            'Чт',
                            'Пт',
                            'Сб',
                            'Вс'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[value.toInt()],
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 200,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 1000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 340),
                        FlSpot(1, 420),
                        FlSpot(2, 280),
                        FlSpot(3, 850),
                        FlSpot(4, 600),
                        FlSpot(5, 450),
                        FlSpot(6, 750),
                      ],
                      isCurved: true,
                      color: AppColors.accent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
