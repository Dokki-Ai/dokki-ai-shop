class DashboardMetrics {
  final int activeBots;
  final int totalMessages;
  final int activeUsers;
  final String avgResponseTime;

  DashboardMetrics({
    required this.activeBots,
    required this.totalMessages,
    required this.activeUsers,
    required this.avgResponseTime,
  });
}
