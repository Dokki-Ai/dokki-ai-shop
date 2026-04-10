class ApiConstants {
  /// URL оркестратора деплоя на Sevalla
  static const String deployServiceUrl =
      'https://deploy-service-vxjp9.sevalla.app';

  /// Конечная точка для деплоя нового бота
  static String get deployUrl => '$deployServiceUrl/deploy';
}
