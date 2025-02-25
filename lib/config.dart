class Config {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  // API 基础URL
  static String get baseUrl {
    if (isProduction) {
      return 'https://trade-order-api.vercel.app'; // Vercel 部署的 API 地址
    }
    return 'http://localhost:8000';
  }

  // API 超时设置
  static const Duration apiTimeout = Duration(seconds: 30);
}
