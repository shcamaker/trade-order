class Config {
  // 更可靠地检测生产环境
  static bool get isProduction {
    const prodEnv =
        bool.fromEnvironment('FLUTTER_WEB_AUTO_DETECT', defaultValue: false);
    return prodEnv || const bool.fromEnvironment('dart.vm.product');
  }

  // API 基础URL
  static String get baseUrl {
    if (isProduction) {
      return 'https://order-server-apis.vercel.app'; // Vercel 部署的 API 地址
    }
    return 'http://localhost:8000';
  }

  // API 超时设置
  static const Duration apiTimeout = Duration(seconds: 30);

  // GitHub Pages 部署的基础路径
  static String get baseHref {
    if (isProduction) {
      return '/trade-order/';
    }
    return '/';
  }
}
