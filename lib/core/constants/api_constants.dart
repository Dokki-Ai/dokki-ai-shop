class ApiConstants {
  /// URL оркестратора деплоя на Railway
  static const String deployServiceUrl =
      'https://dokki-deploy-service-production-a748.up.railway.app';

  /// Конечная точка для деплоя нового бота
  static String get deployUrl => '$deployServiceUrl/deploy';
}